-- Local Lua 5.4 tests of common Lua/Luau code. NOT a Roblox engine test.
local root=assert(os.getenv('VALBRUME_LANDSCAPE_ROOT'))
local dir=root..'/src/ServerScriptService/ValbrumeServer/LandscapeS3P6/'
local P=dofile(dir..'Plan.lua')
local F=dofile(dir..'Field.lua')
local V=dofile(dir..'Voxels.lua')
local tests=0
local function test(name,fn) fn();tests=tests+1;print('PASS '..name) end
local path=F.path(P)
local tiles=F.tiles(P,path)
local v3=dofile(root..'/tests/landscape-s3-p6/v3_layout.lua')
test('compiled files',function()
 for _,name in ipairs({'Plan','Field','Voxels','Audit','Build'}) do assert(loadfile(dir..name..'.lua')) end
end)
test('endpoints preserved by spline',function()
 local x,z=F.at(path,0);assert(x==P.Points[1][1] and z==P.Points[1][2])
 x,z=F.at(path,path.length);assert(math.abs(x-P.Points[#P.Points][1])<1e-8 and math.abs(z-P.Points[#P.Points][2])<1e-8)
 assert(F.weight(P,path,path.points[1].x,path.points[1].z,{},v3)==0)
 assert(F.weight(P,path,path.points[#path.points].x,path.points[#path.points].z,{},v3)==0)
end)
test('tile uniqueness and full source bounds exclusion',function()
 local keys={}
 for _,t in ipairs(tiles) do
  assert(t.x%4==0 and t.z%4==0);local k=t.x..':'..t.z;assert(not keys[k]);keys[k]=true
  for _,b in ipairs(P.ProtectedSources) do assert(not(t.x<=b[3] and t.x+32>=b[1] and t.z<=b[4] and t.z+32>=b[2])) end
 end
 assert(#tiles<=P.MaxTiles)
end)
local columns=0
test('whole column footprint stays outside source and V3 routes',function()
 for _,t in ipairs(tiles) do for x=t.x+2,t.x+30,4 do for z=t.z+2,t.z+30,4 do
  local w,n=F.weight(P,path,x,z,{},v3);assert(w>=0 and w<=1)
  if w>0 then
   columns=columns+1
   for _,b in ipairs(P.ProtectedSources) do assert(F.rectDistance(x,z,b,2)>P.SourceMoat) end
   assert(x< -500)
  end
  for _,base in ipairs({-78,20,45,110}) do
   local h=F.height(P,path,base,w,n,29,40)
   assert(h-base<=P.MaxFill+.0001 and base-h<=P.MaxCut+.0001)
   if w==0 then assert(h==base) end
  end
 end end end
 assert(columns>0 and columns<P.MaxColumns)
end)
test('protected object boxes and smooth shoulder boundary',function()
 local x,z=F.at(path,path.length*.5)
 local b={x-10,z-10,x+10,z+10}
 assert(F.weight(P,path,x,z,{b},nil)==0)
 assert(F.rectDistance(8,0,{10,-10,20,10},2)==0) -- footprint, not point
 for _,t in ipairs({0,.0001,.1,.5,.9,.9999,1}) do assert(F.smooth(t)>=0 and F.smooth(t)<=1) end
 assert(F.smooth(0)==0 and F.smooth(1)==1)
end)
local AIR,GRASS,ROCK='Air','Grass','Rock'
local function grid(nx,ny,nz)
 local d={SolidMaterial={},SolidOccupancy={},LiquidOccupancy={},Size={X=nx,Y=ny,Z=nz}}
 for x=1,nx do
  for _,k in ipairs(V.Names) do d[k][x]={} end
  for y=1,ny do
   for _,k in ipairs(V.Names) do d[k][x][y]={} end
   for z=1,nz do d.SolidMaterial[x][y][z]=AIR;d.SolidOccupancy[x][y][z]=0;d.LiquidOccupancy[x][y][z]=0 end
  end
 end
 return d
end
local size={X=2,Y=12,Z=2}
test('canonical rule, metadata, no input mutation',function()
 local d=grid(2,12,2);d.SolidMaterial[1][1][1]=ROCK;d.SolidOccupancy[1][1][1]=1;d.LiquidOccupancy[1][1][1]=1
 d.SolidMaterial[1][2][1]=ROCK;d.SolidOccupancy[1][2][1]=.5;d.LiquidOccupancy[1][2][1]=.7
 local c,n=V.canonical(d,size,AIR)
 assert(c.Size==nil and n==1 and c.LiquidOccupancy[1][1][1]==0 and d.LiquidOccupancy[1][1][1]==1)
 assert(c.LiquidOccupancy[1][2][1]==.7)
end)
test('water and empty column protected',function()
 local d=grid(2,12,2);local p={MinY=0,MaxY=48}
 local s,e=V.surface(d,1,1,p,AIR);assert(not s and e=='empty')
 d.LiquidOccupancy[1][4][1]=.2
 s,e=V.surface(d,1,1,p,AIR);assert(not s and e=='water')
end)
test('cavity preserved and thin roof cut rejected',function()
 local d=grid(2,12,2);local p={MinY=0,MaxY=48,CoverDepth=12}
 for y=1,2 do d.SolidMaterial[1][y][1]=ROCK;d.SolidOccupancy[1][y][1]=1 end
 for y=5,9 do d.SolidMaterial[1][y][1]=ROCK;d.SolidOccupancy[1][y][1]=1 end
 local s=V.surface(d,1,1,p,AIR);assert(s.floor==16 and s.height==36)
 local b=V.copy(d,size)
 assert(not V.sculpt(d,1,1,s,20,GRASS,p,AIR,ROCK))
 assert(V.equal(d,b,size))
 assert(V.sculpt(d,1,1,s,32,GRASS,p,AIR,ROCK))
 assert(d.SolidOccupancy[1][3][1]==0 and d.SolidOccupancy[1][4][1]==0 and d.SolidOccupancy[1][1][1]==1)
end)
test('unrelated cells unchanged and write arrays reject NaN',function()
 local d=grid(2,12,2);for y=1,8 do d.SolidMaterial[1][y][1]=ROCK;d.SolidOccupancy[1][y][1]=1 end
 local b=V.copy(d,size);local p={MinY=0,MaxY=48,CoverDepth=12}
 local s=V.surface(d,1,1,p,AIR);V.sculpt(d,1,1,s,34,GRASS,p,AIR,ROCK)
 for y=1,12 do for _,k in ipairs(V.Names) do assert(d[k][2][y][2]==b[k][2][y][2]) end end
 d.SolidOccupancy[1][1][1]=0/0;assert(not pcall(V.copy,d,size))
end)
-- Execute the actual builder with a single synthetic tile and strict API stub.
local function runtimeCase(mode)
 local plan={};for k,v in pairs(P) do plan[k]=v end
 local shape={X=8,Y=80,Z=8}
 local original=grid(8,80,8)
 for x=1,8 do for z=1,8 do for y=1,37 do
  original.SolidMaterial[x][y][z]=GRASS;original.SolidOccupancy[x][y][z]=1
 end end end
 local data=V.copy(original,shape)
 local wc,reads,frames,clock=0,0,0,0
 local function obj() return {attrs={},GetAttribute=function(s,k) return s.attrs[k] end,SetAttribute=function(s,k,v) s.attrs[k]=v end} end
 local world,continent=obj(),obj();world.attrs.GenerationId='fixture';world.attrs.GenerationReady=false
 continent.attrs.CandidateVersion=P.BaseCandidate
 local ws={};world.Parent=ws;local changed=false
 function ws:FindFirstChild(k) return k=='ValbrumeWorld' and (changed and {} or world) or k=='ValbrumeContinents' and continent end
 function ws:GetDescendants() return {} end
 function ws:Raycast() return {Position={Y=24},Material=GRASS} end
 local terrain={};ws.Terrain=terrain
 function terrain:ReadVoxelChannels()
  reads=reads+1;local d=V.copy(data,shape);d.Size=shape
  if mode=='concurrent' and reads==2 then d.SolidOccupancy[1][1][1]=.1 end
  return d
 end
 function terrain:WriteVoxelChannels(_,_,d)
  assert(d.Size==nil,'Unknown channel Size')
  for k in pairs(d) do assert(k=='SolidMaterial' or k=='SolidOccupancy' or k=='LiquidOccupancy','Unknown channel') end
  wc=wc+1
  if mode=='write-error' and wc==2 then error('injected write failure') end
  data=V.copy(d,shape)
 end
 local rs={IsStudio=function() return true end,IsRunning=function() return true end,IsServer=function() return true end,
 PostSimulation={Wait=function()
  frames=frames+1
  if wc==1 and mode=='deadline' then clock=100 end
  if wc==1 and mode=='world-change' then changed=true end
 end}}
 local fakeF={};for k,v in pairs(F) do fakeF[k]=v end
 fakeF.tiles=function() return {{x=-1888,z=-992}} end
 local auditCount=0
 local audit={run=function()
  auditCount=auditCount+1
  return {status='REVIEW_REQUIRED',support={{terrain=true,solid=true}}}
 end,public=function(r) return r end,supportRegressions=function() return mode=='support-regression' and 1 or 0 end}
 local hs={JSONEncode=function() return 'fixture' end}
 local vals={Plan=plan,Field=fakeF,Voxels=V,Audit=audit,Layout=v3}
 local env=setmetatable({workspace=ws,game={GetService=function(_,n) return ({RunService=rs,HttpService=hs})[n] end},
 script={Parent={Plan='Plan',Field='Field',Voxels='Voxels',Audit='Audit',Parent={WorldV3={Layout='Layout'}}}},
 require=function(k) return assert(vals[k]) end,print=function() end,
 Enum={Material={Air=AIR,Ground=ROCK,Grass=GRASS,Water='Water'},RaycastFilterType={Include='Include'}},
 RaycastParams={new=function()return{}end},Vector3={new=function(x,y,z)return{X=x,Y=y,Z=z}end},
 Region3={new=function(a,b)return{a,b}end},CFrame={new=function(...)return{...}end},
 Instance={new=function()return{}end},task={wait=function()end},os={clock=function()return clock end}}, {__index=_G})
 local mod=assert(loadfile(dir..'Build.lua','t',env))()
 local ok,r=pcall(mod.run,world)
 if mode=='success' then
  assert(ok,tostring(r));assert(wc==2 and r.columns>0 and r.changedTiles==1)
  assert(not V.equal(data,original,shape));local old=wc;assert(mod.run(world)==r and wc==old)
 elseif mode=='world-change' then
  assert(not ok and wc==1,'stale-world restoration write')
  assert(continent.attrs.LandscapeStatus=='FAILED_PARTIAL_STOP_PLAY')
 else
  assert(not ok,'failure not detected')
  assert(V.equal(data,original,shape),'canonical snapshot was not restored')
  if mode=='concurrent' then assert(wc==0 and continent.attrs.LandscapeStatus=='FAILED_NO_WRITE')
  else assert(wc==3 or (mode=='deadline' and wc==2));assert(continent.attrs.LandscapeStatus=='FAILED_RESTORED') end
 end
end
for _,mode in ipairs({'success','write-error','concurrent','deadline','world-change','support-regression'}) do
 test('builder '..mode,function()runtimeCase(mode)end)
end
print(string.format('RESULT cases=%d tiles=%d unprotected_columns=%d path_studs=%.3f',tests,#tiles,columns,path.length))

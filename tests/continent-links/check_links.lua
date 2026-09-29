-- Run with Lua 5.4 (shared Lua/Luau syntax). These are mocks, NOT Roblox tests.
local root=assert(os.getenv('VALBRUME_LINK_RELEASE'))
local prefix=root..'/src/ServerScriptService/ValbrumeServer/'
local P=dofile(prefix..'ContinentLinkPlan.lua')
local G=dofile(prefix..'ContinentLinkGeometry.lua')
local V=dofile(prefix..'ContinentLinkVoxels.lua')
local v3=dofile(root..'/tests/continent-links/v3_layout.lua')
local atlas=dofile(root..'/tests/continent-links/atlas.lua')
local assertions=0
local function check(condition,message) assertions=assertions+1;assert(condition,message) end
local tiles=G.tiles(P,v3,atlas)
local keys,columns={},0
for _,tile in ipairs(tiles) do
    local key=tile.X..':'..tile.Z
    check(not keys[key],'Duplicate tile');keys[key]=true
    for _,c in ipairs(tile.Columns) do
        check(not G.v3Protected(v3,c.X,c.Z),'V3 overlap')
        check(math.abs(c.X)>=400,'Central sea touched')
        check(c.Distance<P.OuterRadius,'Off-mask column')
        check(G.fillHeight(P,c)<=c.Height,'Raised shoulder')
        columns=columns+1
    end
end
for _,r in ipairs(P.Links) do
    for i=1,#r.Points-1 do
        local a,b=r.Points[i],r.Points[i+1]
        for s=0,100 do
            local x,z=a[1]+(b[1]-a[1])*s/100,a[3]+(b[3]-a[3])*s/100
            if not G.v3Protected(v3,x,z) then
                local info=G.at(P,v3,x,z)
                local protected=false
                for _,c in pairs(v3.Regions) do if (x-c[1])^2+(z-c[3])^2<128^2 then protected=true end end
                check(info~=nil or protected,'Uncovered centreline')
            end
        end
    end
end
local bad=dofile(prefix..'ContinentLinkPlan.lua');bad.MaxTiles=1
check(not pcall(G.tiles,bad,v3,atlas),'Budget guard absent')
bad=dofile(prefix..'ContinentLinkPlan.lua');bad.Links[1].Points[2][1]=0/0
check(not pcall(G.tiles,bad,v3,atlas),'NaN guard absent')
bad=dofile(prefix..'ContinentLinkPlan.lua');bad.Links[1].Points[2][1]=1900
check(not pcall(G.tiles,bad,v3,atlas),'Moved probe accepted')
local AIR,ROCK,GRASS='Air','Rock','Grass'
local function empty(sx,sy,sz)
    local data={SolidMaterial={},SolidOccupancy={},LiquidOccupancy={}}
    for x=1,sx do
        for _,k in ipairs({'SolidMaterial','SolidOccupancy','LiquidOccupancy'}) do data[k][x]={} end
        for y=1,sy do
            for _,k in ipairs({'SolidMaterial','SolidOccupancy','LiquidOccupancy'}) do data[k][x][y]={} end
            for z=1,sz do
                data.SolidMaterial[x][y][z]=AIR;data.SolidOccupancy[x][y][z]=0;data.LiquidOccupancy[x][y][z]=0
            end
        end
    end
    return data
end
local before=empty(4,8,4)
-- A cave column with solid roof, and a separate liquid column.
before.SolidMaterial[1][1][1]=ROCK;before.SolidOccupancy[1][1][1]=1
before.SolidMaterial[1][5][1]=ROCK;before.SolidOccupancy[1][5][1]=.8
before.LiquidOccupancy[3][3][3]=.6
local after=V.copy(before,4,8,4)
V.fillEmpty(after,2,2,8,0,0,10,GRASS,AIR)
check(not pcall(V.fillEmpty,after,1,1,8,0,0,10,GRASS,AIR),'Native cave overwritten')
check(not pcall(V.fillEmpty,after,3,3,8,0,0,10,GRASS,AIR),'Water overwritten')
for x=1,4 do for y=1,8 do for z=1,4 do
    if x~=2 or z~=2 then
        for _,k in ipairs({'SolidMaterial','SolidOccupancy','LiquidOccupancy'}) do check(after[k][x][y][z]==before[k][x][y][z],'Unrelated voxel changed') end
    end
end end end
check(after.SolidOccupancy[2][3][2]==.5,'Top occupancy')
local current=V.copy(before,4,8,4)
local writes,frames=0,0
local adapter={
    write=function(d) current=V.copy(d,4,8,4);writes=writes+1 end,
    read=function() return V.copy(current,4,8,4) end,
    waitFrame=function() frames=frames+1 end,
}
V.commit(adapter,before,after,{{IX=1,IZ=1},{IX=3,IZ=3}},4,8,4,AIR)
check(writes==2 and frames==2,'Refresh/write sequence')
check(V.equal(current,after,4,8,4),'Commit not verified')
check(current.SolidOccupancy[1][5][1]==.8 and current.SolidOccupancy[1][3][1]==0,'Cave lost')
check(current.LiquidOccupancy[3][3][3]==.6,'Liquid lost')
-- Failure after transient clear must attempt original-channel restoration.
current=V.copy(before,4,8,4);writes=0
adapter.write=function(d)
    writes=writes+1
    if writes==2 then error('Injected final-write failure') end
    current=V.copy(d,4,8,4)
end
local ok,err=pcall(V.commit,adapter,before,after,{{IX=1,IZ=1}},4,8,4,AIR)
check(not ok and string.find(err,'tileRestored=true',1,true),'Restoration not reported')
check(V.equal(before,current,4,8,4),'Original tile not restored')
print('PURE TESTS OK assertions='..assertions..' tiles='..#tiles..' columns='..columns)
-- Execute the real repair module with explicitly simulated engine methods.
local objects={}
local function runtimeCase(failWrite)
    local native=empty(16,4,16);native.Size={X=16,Y=4,Z=16}
    native.SolidMaterial[1][1][1]=ROCK;native.SolidOccupancy[1][1][1]=1
    native.LiquidOccupancy[3][1][1]=1
    native.SolidMaterial[6][1][1]=ROCK;native.SolidOccupancy[6][1][1]=1
    local data=V.copy(native,16,4,16)
    local writeCount=0
    local terrain={}
    function terrain:ReadVoxelChannels()
        local d=V.copy(data,16,4,16);d.Size={X=16,Y=4,Z=16};return d
    end
    function terrain:WriteVoxelChannels(_,_,d)
        writeCount=writeCount+1
        if failWrite and writeCount==2 then error('Injected engine write') end
        data=V.copy(d,16,4,16)
    end
    local function obj()
        return {attrs={},GetAttribute=function(s,k) return s.attrs[k] end,SetAttribute=function(s,k,v) s.attrs[k]=v end}
    end
    local world,continent=obj(),obj()
    local workspace={Terrain=terrain};world.Parent=workspace
    world.attrs.GenerationId='mock-generation'
    function workspace:FindFirstChild(n) return n=='ValbrumeWorld' and world or n=='ValbrumeContinents' and continent end
    function continent:FindFirstChild(n) return n=='ImportedRegions' and {} end
    function workspace:Raycast(origin,_,params)
        local ix=math.floor((origin.X-1600)/4)+1
        if ix==6 then return {Position={Y=4},Material=ROCK} end
        if ix==7 then return {Position={Y=500},Material=ROCK} end
        if ix==5 and params.RespectCanCollide then return {Position={Y=9},Material=ROCK} end
        return nil
    end
    local small={Version='mock',MinY=0,MaxY=16,TileSize=64,FoundationY=0,MaxSeconds=85,CoreRadius=32,OuterRadius=48}
    local tile={X=1600,Z=0,Columns={}}
    for ix=1,7 do tile.Columns[#tile.Columns+1]={IX=ix,IZ=1,X=1600+(ix-.5)*4,Z=2,Height=8,Distance=0,Material='Ground',ProtectedSource=ix==4} end
    local mockG={tiles=function() return {tile} end,fillHeight=G.fillHeight}
    local rs={IsServer=function() return true end,IsRunning=function() return true end,PostSimulation={Wait=function() end}}
    local hs={JSONEncode=function() return 'MOCK_REPORT' end}
    local values={plan=small,geometry=mockG,voxels=V,atlas=atlas,v3=v3}
    local env=setmetatable({
        workspace=workspace,game={GetService=function(_,k) return ({RunService=rs,HttpService=hs,ReplicatedStorage={Valbrume={ContinentAtlas='atlas'}}})[k] end},
        script={Parent={ContinentLinkPlan='plan',ContinentLinkGeometry='geometry',ContinentLinkVoxels='voxels',WorldV3={Layout='v3'}}},
        require=function(k) return assert(values[k]) end,
        RaycastParams={new=function() return {} end},Enum={Material={Air=AIR,Ground=GRASS},RaycastFilterType={Include='Include'}},
        Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end},Region3={new=function(a,b) return {a,b} end},
    },{__index=_G})
    local runtime=assert(loadfile(prefix..'ContinentLinkRepair.lua','t',env))()
    local success,res=pcall(runtime.apply,world)
    if failWrite then
        check(not success,'Engine error swallowed')
        check(world.attrs.GenerationError~=nil,'Generation error not recorded')
        check(continent.attrs.LinkRepairStatus=='FAILED_PARTIAL','Partial failure mislabeled')
        check(V.equal(native,data,16,4,16),'Tile not restored')
    else
        check(success,tostring(res))
        check(res.refreshed==2 and res.filled==1,'Wrong action counts')
        check(res.protectedEmpty==1 and res.partSupportedEmpty==1 and res.outOfSlab==1,'Protected cases not handled')
        check(data.SolidOccupancy[2][2][1]==1,'Gap not filled')
        check(data.LiquidOccupancy[3][1][1]==1,'Water refresh changed shape')
        local count=writeCount
        check(runtime.apply(world)==res and writeCount==count,'Repeated apply wrote again')
    end
end
runtimeCase(false);runtimeCase(true)
print('RUNTIME MOCKS OK assertions='..assertions)

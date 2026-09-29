-- Execute the REAL TerrainBuilder through an API mock, with a small synthetic layout.
-- Verifies occupancy contracts; does NOT emulate Roblox's surface mesher/physics.
local dir=ROOT.."/src/ServerScriptService/ValbrumeServer/WorldV3/"
local G=dofile(dir.."Geometry.lua")
local layout={Resolution=4,TileSize=32,MinY=-16,MaxY=96,MaxTiles=100,MaxBuildSeconds=30,MaxDesignSlope=18,
    Routes={{Id="test",Core=20,Outer=40,Surface="Ground",Shoulder="Grass",Points={{0,16,0},{96,24,0}}}}}
Enum={Material={Air="Air",Rock="Rock",Ground="Ground",Grass="Grass"}}
Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
Region3={new=function(a,b) return {lo=a,hi=b} end}
task={wait=function() end}
game={GetService=function() return {PostSimulation={Wait=function() end}} end}
script={Parent={Geometry="mockGeometry"}}
local oldRequire=require
require=function(name) if name=="mockGeometry" then return G else return oldRequire(name) end end
local B=dofile(dir.."TerrainBuilder.lua")
require=oldRequire
local outsideChecked,coreChecked,writes=0,0,0
local function original(x,y,z)
    -- One gap, a tall mountain and a floating slab, plus water in empty cells.
    local solid=(x<20 and y<32) or (x>=60 and y<64) or (y>=76 and y<80)
    return solid and "Rock" or "Air",solid and 1 or 0,not solid and y<12 and .75 or 0
end
local terrain={}
function terrain:ReadVoxelChannels(region,resolution,names)
    local data={SolidMaterial={},SolidOccupancy={},LiquidOccupancy={}}
    for _,key in ipairs(names) do
        for ix=1,(region.hi.X-region.lo.X)/4 do
            data[key][ix]={}
            for iy=1,(region.hi.Y-region.lo.Y)/4 do
                data[key][ix][iy]={}
                for iz=1,(region.hi.Z-region.lo.Z)/4 do
                    local a,b,c=original(region.lo.X+(ix-.5)*4,region.lo.Y+(iy-.5)*4,region.lo.Z+(iz-.5)*4)
                    data[key][ix][iy][iz]=key=="SolidMaterial" and a or key=="SolidOccupancy" and b or c
                end
            end
        end
    end
    return data
end
function terrain:WriteVoxelChannels(region,resolution,data)
    assert(resolution==4)
    writes=writes+1
    for ix=1,#data.SolidMaterial do
        for iz=1,#data.SolidMaterial[ix][1] do
            local x,z=region.lo.X+(ix-.5)*4,region.lo.Z+(iz-.5)*4
            local sample=G.field(layout.Routes,x,z)
            local previous=1
            for iy=1,#data.SolidMaterial[ix] do
                local m,o,w=data.SolidMaterial[ix][iy][iz],data.SolidOccupancy[ix][iy][iz],data.LiquidOccupancy[ix][iy][iz]
                assert(o>=0 and o<=1 and w>=0 and w<=1)
                if sample then
                    assert(w==0 and o<=previous+1e-10,"Floating solid above cleared ground")
                    assert((o==0 and m=="Air") or (o>0 and m~="Air"))
                    previous=o
                    if sample.Weight==1 then
                        local expected=math.clamp((sample.Height-(region.lo.Y+(iy-1)*4))/4,0,1)
                        assert(math.abs(expected-o)<1e-9); coreChecked=coreChecked+1
                    end
                else
                    local a,b,c=original(x,region.lo.Y+(iy-.5)*4,z)
                    assert(m==a and o==b and w==c,"Unrelated terrain/water modified")
                    outsideChecked=outsideChecked+1
                end
            end
        end
    end
end
local report=B.build(layout,terrain,function() return true end)
assert(report.Tiles==writes and writes>0 and coreChecked>0 and outsideChecked>0)
print(string.format("PASS: real voxel writer mocked; %d tiles, %d core voxels, %d outside voxels unchanged",writes,coreChecked,outsideChecked))
local before=writes
assert(not pcall(B.build,layout,terrain,function() return false end))
assert(writes==before,"Wrote into obsolete world")
layout.MaxTiles=1
assert(not pcall(B.build,layout,terrain,function() return true end))
assert(writes==before,"Budget failure wrote terrain")
print("PASS: obsolete-world and tile-budget guards, no writes")

-- Runtime server only. Overwrite only corridor columns, tile by tile.
-- Full-height column replacement removes buried slabs and overhead remnants.
-- No global Clear(), no edits to the saved terrain while Studio is stopped.
local G = require(script.Parent.Geometry)
local B = {}

function B.build(layout, terrain, stillCurrent)
    local tiles = G.plan(layout) -- all dimensions/budgets checked before any write
    local start = os.clock()
    local channels = {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"}
    local resolution, size = layout.Resolution, layout.TileSize
    local nx, ny = size/resolution, (layout.MaxY-layout.MinY)/resolution
    local report = {Tiles = 0, Columns = 0, Voxels = 0}
    local materials = {}
    for _, route in ipairs(layout.Routes) do
        materials[route.Id] = {Enum.Material[route.Surface], Enum.Material[route.Shoulder]}
        assert(materials[route.Id][1] and materials[route.Id][2], "Unknown Terrain material")
    end
    for tileIndex, tile in ipairs(tiles) do
        assert(stillCurrent(), "World replaced during V3 terrain generation")
        assert(os.clock()-start <= layout.MaxBuildSeconds, "World V3 generation deadline exceeded")
        local region = Region3.new(Vector3.new(tile.X,layout.MinY,tile.Z),
            Vector3.new(tile.X+size,layout.MaxY,tile.Z+size))
        local data = terrain:ReadVoxelChannels(region, resolution, channels)
        local solid, occupancy, liquid = data.SolidMaterial, data.SolidOccupancy, data.LiquidOccupancy
        local touched = false
        for ix = 1, nx do
            local x = tile.X+(ix-0.5)*resolution
            for iz = 1, nx do
                local z = tile.Z+(iz-0.5)*resolution
                local sample = G.field(layout.Routes,x,z)
                if sample then
                    assert(occupancy[ix][ny][iz] == 0, "Terrain above V3 ceiling: stop and inspect")
                    local originalY
                    for iy = ny, 1, -1 do
                        local amount = occupancy[ix][iy][iz]
                        if amount > 0 and solid[ix][iy][iz] ~= Enum.Material.Air then
                            originalY = layout.MinY+(iy-1+amount)*resolution
                            break
                        end
                    end
                    local height = G.surface(sample,originalY,layout.MinY)
                    local palette = materials[sample.Route.Id]
                    local top = sample.Distance <= 10 and palette[1] or palette[2]
                    for iy = 1, ny do
                        local bottom = layout.MinY+(iy-1)*resolution
                        local amount = math.clamp((height-bottom)/resolution,0,1)
                        occupancy[ix][iy][iz] = amount
                        liquid[ix][iy][iz] = 0
                        solid[ix][iy][iz] = amount <= 0 and Enum.Material.Air
                            or (bottom >= height-8 and top or Enum.Material.Rock)
                    end
                    report.Columns = report.Columns+1
                    report.Voxels = report.Voxels+ny
                    touched = true
                end
            end
        end
        if touched then
            terrain:WriteVoxelChannels(region,resolution,{SolidMaterial=solid,
                SolidOccupancy=occupancy, LiquidOccupancy=liquid})
            report.Tiles = report.Tiles+1
        end
        if tileIndex % 2 == 0 then task.wait() end
    end
    game:GetService("RunService").PostSimulation:Wait()
    report.Seconds = os.clock()-start
    return report
end
return B

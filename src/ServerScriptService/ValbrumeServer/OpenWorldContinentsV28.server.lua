-- Valbrume World V3.1 bootstrap. Legacy filename/stage/hierarchy are API contracts.
-- Replaces geography only. Do not run this source in the Command Bar.
local RunService = game:GetService("RunService")
assert(RunService:IsServer(), "World generation is server-authoritative")
local server = script.Parent
local modules = server:WaitForChild("WorldV3",10)
assert(modules, "WorldV3 modules missing: install the complete release")
local Layout = require(modules.Layout)
local Geometry = require(modules.Geometry)
local Builder = require(modules.TerrainBuilder)
local Dressing = require(modules.Dressing)
local Audit = require(modules.Audit)
local Generation = require(server.WorldGeneration)
local Config = require(game:GetService("ReplicatedStorage").Valbrume.Config)
local world = Generation.Await("Expansion")
local terrain = workspace.Terrain
local function current()
    return world.Parent == workspace and workspace:FindFirstChild("ValbrumeWorld") == world
end
local function verifyContracts()
    Geometry.plan(Layout)
    assert(current(), "Obsolete world")
    assert(world.ExpansionV25 and world.ExpansionV25.Zones, "Expansion hierarchy missing")
    for id, position in pairs(Layout.Regions) do
        local actual
        if Config.Zones[id] then actual = Config.Zones[id].Origin
        else
            local spawn = world.ExpansionV25.Zones:FindFirstChild(id.."_ExpansionSpawn")
            assert(spawn and spawn:IsA("BasePart"), "Missing region "..id)
            actual = spawn.Position
        end
        assert(math.abs(actual.X-position[1]) < .01 and math.abs(actual.Z-position[3]) < .01,
            "Region moved: review Layout before generation: "..id)
    end
    assert(not world:FindFirstChild("OpenWorldV28"), "World geography already exists; restart Play")
end
local function build()
    verifyContracts() -- no mutation until the current contracts have been checked
    local root = Instance.new("Folder")
    root.Name, root.Parent = "OpenWorldV28",world
    root:SetAttribute("WorldRevision","V3")
    root:SetAttribute("GeographyRevision",Layout.Version)
    for _, name in ipairs({"Roads","POI","SeaTravel","Hazards","GeographyV3"}) do
        local folder = Instance.new("Folder")
        folder.Name,folder.Parent = name,root
    end
    -- Retain the existing maritime footprint. The masks below bridge each shore gap.
    terrain:FillBlock(CFrame.new(0,-17,0),Vector3.new(900,50,2300),Enum.Material.Water)
    terrain:FillBlock(CFrame.new(-500,8,0),Vector3.new(160,20,2100),Enum.Material.Sand)
    terrain:FillBlock(CFrame.new(500,8,0),Vector3.new(160,20,2100),Enum.Material.Sand)
    for i, pos in ipairs({Vector3.new(-155,5,-430),Vector3.new(140,6,360),Vector3.new(-60,4,780)}) do
        terrain:FillBall(pos,68-i*7,Enum.Material.Rock)
        terrain:FillBall(pos+Vector3.new(0,15,0),44-i*4,Enum.Material.Grass)
    end
    local report = Builder.build(Layout,terrain,current)
    report.VegetationAdjusted = Dressing.build(world,root,Layout)
    local oldTravel = world.ExpansionV25:FindFirstChild("Travel")
    if oldTravel then oldTravel:Destroy() end -- replaces only the old generated portal hub
    root:SetAttribute("BuildSeconds",report.Seconds)
    root:SetAttribute("ModifiedColumns",report.Columns)
    print("[Valbrume V3.1] "..game:GetService("HttpService"):JSONEncode(report))
    Generation.Complete(world,"Continents")
    if RunService:IsStudio() then
        task.spawn(function()
            local readyOK,readyError = pcall(function() Generation.Await("Ready"); Audit.run(world,Layout) end)
            if not readyOK then warn("[Valbrume V3.1 QA] "..tostring(readyError)) end
        end)
    end
end
local ok,err = xpcall(build,debug.traceback)
if not ok then
    if current() then world:SetAttribute("GenerationError","WorldV3: "..tostring(err)) end
    error(err) -- never emit Continents/Ready on an incomplete build
end

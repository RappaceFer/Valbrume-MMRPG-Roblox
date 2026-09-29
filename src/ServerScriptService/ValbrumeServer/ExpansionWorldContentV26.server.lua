local Terrain = workspace.Terrain

local Generation = require(script.Parent.WorldGeneration)
local world = Generation.Await("Biome")
local expansion = world.ExpansionV25
local zonesFolder = expansion:WaitForChild("Zones")

local old = world:FindFirstChild("V26Content")
if old then
    old:Destroy()
end

local root = Instance.new("Folder")
root.Name = "V26Content"
root.Parent = world

local homeDensity = Instance.new("Folder")
homeDensity.Name = "HomeDensity"
homeDensity.Parent = root

local questObjects = Instance.new("Folder")
questObjects.Name = "ExpansionQuestObjects"
questObjects.Parent = root

local function terrainY(x, z, fallback)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {Terrain}

    local hit = workspace:Raycast(
        Vector3.new(x, 340, z),
        Vector3.new(0, -700, 0),
        params
    )

    return hit and hit.Position.Y or fallback
end

local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.CanTouch = false
    p.Color = color
    p.Material = material or Enum.Material.Slate
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function billboard(adornee, textValue, color)
    local gui = Instance.new("BillboardGui")
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(250, 70)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 5.5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 105
    gui.Parent = adornee

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = textValue
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextWrapped = true
    label.Parent = gui
end

local function zoneSpawn(zoneId)
    return zonesFolder:FindFirstChild(zoneId .. "_ExpansionSpawn")
end

local function localWorld(zoneId, relative)
    local spawn = zoneSpawn(zoneId)
    assert(spawn, "Spawn expansion absent : " .. zoneId)

    local x = spawn.Position.X + relative.X
    local z = spawn.Position.Z + relative.Z
    local y = terrainY(x, z, spawn.Position.Y - 8)

    return Vector3.new(x, y, z)
end

local function marker(zoneId, pointId, relative, color, caption)
    local pos = localWorld(zoneId, relative)

    local p = part(
        questObjects,
        "V26_" .. zoneId .. "_" .. pointId,
        Vector3.new(4.5, 7, 4.5),
        pos + Vector3.new(0, 3.5, 0),
        color,
        Enum.Material.Slate
    )

    p:SetAttribute("VBExpansionZone", zoneId)
    p:SetAttribute("VBExpansionPoint", pointId)
    p.CanCollide = false

    if caption then
        billboard(p, caption, color)
    end

    return p
end

local function questGiver(zoneId, name, relative, color)
    local pos = localWorld(zoneId, relative)

    local model = Instance.new("Model")
    model.Name = "V26_Giver_" .. zoneId .. "_" .. name
    model:SetAttribute("VBExpansionZone", zoneId)
    model:SetAttribute("VBExpansionQuestGiver", true)

    local body = part(
        model,
        "HumanoidRootPart",
        Vector3.new(2.6, 4.2, 1.8),
        pos + Vector3.new(0, 2.1, 0),
        color,
        Enum.Material.SmoothPlastic
    )

    body.CanCollide = true

    local head = part(
        model,
        "Head",
        Vector3.new(2.2, 2.2, 2.2),
        pos + Vector3.new(0, 5.1, 0),
        Color3.fromRGB(225, 198, 168),
        Enum.Material.SmoothPlastic
    )
    head.Shape = Enum.PartType.Ball

    model.PrimaryPart = body
    model.Parent = questObjects

    billboard(head, "!  " .. name .. "\nChronique de l'Écho", color)
    return model
end

local function crateCluster(parent, origin, color)
    for i = 1, 4 do
        local dx = (i % 2) * 5
        local dz = math.floor((i - 1) / 2) * 5
        part(
            parent,
            "SupplyCrate",
            Vector3.new(4, 4, 4),
            origin + Vector3.new(dx, 2, dz),
            color,
            Enum.Material.WoodPlanks
        )
    end
end

local function homePOI(zoneId, basePosition, title, color, material)
    local y = terrainY(basePosition.X, basePosition.Z, basePosition.Y)
    local center = Vector3.new(basePosition.X, y, basePosition.Z)

    local pad = part(
        homeDensity,
        "V26_" .. zoneId .. "_" .. title:gsub("%s+", ""),
        Vector3.new(28, 1, 24),
        center + Vector3.new(0, 0.5, 0),
        color,
        material
    )

    billboard(pad, title, color)
    crateCluster(homeDensity, center + Vector3.new(-8, 0.6, -5), Color3.fromRGB(111, 78, 54))
end

-- Densité A2/H2 : POI lisibles, sans toucher au relief ni aux quêtes existantes.
homePOI("A2", Vector3.new(-900 + 70, 25, -16), "Camp des pisteurs", Color3.fromRGB(112,158,123), Enum.Material.Cobblestone)
homePOI("A2", Vector3.new(-900 - 82, 25, 96), "Relais du vieux pont", Color3.fromRGB(112,145,166), Enum.Material.Slate)
homePOI("A2", Vector3.new(-900 + 138, 25, -38), "Poste du col", Color3.fromRGB(126,106,82), Enum.Material.WoodPlanks)

homePOI("H2", Vector3.new(900 + 70, 23, -18), "Caravane rouge", Color3.fromRGB(181,121,78), Enum.Material.Sandstone)
homePOI("H2", Vector3.new(900 - 80, 23, 100), "Camp des éclaireurs", Color3.fromRGB(150,108,77), Enum.Material.Sandstone)
homePOI("H2", Vector3.new(900 + 138, 23, -42), "Arche de basalte", Color3.fromRGB(102,89,84), Enum.Material.Slate)

-- S3
questGiver("S3", "Maelis", Vector3.new(-10,0,18), Color3.fromRGB(104,176,132))
marker("S3", "MistRootA", Vector3.new(-72,0,26), Color3.fromRGB(91,148,108), "Racine I")
marker("S3", "MistRootB", Vector3.new(-18,0,-72), Color3.fromRGB(91,148,108), "Racine II")
marker("S3", "MistRootC", Vector3.new(78,0,-28), Color3.fromRGB(91,148,108), "Racine III")
marker("S3", "BossGlade", Vector3.new(-118,0,-118), Color3.fromRGB(115,205,151), "Clairière du Veilleur")

-- N4
questGiver("N4", "Neris", Vector3.new(-10,0,18), Color3.fromRGB(143,185,204))
marker("N4", "BeaconA", Vector3.new(-80,0,18), Color3.fromRGB(151,185,198), "Balise I")
marker("N4", "BeaconB", Vector3.new(-12,0,-82), Color3.fromRGB(151,185,198), "Balise II")
marker("N4", "BeaconC", Vector3.new(86,0,-20), Color3.fromRGB(151,185,198), "Balise III")
marker("N4", "WindLens", Vector3.new(48,0,82), Color3.fromRGB(177,208,219), "Lentille des vents")
marker("N4", "BossCliff", Vector3.new(-115,0,-120), Color3.fromRGB(170,210,226), "Promontoire de Nacre")

-- O5
questGiver("O5", "Dorran", Vector3.new(-10,0,18), Color3.fromRGB(190,123,78))
marker("O5", "ForgeCoreA", Vector3.new(-78,0,26), Color3.fromRGB(195,106,62), "Cœur de forge I")
marker("O5", "ForgeCoreB", Vector3.new(-20,0,-76), Color3.fromRGB(195,106,62), "Cœur de forge II")
marker("O5", "Smelter", Vector3.new(84,0,-28), Color3.fromRGB(216,122,65), "Ancien creuset")
marker("O5", "BossForge", Vector3.new(112,0,86), Color3.fromRGB(226,128,66), "Grand Fourneau")

-- V6
questGiver("V6", "Seyra", Vector3.new(-10,0,18), Color3.fromRGB(166,123,215))
marker("V6", "CrystalA", Vector3.new(-76,0,22), Color3.fromRGB(155,112,221), "Cristal I")
marker("V6", "CrystalB", Vector3.new(-18,0,-74), Color3.fromRGB(155,112,221), "Cristal II")
marker("V6", "CrystalC", Vector3.new(80,0,-30), Color3.fromRGB(155,112,221), "Cristal III")
marker("V6", "DeepFissure", Vector3.new(54,0,84), Color3.fromRGB(113,198,216), "Faille profonde")
marker("V6", "BossCore", Vector3.new(-104,0,96), Color3.fromRGB(190,122,233), "Chambre du Noyau")

print("[Valbrume V2.6] World content : POI A2/H2 + objets de quête expansion chargés.")

Generation.Complete(world, "Content")

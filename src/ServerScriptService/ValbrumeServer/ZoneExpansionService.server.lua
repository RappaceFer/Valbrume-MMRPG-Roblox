local Players = game:GetService("Players")
local Terrain = workspace.Terrain

local Generation = require(script.Parent.WorldGeneration)
local world = Generation.Await("Core")
local decor = world:WaitForChild("Decor")

print("[Valbrume V2.5.1] ValbrumeWorld stable détecté avant expansion.")

local ROOT_NAME = "ExpansionV25"
local old = world:FindFirstChild(ROOT_NAME)
if old then
    old:Destroy()
end

local root = Instance.new("Folder")
root.Name = ROOT_NAME
root.Parent = world

local zonesFolder = Instance.new("Folder")
zonesFolder.Name = "Zones"
zonesFolder.Parent = root

local travelFolder = Instance.new("Folder")
travelFolder.Name = "Travel"
travelFolder.Parent = root

local ZONES = {
    S3 = {
        Name = "Sylvebrume",
        Subtitle = "Forêt noyée dans les brumes",
        Origin = Vector3.new(-1520, 0, -560),
        GroundY = 24,
        Color = Color3.fromRGB(90, 157, 118),
        Material = Enum.Material.Grass,
    },

    N4 = {
        Name = "Caps de Nacre",
        Subtitle = "Caps rocheux et vents salés",
        Origin = Vector3.new(-1520, 0, 560),
        GroundY = 34,
        Color = Color3.fromRGB(122, 166, 188),
        Material = Enum.Material.Slate,
    },

    O5 = {
        Name = "Forges d'Ormefer",
        Subtitle = "Ruines des forges anciennes",
        Origin = Vector3.new(1520, 0, -560),
        GroundY = 28,
        Color = Color3.fromRGB(165, 117, 78),
        Material = Enum.Material.Rock,
    },

    V6 = {
        Name = "Profondeurs de l'Écho",
        Subtitle = "Fractures cristallines profondes",
        Origin = Vector3.new(1520, 0, 560),
        GroundY = 26,
        Color = Color3.fromRGB(143, 111, 201),
        Material = Enum.Material.Basalt,
    },
}

local function part(parent, name, size, cf, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.CanCollide = true
    p.CanTouch = false
    p.CanQuery = true
    p.Color = color
    p.Material = material or Enum.Material.Slate
    p.Parent = parent
    return p
end

local function label(adornee, title, subtitle, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "ZoneLabel"
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(300, 82)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 120
    gui.Parent = adornee

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = title .. "\n" .. subtitle
    text.TextColor3 = color
    text.TextStrokeTransparency = 0.25
    text.Font = Enum.Font.GothamBold
    text.TextSize = 18
    text.TextWrapped = true
    text.Parent = gui
end

local function clearRegion(zone)
    Terrain:FillBlock(
        CFrame.new(zone.Origin + Vector3.new(0, 70, 0)),
        Vector3.new(720, 300, 720),
        Enum.Material.Air
    )
end

local function terrainBlock(zone, offset, size, material)
    Terrain:FillBlock(
        CFrame.new(zone.Origin + offset),
        size,
        material
    )
end

local function terrainBall(zone, offset, radius, material)
    Terrain:FillBall(
        zone.Origin + offset,
        radius,
        material
    )
end

local function makeSpawn(zoneId, zone)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = zoneId .. "_ExpansionSpawn"
    spawn.Size = Vector3.new(12, 1, 12)
    spawn.CFrame = CFrame.new(zone.Origin + Vector3.new(0, zone.GroundY + 8, 0))
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Transparency = 0.2
    spawn.Material = Enum.Material.Neon
    spawn.Color = zone.Color
    spawn.CanCollide = true
    spawn.Parent = zonesFolder
    spawn:SetAttribute("VBExpansionZone", zoneId)
    return spawn
end

local function tree(parent, pos, scale)
    local trunk = part(
        parent,
        "Trunk",
        Vector3.new(3 * scale, 15 * scale, 3 * scale),
        CFrame.new(pos + Vector3.new(0, 7.5 * scale, 0)),
        Color3.fromRGB(86, 63, 48),
        Enum.Material.Wood
    )

    trunk.CanQuery = false

    local crown = part(
        parent,
        "Crown",
        Vector3.new(10 * scale, 10 * scale, 10 * scale),
        CFrame.new(pos + Vector3.new(0, 16 * scale, 0)),
        Color3.fromRGB(69, 123, 84),
        Enum.Material.Grass
    )
    crown.Shape = Enum.PartType.Ball
    crown.CanCollide = false
    crown.CanQuery = false
end

local function crystal(parent, pos, color, height)
    local c = part(
        parent,
        "EchoCrystal",
        Vector3.new(3, height, 3),
        CFrame.new(pos + Vector3.new(0, height * 0.5, 0))
            * CFrame.Angles(0, 0, math.rad(12)),
        color,
        Enum.Material.Neon
    )
    c.CanCollide = false
    c.CanQuery = false
end

local function buildS3(zoneId, zone, model)
    clearRegion(zone)
    terrainBlock(zone, Vector3.new(0, 0, 0), Vector3.new(620, 48, 620), Enum.Material.Rock)
    terrainBlock(zone, Vector3.new(0, 22, 0), Vector3.new(590, 10, 590), Enum.Material.Grass)

    for i = 1, 22 do
        local angle = i * 1.71
        local radius = 75 + (i % 6) * 31
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        tree(model, zone.Origin + Vector3.new(x, zone.GroundY + 4, z), 0.8 + (i % 3) * 0.15)
    end

    terrainBlock(zone, Vector3.new(85, 28, -55), Vector3.new(120, 4, 36), Enum.Material.Mud)
    terrainBall(zone, Vector3.new(-130, 38, 110), 44, Enum.Material.Rock)

    local poi = part(
        model,
        "S3_StoneCircle",
        Vector3.new(34, 2, 34),
        CFrame.new(zone.Origin + Vector3.new(-90, zone.GroundY + 6, -115)),
        Color3.fromRGB(91, 105, 98),
        Enum.Material.Slate
    )
    label(poi, "Cercle des Veilleurs", "Les brumes y retiennent des souvenirs.", zone.Color)
end

local function buildN4(zoneId, zone, model)
    clearRegion(zone)
    terrainBlock(zone, Vector3.new(0, 0, 0), Vector3.new(620, 60, 620), Enum.Material.Rock)
    terrainBlock(zone, Vector3.new(-40, 28, 0), Vector3.new(520, 10, 580), Enum.Material.Slate)

    for i = 1, 10 do
        local x = -220 + i * 42
        terrainBall(zone, Vector3.new(x, 46 + (i % 3) * 12, 180), 30 + (i % 2) * 10, Enum.Material.Rock)
    end

    local bridge = part(
        model,
        "N4_WindBridge",
        Vector3.new(110, 3, 14),
        CFrame.new(zone.Origin + Vector3.new(55, zone.GroundY + 18, -90))
            * CFrame.Angles(0, math.rad(20), 0),
        Color3.fromRGB(155, 150, 137),
        Enum.Material.WoodPlanks
    )
    label(bridge, "Pont des Vents", "Le passage vers les caps de Nacre.", zone.Color)
end

local function buildO5(zoneId, zone, model)
    clearRegion(zone)
    terrainBlock(zone, Vector3.new(0, 0, 0), Vector3.new(620, 52, 620), Enum.Material.Rock)
    terrainBlock(zone, Vector3.new(0, 25, 0), Vector3.new(590, 8, 590), Enum.Material.Ground)

    for i = 1, 12 do
        local x = -180 + (i % 4) * 90
        local z = -160 + math.floor((i - 1) / 4) * 120
        local h = 18 + (i % 3) * 10
        part(
            model,
            "O5_RuinPillar",
            Vector3.new(10, h, 10),
            CFrame.new(zone.Origin + Vector3.new(x, zone.GroundY + 5 + h * 0.5, z)),
            Color3.fromRGB(103, 91, 82),
            Enum.Material.Brick
        )
    end

    local forge = part(
        model,
        "O5_ForgeCourt",
        Vector3.new(75, 3, 75),
        CFrame.new(zone.Origin + Vector3.new(110, zone.GroundY + 7, 80)),
        Color3.fromRGB(91, 78, 72),
        Enum.Material.Cobblestone
    )
    label(forge, "Cour des Forges", "Les marteaux se sont tus, pas l'Écho.", zone.Color)
end

local function buildV6(zoneId, zone, model)
    clearRegion(zone)
    terrainBlock(zone, Vector3.new(0, 0, 0), Vector3.new(620, 54, 620), Enum.Material.Basalt)
    terrainBlock(zone, Vector3.new(0, 26, 0), Vector3.new(590, 8, 590), Enum.Material.Slate)

    for i = 1, 28 do
        local angle = i * 2.11
        local radius = 55 + (i % 8) * 27
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        crystal(
            model,
            zone.Origin + Vector3.new(x, zone.GroundY + 6, z),
            i % 3 == 0 and Color3.fromRGB(104, 218, 232) or Color3.fromRGB(176, 113, 232),
            9 + (i % 5) * 3
        )
    end

    local fissure = part(
        model,
        "V6_ResonanceWell",
        Vector3.new(62, 2, 62),
        CFrame.new(zone.Origin + Vector3.new(-100, zone.GroundY + 7, 95)),
        Color3.fromRGB(66, 57, 87),
        Enum.Material.Basalt
    )
    label(fissure, "Puits de Résonance", "Ici l'Écho répond sans voix.", zone.Color)
end

local BUILDERS = {
    S3 = buildS3,
    N4 = buildN4,
    O5 = buildO5,
    V6 = buildV6,
}

local spawns = {}

for zoneId, zone in pairs(ZONES) do
    local model = Instance.new("Model")
    model.Name = zoneId .. "_" .. zone.Name
    model:SetAttribute("VBExpansionZone", zoneId)
    model.Parent = zonesFolder

    BUILDERS[zoneId](zoneId, zone, model)
    spawns[zoneId] = makeSpawn(zoneId, zone)

    local welcome = part(
        model,
        zoneId .. "_WelcomeStone",
        Vector3.new(5, 10, 5),
        CFrame.new(zone.Origin + Vector3.new(16, zone.GroundY + 10, 8)),
        zone.Color,
        Enum.Material.Slate
    )
    label(welcome, zoneId .. " — " .. zone.Name, zone.Subtitle, zone.Color)
end

local function safePivot(player, cf)
    local character = player.Character
    if not character then
        return false
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not rootPart or not humanoid or humanoid.Health <= 0 then
        return false
    end

    character:PivotTo(cf)
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function homeZoneFor(player)
    local a2 = world:FindFirstChild("A2Spawn")
    local h2 = world:FindFirstChild("H2Spawn")
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not rootPart then
        return "A2"
    end

    if a2 and h2 then
        local da = (rootPart.Position - a2.Position).Magnitude
        local dh = (rootPart.Position - h2.Position).Magnitude
        return da <= dh and "A2" or "H2"
    end

    return a2 and "A2" or "H2"
end

local function travelToExpansion(player, zoneId)
    local spawn = spawns[zoneId]
    if not spawn then
        return
    end

    if not player:GetAttribute("VBHomeZone") then
        player:SetAttribute("VBHomeZone", homeZoneFor(player))
    end

    player:SetAttribute("VBExpansionTravel", true)
    player:SetAttribute("VBExpansionZone", zoneId)

    safePivot(player, spawn.CFrame + Vector3.new(0, 5, 0))
end

local function returnHome(player)
    local homeZone = player:GetAttribute("VBHomeZone") or "A2"
    local spawn = world:FindFirstChild(homeZone .. "Spawn")
        or world:FindFirstChild("A2Spawn")
        or world:FindFirstChild("H2Spawn")

    player:SetAttribute("VBExpansionZone", nil)
    player:SetAttribute("VBExpansionTravel", nil)
    player:SetAttribute("VBHomeZone", nil)

    if spawn then
        safePivot(player, spawn.CFrame + Vector3.new(0, 5, 0))
    end
end

local function portal(parent, name, position, color, actionText, objectText, callback)
    local stone = part(
        parent,
        name,
        Vector3.new(6, 9, 6),
        CFrame.new(position),
        color,
        Enum.Material.Slate
    )

    stone.CanTouch = false

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.HoldDuration = 0.35
    prompt.MaxActivationDistance = 14
    prompt.RequiresLineOfSight = false
    prompt.Parent = stone

    prompt.Triggered:Connect(callback)
    return stone
end

local destinationOrder = {"S3", "N4", "O5", "V6"}

local function makeDepartureHub(spawn, homeName)
    if not spawn then
        return
    end

    local hub = Instance.new("Folder")
    hub.Name = homeName .. "_ExpansionHub"
    hub.Parent = travelFolder

    for index, zoneId in ipairs(destinationOrder) do
        local zone = ZONES[zoneId]
        local angle = (index - 1) / #destinationOrder * math.pi * 2
        local offset = Vector3.new(math.cos(angle) * 18, 5, math.sin(angle) * 18)

        portal(
            hub,
            homeName .. "_To_" .. zoneId,
            spawn.Position + offset,
            zone.Color,
            "Voyager",
            zoneId .. " — " .. zone.Name,
            function(player)
                travelToExpansion(player, zoneId)
            end
        )
    end
end

makeDepartureHub(world:FindFirstChild("A2Spawn"), "A2")
makeDepartureHub(world:FindFirstChild("H2Spawn"), "H2")

for index, zoneId in ipairs(destinationOrder) do
    local zone = ZONES[zoneId]
    local spawn = spawns[zoneId]
    local nextZoneId = destinationOrder[index % #destinationOrder + 1]
    local nextZone = ZONES[nextZoneId]

    portal(
        travelFolder,
        zoneId .. "_Return",
        spawn.Position + Vector3.new(-15, 5, 10),
        Color3.fromRGB(216, 204, 174),
        "Retour",
        "Camp d'origine",
        returnHome
    )

    portal(
        travelFolder,
        zoneId .. "_Next",
        spawn.Position + Vector3.new(15, 5, 10),
        nextZone.Color,
        "Continuer",
        nextZoneId .. " — " .. nextZone.Name,
        function(player)
            travelToExpansion(player, nextZoneId)
        end
    )
end

local function restoreExpansionPosition(player, character)
    task.wait(1)

    local zoneId = player:GetAttribute("VBExpansionZone")
    local spawn = zoneId and spawns[zoneId]

    if spawn and character == player.Character then
        player:SetAttribute("VBExpansionTravel", true)
        safePivot(player, spawn.CFrame + Vector3.new(0, 5, 0))
    end
end

local function watchPlayer(player)
    player.CharacterAdded:Connect(function(character)
        restoreExpansionPosition(player, character)
    end)

    if player.Character then
        task.spawn(restoreExpansionPosition, player, player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    watchPlayer(player)
end

Players.PlayerAdded:Connect(watchPlayer)

-- Filet de sécurité uniquement dans les régions V2.5.
task.spawn(function()
    while root.Parent do
        task.wait(1)

        for _, player in ipairs(Players:GetPlayers()) do
            local zoneId = player:GetAttribute("VBExpansionZone")
            local spawn = zoneId and spawns[zoneId]
            local character = player.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")

            if spawn and rootPart and rootPart.Position.Y < -80 then
                safePivot(player, spawn.CFrame + Vector3.new(0, 6, 0))
            end
        end
    end
end)

print("[Valbrume V2.5] 4 régions d'expansion chargées : S3, N4, O5, V6.")

Generation.Complete(world, "Expansion")

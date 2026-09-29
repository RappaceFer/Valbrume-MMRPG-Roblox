local C = require(game.ReplicatedStorage.Valbrume.Config)

local W = {}

local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = CFrame.new(position)
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function label(parent, adornee, text, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Label"
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(240, 52)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 85
    gui.Parent = parent

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.TextWrapped = true
    textLabel.TextColor3 = color
    textLabel.TextStrokeTransparency = 0.35
    textLabel.Text = text
    textLabel.Parent = gui
end

function W.Build()
    local existing = workspace:FindFirstChild("ValbrumeWorld")
    if existing then
        return existing
    end

    local world = Instance.new("Folder")
    world.Name = "ValbrumeWorld"
    world.Parent = workspace

    for _, name in ipairs({
        "Decor",
        "NPCs",
        "Collectibles",
        "Spawns",
        "Enemies",
    }) do
        local folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = world
    end

    local decor = world.Decor
    local ground = C.GroundY

    part(
        decor,
        "Ground",
        Vector3.new(700, 8, 700),
        Vector3.new(0, ground - 4, 0),
        Color3.fromRGB(98, 133, 89),
        Enum.Material.Grass
    )

    local function road(name, x, z, width, length)
        local p = part(
            decor,
            name,
            Vector3.new(width, 0.2, length),
            Vector3.new(x, ground + 0.08, z),
            Color3.fromRGB(155, 142, 115),
            Enum.Material.Ground
        )
        p.CanQuery = false
    end

    road("VillageRoad", 0, 30, 15, 220)
    road("ForestRoad", 105, 135, 210, 14)
    road("RuinsRoad", 240, 10, 14, 265)

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Spawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.Position = Vector3.new(0, ground + 0.5, 20)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Color = Color3.fromRGB(92, 161, 184)
    spawn.Material = Enum.Material.Slate
    spawn.Parent = world

    local houseLocations = {
        {-45, -35}, {45, -35},
        {-48, 15}, {48, 20},
        {-28, -75}, {28, -75},
    }

    for index, location in ipairs(houseLocations) do
        local x, z = location[1], location[2]

        local house = Instance.new("Model")
        house.Name = "House_" .. index
        house.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
        house.Parent = decor

        local wallColor = Color3.fromRGB(199, 180, 144)
        local roofColor = Color3.fromRGB(82, 107, 130)

        part(
            house, "Walls",
            Vector3.new(20, 12, 18),
            Vector3.new(x, ground + 6, z),
            wallColor, Enum.Material.Plaster
        )

        for side = -1, 1, 2 do
            local roof = part(
                house, "Roof",
                Vector3.new(12, 1, 22),
                Vector3.new(x + side * 5, ground + 14, z),
                roofColor, Enum.Material.Slate
            )
            roof.CFrame *= CFrame.Angles(0, 0, -side * math.rad(25))

            local window = part(
                house, "Window",
                Vector3.new(3, 3, 0.3),
                Vector3.new(x + side * 6, ground + 7, z + 9.2),
                Color3.fromRGB(239, 209, 128),
                Enum.Material.Neon
            )
            window.CanCollide = false
        end

        part(
            house, "Door",
            Vector3.new(4, 7, 0.4),
            Vector3.new(x, ground + 3.5, z + 9.3),
            Color3.fromRGB(91, 68, 51),
            Enum.Material.WoodPlanks
        )
    end

    local rng = Random.new(28761)

    for index = 1, 95 do
        local x = rng:NextNumber(-295, 305)
        local z = rng:NextNumber(-275, 280)

        local forbidden =
            (math.abs(x) < 75 and math.abs(z) < 95)
            or math.abs(x) < 18
            or math.abs(z - 135) < 19
            or math.abs(x - 240) < 20
            or (x > 175 and z < -20)

        for _, spawnInfo in ipairs(C.Spawns) do
            local delta = Vector2.new(x - spawnInfo[2], z - spawnInfo[3])
            if delta.Magnitude < 24 then
                forbidden = true
                break
            end
        end

        if not forbidden then
            local tree = Instance.new("Model")
            tree.Name = "Tree_" .. index
            tree.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
            tree.Parent = decor

            local height = rng:NextNumber(8, 13)

            part(
                tree, "Trunk",
                Vector3.new(2.3, height, 2.3),
                Vector3.new(x, ground + height / 2, z),
                Color3.fromRGB(102, 77, 56),
                Enum.Material.Wood
            )

            for layer = 1, 2 do
                local diameter = 13 - layer * 2
                local leaves = part(
                    tree, "Leaves",
                    Vector3.new(diameter, diameter, diameter),
                    Vector3.new(x, ground + height + layer * 2 - 3, z),
                    Color3.fromRGB(58 + layer * 10, 111 + layer * 12, 72),
                    Enum.Material.Grass
                )
                leaves.Shape = Enum.PartType.Ball
                leaves.CanCollide = false
                leaves.CanQuery = false
            end
        end
    end

    -- Cour des ruines : accessible sans téléportation.
    part(
        decor, "SanctuaryFloor",
        Vector3.new(125, 0.5, 190),
        Vector3.new(240, ground + 0.1, -100),
        Color3.fromRGB(119, 125, 133),
        Enum.Material.Slate
    )

    for index = 1, 10 do
        local angle = index / 10 * math.pi * 2
        local x = 240 + math.cos(angle) * 44
        local z = -155 + math.sin(angle) * 44

        local pillar = part(
            decor, "RuinedPillar",
            Vector3.new(5, 20, 5),
            Vector3.new(x, ground + 10, z),
            Color3.fromRGB(139, 145, 151),
            Enum.Material.Slate
        )

        if index % 3 == 0 then
            pillar.Size = Vector3.new(5, 10, 5)
            pillar.Position -= Vector3.new(0, 5, 0)
        end
    end

    local crystal = part(
        decor, "SanctuaryCrystal",
        Vector3.new(6, 14, 6),
        Vector3.new(240, ground + 9, -180),
        Color3.fromRGB(162, 115, 228),
        Enum.Material.Neon
    )
    crystal.CFrame *= CFrame.Angles(0, math.rad(45), math.rad(10))

    local function createNPC(name, position, color, caption)
        local model = Instance.new("Model")
        model.Name = name
        model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

        local body = part(
            model, "Body",
            Vector3.new(2.5, 4, 1.5),
            position,
            color
        )

        local head = part(
            model, "Head",
            Vector3.new(2, 2, 2),
            position + Vector3.new(0, 3, 0),
            Color3.fromRGB(218, 181, 143)
        )
        head.Shape = Enum.PartType.Ball

        model.PrimaryPart = body
        label(model, head, caption, Color3.fromRGB(255, 222, 131))
        model.Parent = world.NPCs
    end

    createNPC(
        "Nora",
        C.NoraPosition,
        Color3.fromRGB(94, 126, 163),
        "!  Nora\nQuêtes"
    )

    createNPC(
        "Mira",
        Vector3.new(-18, ground + 2, -12),
        Color3.fromRGB(108, 166, 137),
        "Mira\nRepos"
    )

    local shardLocations = {
        {-30, 65}, {-10, 80}, {15, 70},
        {35, 83}, {-35, 90}, {35, 55},
    }

    for index, location in ipairs(shardLocations) do
        local model = Instance.new("Model")
        model.Name = "Shard_" .. index
        model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

        local core = part(
            model, "Core",
            Vector3.new(2, 4, 2),
            Vector3.new(location[1], ground + 2, location[2]),
            Color3.fromRGB(108, 223, 230),
            Enum.Material.Neon
        )
        core.CFrame *= CFrame.Angles(0, math.rad(45), math.rad(12))
        core.CanCollide = false

        model.PrimaryPart = core
        model.Parent = world.Collectibles
    end

    for index, spawnInfo in ipairs(C.Spawns) do
        local marker = part(
            world.Spawns, "Spawn_" .. index,
            Vector3.new(1, 1, 1),
            Vector3.new(spawnInfo[2], ground + 3, spawnInfo[3]),
            Color3.new(1, 1, 1)
        )
        marker.Transparency = 1
        marker.CanCollide = false
        marker.CanQuery = false
        marker.CanTouch = false
        marker:SetAttribute("MobId", spawnInfo[1])
    end

    local lighting = game:GetService("Lighting")
    lighting.ClockTime = 14
    lighting.Brightness = 2
    lighting.Ambient = Color3.fromRGB(105, 111, 123)
    lighting.OutdoorAmbient = Color3.fromRGB(140, 146, 150)
    lighting.FogColor = Color3.fromRGB(172, 193, 201)
    lighting.FogStart = 200
    lighting.FogEnd = 680

    return world
end

function W.CreateEnemy(mobId, marker, parent)
    local definition = C.Mobs[mobId]
    local scale = definition.Scale or 1
    local position = marker.Position + Vector3.new(0, (scale - 1) * 3, 0)

    local model = Instance.new("Model")
    model.Name = mobId
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model:SetAttribute("MobId", mobId)
    model:SetAttribute("Evading", false)
    -- Publish identity before parenting: cleanup and grounding observe ChildAdded.
    model:SetAttribute("ZoneId", marker:GetAttribute("ZoneId"))
    model:SetAttribute("DungeonId", marker:GetAttribute("DungeonId"))

    local function limb(name, size, offset, color)
        local p = part(model, name, size, position + offset, color)
        p.Anchored = false
        p.CanCollide = false
        p.Massless = name ~= "HumanoidRootPart"
        return p
    end

    local root = limb(
        "HumanoidRootPart",
        Vector3.new(2, 2, 1),
        Vector3.zero,
        definition.Color
    )
    root.Transparency = 1

    local torso = limb(
        "Torso",
        Vector3.new(2, 2, 1),
        Vector3.zero,
        definition.Color
    )
    torso.CanCollide = true

    local head = limb(
        "Head",
        Vector3.new(2, 1, 1),
        Vector3.new(0, 1.5, 0),
        definition.Color:Lerp(Color3.new(1, 1, 1), 0.15)
    )

    local rightArm = limb(
        "Right Arm", Vector3.new(1, 2, 1),
        Vector3.new(1.5, 0, 0), definition.Color
    )
    local leftArm = limb(
        "Left Arm", Vector3.new(1, 2, 1),
        Vector3.new(-1.5, 0, 0), definition.Color
    )
    local rightLeg = limb(
        "Right Leg", Vector3.new(1, 2, 1),
        Vector3.new(0.5, -2, 0), definition.Color
    )
    local leftLeg = limb(
        "Left Leg", Vector3.new(1, 2, 1),
        Vector3.new(-0.5, -2, 0), definition.Color
    )

    local function motor(name, a, b, c0, c1)
        local joint = Instance.new("Motor6D")
        joint.Name = name
        joint.Part0 = a
        joint.Part1 = b
        joint.C0 = c0
        joint.C1 = c1
        joint.Parent = a
    end

    motor("RootJoint", root, torso, CFrame.identity, CFrame.identity)
    motor("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    motor("Right Shoulder", torso, rightArm, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
    motor("Left Shoulder", torso, leftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
    motor("Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
    motor("Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))

    local humanoid = Instance.new("Humanoid")
    humanoid.RequiresNeck = false
    humanoid.BreakJointsOnDeath = false
    humanoid.MaxHealth = definition.Health
    humanoid.Health = definition.Health
    humanoid.WalkSpeed = definition.Speed
    humanoid.DisplayName = definition.Name .. " — Niv. " .. definition.Level
    humanoid.NameDisplayDistance = 70
    humanoid.HealthDisplayDistance = 70
    humanoid.Parent = model

    model.PrimaryPart = root
    model:ScaleTo(scale)
    model.Parent = parent

    pcall(function()
        root:SetNetworkOwner(nil)
    end)

    return model, humanoid, root
end

function W.EquipVisual(character, classId, tier)
    local old = character:FindFirstChild("VB_Equipment")
    if old then
        old:Destroy()
    end

    local hand = character:FindFirstChild("RightHand")
        or character:FindFirstChild("Right Arm")
    local torso = character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")

    if not hand or not torso then
        return
    end

    local folder = Instance.new("Folder")
    folder.Name = "VB_Equipment"
    folder.Parent = character

    local color = C.Classes[classId].Color

    local function welded(name, size, bodyPart, offset, material)
        local p = part(folder, name, size, Vector3.zero, color, material)
        p.Anchored = false
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.Massless = true
        p.CFrame = bodyPart.CFrame * offset

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = bodyPart
        weld.Part1 = p
        weld.Parent = p

        return p
    end

    welded(
        "Chest",
        Vector3.new(2.05, 1.5, 0.25),
        torso,
        CFrame.new(0, 0, -0.65),
        Enum.Material.Metal
    )

    if classId == "Bastion" then
        welded(
            "Blade",
            Vector3.new(0.45, 3.5 + tier * 0.3, 0.3),
            hand,
            CFrame.new(0, -1.5, -0.2),
            Enum.Material.Metal
        )
    elseif classId == "Eclaireur" then
        welded(
            "Bow",
            Vector3.new(0.3, 3.4, 0.4),
            hand,
            CFrame.new(0, -0.5, -0.5) * CFrame.Angles(0, 0, 0.2),
            Enum.Material.Wood
        )
    else
        welded(
            "Staff",
            Vector3.new(0.3, 4.8, 0.3),
            hand,
            CFrame.new(0, -0.4, -0.3),
            Enum.Material.Wood
        )

        local orb = welded(
            "Focus",
            Vector3.new(0.85, 0.85, 0.85),
            hand,
            CFrame.new(0, 2.1, -0.3),
            Enum.Material.Neon
        )
        orb.Shape = Enum.PartType.Ball
    end
end

-- VALBRUME_V2_WORLD
local Terrain = workspace.Terrain

local function vbAbsolute(zoneId, relative)
    return C.Zones[zoneId].Origin + relative
end

local function vbTerrainBlock(zoneId, relative, size, material, angle)
    local cf = CFrame.new(vbAbsolute(zoneId, relative))
    if angle then
        cf *= CFrame.Angles(0, math.rad(angle), 0)
    end
    Terrain:FillBlock(cf, size, material)
end

local function vbTerrainBall(zoneId, relative, radius, material)
    Terrain:FillBall(vbAbsolute(zoneId, relative), radius, material)
end

local function vbSurface(zoneId, x, z, fallback)
    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Include
    parameters.FilterDescendantsInstances = {Terrain}

    local origin = C.Zones[zoneId].Origin + Vector3.new(x, 220, z)
    local result = workspace:Raycast(origin, Vector3.new(0, -400, 0), parameters)
    return result and result.Position.Y or fallback
end

local function vbClearZone(zoneId)
    Terrain:FillBlock(
        CFrame.new(C.Zones[zoneId].Origin + Vector3.new(0, 70, 0)),
        Vector3.new(650, 280, 650),
        Enum.Material.Air
    )
end

local function vbHouse(parent, position, bodyColor, roofColor, scale)
    scale = scale or 1

    local model = Instance.new("Model")
    model.Name = "House"
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model.Parent = parent

    part(
        model,
        "Walls",
        Vector3.new(20, 12, 18) * scale,
        position + Vector3.new(0, 6 * scale, 0),
        bodyColor,
        Enum.Material.Plaster
    )

    for side = -1, 1, 2 do
        local roof = part(
            model,
            "Roof",
            Vector3.new(12, 1.1, 22) * scale,
            position + Vector3.new(side * 5 * scale, 14 * scale, 0),
            roofColor,
            Enum.Material.Slate
        )
        roof.CFrame *= CFrame.Angles(0, 0, -side * math.rad(25))
    end
end

local function vbTree(parent, zoneId, x, z, rng, autumn)
    local zone = C.Zones[zoneId]
    local y = vbSurface(zoneId, x, z, zone.GroundY)

    local model = Instance.new("Model")
    model.Name = "Tree"
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model.Parent = parent

    local height = rng:NextNumber(9, 15)

    part(
        model,
        "Trunk",
        Vector3.new(2.2, height, 2.2),
        Vector3.new(zone.Origin.X + x, y + height / 2, z),
        Color3.fromRGB(94, 67, 46),
        Enum.Material.Wood
    )

    for layer = 1, 2 do
        local diameter = 13 - layer * 2
        local leaves = part(
            model,
            "Leaves",
            Vector3.new(diameter, diameter, diameter),
            Vector3.new(zone.Origin.X + x, y + height + layer * 2 - 3, z),
            autumn
                and Color3.fromRGB(184, 116 + layer * 5, 61)
                or Color3.fromRGB(59 + layer * 9, 117 + layer * 10, 76),
            Enum.Material.Grass
        )
        leaves.Shape = Enum.PartType.Ball
        leaves.CanCollide = false
        leaves.CanQuery = false
    end
end

local function vbCactus(parent, zoneId, x, z, rng)
    local zone = C.Zones[zoneId]
    local y = vbSurface(zoneId, x, z, zone.GroundY)
    local h = rng:NextNumber(7, 13)

    local model = Instance.new("Model")
    model.Name = "Cactus"
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model.Parent = parent

    part(
        model,
        "Trunk",
        Vector3.new(2.1, h, 2.1),
        Vector3.new(zone.Origin.X + x, y + h / 2, z),
        Color3.fromRGB(82, 132, 89),
        Enum.Material.Grass
    )
end

local function vbNPC(world, zoneId, role, name, relative, color, caption)
    local model = Instance.new("Model")
    model.Name = name .. "_" .. zoneId
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model:SetAttribute("ZoneId", zoneId)
    model:SetAttribute("Role", role)

    local zone = C.Zones[zoneId]
    local surfaceY = vbSurface(zoneId, relative.X, relative.Z, zone.GroundY)
    local position = Vector3.new(zone.Origin.X + relative.X, surfaceY + 3, relative.Z)
    local body = part(model, "Body", Vector3.new(2.5, 4, 1.5), position, color)

    local head = part(
        model,
        "Head",
        Vector3.new(2, 2, 2),
        position + Vector3.new(0, 3, 0),
        Color3.fromRGB(218, 181, 143)
    )
    head.Shape = Enum.PartType.Ball

    model.PrimaryPart = body
    label(model, head, caption, Color3.fromRGB(255, 222, 131))
    model.Parent = world.NPCs
end

local function vbCrystal(world, zoneId, index, x, z, color)
    local zone = C.Zones[zoneId]
    local y = vbSurface(zoneId, x, z, zone.GroundY)

    local model = Instance.new("Model")
    model.Name = zoneId .. "_Shard_" .. index
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model:SetAttribute("ZoneId", zoneId)

    local core = part(
        model,
        "Core",
        Vector3.new(2, 4, 2),
        Vector3.new(zone.Origin.X + x, y + 2.2, z),
        color,
        Enum.Material.Neon
    )
    core.CFrame *= CFrame.Angles(0, math.rad(45), math.rad(12))
    core.CanCollide = false

    model.PrimaryPart = core
    model.Parent = world.Collectibles
end

local function vbBuildA2(world)
    local zone = C.Zones.A2
    local rng = Random.new(62021)

    vbClearZone("A2")
    vbTerrainBlock("A2", Vector3.new(0, -8, 0), Vector3.new(600, 60, 600), Enum.Material.Rock)
    vbTerrainBlock("A2", Vector3.new(0, 20, 0), Vector3.new(575, 12, 575), Enum.Material.Grass)

    for _, h in ipairs({
        {-240, 37, -15, 92}, {-190, 46, -185, 83}, {-80, 44, -245, 78},
        {100, 46, -245, 86}, {230, 39, -155, 88}, {250, 34, 80, 84},
        {-225, 36, 180, 82}, {155, 40, 210, 78},
    }) do
        vbTerrainBall("A2", Vector3.new(h[1], h[2], h[3]), h[4], Enum.Material.Rock)
        vbTerrainBall("A2", Vector3.new(h[1], h[2] + 8, h[3]), h[4] - 13, Enum.Material.Grass)
    end

    -- Coupe d'une vallée dans le relief, puis rivière visuelle au fond.
    vbTerrainBlock("A2", Vector3.new(55, 30, 20), Vector3.new(31, 55, 460), Enum.Material.Air, 7)

    local water = part(
        world.Decor,
        "A2_River",
        Vector3.new(25, 1.2, 440),
        vbAbsolute("A2", Vector3.new(55, 17, 20)),
        Color3.fromRGB(73, 165, 204),
        Enum.Material.Glass
    )
    water.Transparency = 0.28
    water.CanCollide = false
    water.CFrame *= CFrame.Angles(0, math.rad(7), 0)

    part(
        world.Decor,
        "A2_VillageSquare",
        Vector3.new(115, 1, 105),
        vbAbsolute("A2", Vector3.new(-35, 26, 15)),
        Color3.fromRGB(148, 140, 120),
        Enum.Material.Cobblestone
    )

    local bridge = part(
        world.Decor,
        "A2_Bridge",
        Vector3.new(58, 2, 13),
        vbAbsolute("A2", Vector3.new(55, 29, 65)),
        Color3.fromRGB(102, 77, 53),
        Enum.Material.WoodPlanks
    )
    bridge.CFrame *= CFrame.Angles(0, math.rad(7), 0)

    vbHouse(world.Decor, vbAbsolute("A2", Vector3.new(-68, 26, 20)), Color3.fromRGB(201,184,148), Color3.fromRGB(75,103,130))
    vbHouse(world.Decor, vbAbsolute("A2", Vector3.new(-68, 26, -28)), Color3.fromRGB(193,178,143), Color3.fromRGB(75,101,126))
    vbHouse(world.Decor, vbAbsolute("A2", Vector3.new(-25, 26, 48)), Color3.fromRGB(206,188,151), Color3.fromRGB(73,98,122))

    for i = 1, 8 do
        local angle = i / 8 * math.pi * 2
        local x = 240 + math.cos(angle) * 38
        local z = -155 + math.sin(angle) * 38

        part(
            world.Decor,
            "A2_RuinPillar",
            Vector3.new(4.5, 20, 4.5),
            vbAbsolute("A2", Vector3.new(x, 31, z)),
            Color3.fromRGB(132, 145, 158),
            Enum.Material.Slate
        )
    end

    for _ = 1, 88 do
        local x = rng:NextNumber(-255, 245)
        local z = rng:NextNumber(-250, 245)
        local village = x > -125 and x < 35 and z > -80 and z < 75
        local river = math.abs(x - 55) < 37
        local ruins = (Vector2.new(x - 240, z + 155)).Magnitude < 70

        if not village and not river and not ruins then
            vbTree(world.Decor, "A2", x, z, rng, z < -130 and rng:NextNumber() < 0.45)
        end
    end

    vbNPC(world, "A2", "Quest", "Elyra", C.NoraPosition, Color3.fromRGB(83,126,170), "!  Elyra\nExpédition A2")
    vbNPC(world, "A2", "Heal", "Solen", Vector3.new(-18,22,-12), Color3.fromRGB(101,166,134), "Solen\nRepos")

    for i, p in ipairs({
        {-30,65}, {-10,80}, {15,70}, {35,83}, {-35,90}, {35,55},
    }) do
        vbCrystal(world, "A2", i, p[1], p[2], Color3.fromRGB(100, 220, 234))
    end
end

local function vbBuildH2(world)
    local zone = C.Zones.H2
    local rng = Random.new(62022)

    vbClearZone("H2")
    vbTerrainBlock("H2", Vector3.new(0, -10, 0), Vector3.new(600, 64, 600), Enum.Material.Rock)
    vbTerrainBlock("H2", Vector3.new(0, 18, 0), Vector3.new(575, 10, 575), Enum.Material.Sand)

    -- Mesas plus verticales/plates que les montagnes d'A2.
    for _, m in ipairs({
        {-235, 34, -35, 76}, {-180, 43, -190, 70}, {-45, 46, -245, 72},
        {120, 43, -238, 80}, {235, 36, -140, 74}, {250, 33, 85, 78},
        {-225, 36, 180, 70}, {150, 39, 210, 68},
    }) do
        vbTerrainBall("H2", Vector3.new(m[1], m[2], m[3]), m[4], Enum.Material.Rock)
        vbTerrainBlock(
            "H2",
            Vector3.new(m[1], m[2] + 34, m[3]),
            Vector3.new(m[4] * 1.1, 24, m[4] * 0.86),
            Enum.Material.Sand
        )
    end

    -- Canyon diagonal profond.
    vbTerrainBlock("H2", Vector3.new(45, 28, 5), Vector3.new(54, 86, 470), Enum.Material.Air, -17)

    part(
        world.Decor,
        "H2_OutpostFloor",
        Vector3.new(115, 1, 105),
        vbAbsolute("H2", Vector3.new(-35, 24, 15)),
        Color3.fromRGB(151, 112, 82),
        Enum.Material.Sandstone
    )

    local bridge = part(
        world.Decor,
        "H2_CanyonBridge",
        Vector3.new(72, 2, 11),
        vbAbsolute("H2", Vector3.new(45, 31, 63)),
        Color3.fromRGB(97, 67, 47),
        Enum.Material.WoodPlanks
    )
    bridge.CFrame *= CFrame.Angles(0, math.rad(-17), 0)

    for _, p in ipairs({{-72,20}, {-70,-28}, {-25,48}}) do
        vbHouse(
            world.Decor,
            vbAbsolute("H2", Vector3.new(p[1], 24, p[2])),
            Color3.fromRGB(176, 133, 93),
            Color3.fromRGB(108, 69, 56),
            0.9
        )
    end

    part(
        world.Decor,
        "H2_TitanPit",
        Vector3.new(100, 2, 100),
        vbAbsolute("H2", Vector3.new(240, 24, -155)),
        Color3.fromRGB(101, 82, 76),
        Enum.Material.Rock
    )

    for i = 1, 8 do
        local angle = i / 8 * math.pi * 2
        local x = 240 + math.cos(angle) * 42
        local z = -155 + math.sin(angle) * 42

        local spike = part(
            world.Decor,
            "H2_BasaltSpike",
            Vector3.new(5, 19 + (i % 2) * 8, 5),
            vbAbsolute("H2", Vector3.new(x, 31, z)),
            Color3.fromRGB(74, 66, 63),
            Enum.Material.Slate
        )
        spike.CFrame *= CFrame.Angles(0, 0, math.rad((i % 2) * 7))
    end

    for _ = 1, 54 do
        local x = rng:NextNumber(-255, 250)
        local z = rng:NextNumber(-250, 245)
        local outpost = x > -125 and x < 35 and z > -80 and z < 75
        local canyon = math.abs(x - 45) < 58
        local boss = (Vector2.new(x - 240, z + 155)).Magnitude < 72

        if not outpost and not canyon and not boss then
            if rng:NextNumber() < 0.56 then
                vbCactus(world.Decor, "H2", x, z, rng)
            else
                local y = vbSurface("H2", x, z, zone.GroundY)
                local rock = part(
                    world.Decor,
                    "H2_DesertRock",
                    Vector3.new(
                        rng:NextNumber(3, 9),
                        rng:NextNumber(3, 12),
                        rng:NextNumber(3, 9)
                    ),
                    Vector3.new(zone.Origin.X + x, y + 3, z),
                    Color3.fromRGB(130, 91, 71),
                    Enum.Material.Rock
                )
                rock.CFrame *= CFrame.Angles(
                    rng:NextNumber(-0.15,0.15),
                    rng:NextNumber(0,math.pi),
                    rng:NextNumber(-0.15,0.15)
                )
            end
        end
    end

    vbNPC(world, "H2", "Quest", "Rhaz", C.NoraPosition, Color3.fromRGB(160,84,64), "!  Rhaz\nExpédition H2")
    vbNPC(world, "H2", "Heal", "Tahla", Vector3.new(-18,22,-12), Color3.fromRGB(180,142,90), "Tahla\nRepos")

    for i, p in ipairs({
        {-30,65}, {-10,80}, {15,70}, {35,83}, {-35,90}, {35,55},
    }) do
        vbCrystal(world, "H2", i, p[1], p[2], Color3.fromRGB(244, 174, 76))
    end
end

function W.Build()
    local existing = workspace:FindFirstChild("ValbrumeWorld")
    if existing then
        existing:Destroy()
    end

    local world = Instance.new("Folder")
    world.Name = "ValbrumeWorld"
    world.Parent = workspace

    for _, name in ipairs({"Decor", "NPCs", "Collectibles", "Spawns", "Enemies"}) do
        local folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = world
    end

    -- Petit lobby neutre pendant le choix zone/classe.
    part(
        world.Decor,
        "SelectionPlatform",
        Vector3.new(50, 2, 50),
        Vector3.new(0, 320, 0),
        Color3.fromRGB(46, 55, 70),
        Enum.Material.Slate
    )

    local neutralSpawn = Instance.new("SpawnLocation")
    neutralSpawn.Name = "Spawn"
    neutralSpawn.Size = Vector3.new(8, 1, 8)
    neutralSpawn.Position = Vector3.new(0, 322, 0)
    neutralSpawn.Anchored = true
    neutralSpawn.Neutral = true
    neutralSpawn.Duration = 0
    neutralSpawn.Transparency = 1
    neutralSpawn.Parent = world

    vbBuildA2(world)
    vbBuildH2(world)

    for _, zoneId in ipairs({"A2", "H2"}) do
        local zone = C.Zones[zoneId]

        local spawn = Instance.new("SpawnLocation")
        spawn.Name = zoneId .. "Spawn"
        spawn.Size = Vector3.new(8, 1, 8)
        local spawnY = vbSurface(zoneId, C.Spawn.X, C.Spawn.Z, zone.GroundY)
        spawn.Position = Vector3.new(zone.Origin.X + C.Spawn.X, spawnY + 1, C.Spawn.Z)
        spawn.Anchored = true
        spawn.Neutral = true
        spawn.Duration = 0
        spawn.Transparency = 0.25
        spawn.Color = zone.Color
        spawn.Material = Enum.Material.Slate
        spawn.Parent = world

        for index, spawnInfo in ipairs(C.Spawns) do
            local x = spawnInfo[2]
            local z = spawnInfo[3]
            local y = vbSurface(zoneId, x, z, zone.GroundY)

            local marker = part(
                world.Spawns,
                zoneId .. "_Spawn_" .. index,
                Vector3.one,
                Vector3.new(zone.Origin.X + x, y + 3, z),
                Color3.new(1,1,1)
            )

            marker.Transparency = 1
            marker.CanCollide = false
            marker.CanQuery = false
            marker.CanTouch = false
            marker:SetAttribute("MobId", spawnInfo[1])
            marker:SetAttribute("ZoneId", zoneId)
        end
    end

    return world
end

return W

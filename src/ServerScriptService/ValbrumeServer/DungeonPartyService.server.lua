local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local package = game.ReplicatedStorage:WaitForChild("Valbrume")
local C = require(package.Config)
local PartyRemote = package:WaitForChild("PartyRemote")
local State = package:WaitForChild("State")

local server = script.Parent
local SpawnRequest = server:WaitForChild("DungeonSpawnRequest")
local MobDied = server:WaitForChild("DungeonMobDied")

local Generation = require(script.Parent.WorldGeneration)
local world = Generation.Await("ExpansionStory")
local decor = world:WaitForChild("Decor")

local dungeons = world:FindFirstChild("Dungeons")
if not dungeons then
    dungeons = Instance.new("Folder")
    dungeons.Name = "Dungeons"
    dungeons.Parent = world
end

local staging = {A2 = nil, H2 = nil}
local memberships = {}
local active = {}
local usedSlots = {A2 = {}, H2 = {}}
local nextPartyId = 0

local MAX_MEMBERS = 5
local MAX_SLOTS = 4

local function message(player, value)
    if player and player.Parent then
        State:FireClient(player, "Message", value)
    end
end

local function membersArray(party)
    local result = {}
    for player in pairs(party.Members) do
        if player.Parent then
            table.insert(result, player)
        end
    end

    table.sort(result, function(a, b)
        return a.UserId < b.UserId
    end)

    return result
end

local function sendPartyState(party)
    local names = {}
    for _, player in ipairs(membersArray(party)) do
        table.insert(names, {
            UserId = player.UserId,
            Name = player.DisplayName,
            Leader = player == party.Leader,
        })
    end

    for player in pairs(party.Members) do
        if player.Parent then
            PartyRemote:FireClient(player, "State", {
                PartyId = party.Id,
                Zone = party.Zone,
                Started = party.Started,
                Members = names,
                LeaderUserId = party.Leader and party.Leader.UserId or 0,
            })
        end
    end
end

local function clearPartyState(player)
    if player and player.Parent then
        PartyRemote:FireClient(player, "State", false)
    end
end

local function zoneSpawn(zoneId)
    return world:FindFirstChild(zoneId .. "Spawn")
end

local function teleportHome(player, zoneId)
    local spawn = zoneSpawn(zoneId)
    local character = player.Character

    if spawn and character then
        character:PivotTo(spawn.CFrame + Vector3.new(0, 5, 0))
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end

    player:SetAttribute("VBDungeonId", nil)
end

local function chooseNewLeader(party)
    local list = membersArray(party)
    party.Leader = list[1]
end

local function releaseSlot(party)
    if party.Slot then
        usedSlots[party.Zone][party.Slot] = nil
    end
end

local function destroyParty(party, returnPlayers)
    if party.Destroyed then
        return
    end
    party.Destroyed = true

    if staging[party.Zone] == party then
        staging[party.Zone] = nil
    end

    active[party.Id] = nil
    releaseSlot(party)

    for player in pairs(party.Members) do
        memberships[player] = nil
        clearPartyState(player)
        if returnPlayers then
            teleportHome(player, party.Zone)
        else
            player:SetAttribute("VBDungeonId", nil)
        end
    end

    local enemyFolder = world:FindFirstChild("Enemies")
    if enemyFolder then
        for _, enemy in ipairs(enemyFolder:GetChildren()) do
            if enemy:GetAttribute("DungeonId") == party.Id then
                enemy:Destroy()
            end
        end
    end

    if party.Model then
        party.Model:Destroy()
    end
end

local function removeMember(player, returnHome)
    local party = memberships[player]
    if not party then
        return
    end

    party.Members[player] = nil
    memberships[player] = nil
    clearPartyState(player)

    if returnHome then
        teleportHome(player, party.Zone)
    end

    if next(party.Members) == nil then
        destroyParty(party, false)
        return
    end

    if party.Leader == player then
        chooseNewLeader(party)
    end

    sendPartyState(party)
end

local function part(parent, name, size, position, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Color = color
    p.Material = material or Enum.Material.Slate
    p.Parent = parent
    return p
end

local function dungeonBase(party)
    -- Les instances sont volontairement loin des maps ouvertes.
    -- Chaque slot reçoit sa propre cellule spatiale pour le streaming.
    local side = party.Zone == "A2" and -1 or 1
    return Vector3.new(
        side * 1900,
        160 + (party.Slot - 1) * 25,
        (party.Slot - 1) * 520
    )
end

local function warningCircle(party, position, radius)
    if party.Destroyed or party.Completed then
        return
    end

    local warning = part(
        party.Model,
        "Danger",
        Vector3.new(0.35, radius * 2, radius * 2),
        position,
        Color3.fromRGB(240, 103, 68),
        Enum.Material.Neon
    )
    warning.Shape = Enum.PartType.Cylinder
    warning.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
    warning.Transparency = 0.45
    warning.CanCollide = false
    warning.CanQuery = false

    task.delay(1.6, function()
        if not warning.Parent or party.Destroyed or party.Completed then
            return
        end

        for player in pairs(party.Members) do
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if humanoid
                and root
                and humanoid.Health > 0
                and player:GetAttribute("VBDungeonId") == party.Id then
                local delta = root.Position - position
                local horizontal = Vector2.new(delta.X, delta.Z).Magnitude

                if horizontal <= radius and math.abs(delta.Y) <= 12 then
                    humanoid:TakeDamage(math.max(25, humanoid.MaxHealth * 0.28))
                end
            end
        end

        warning.Transparency = 0.88
        Debris:AddItem(warning, 0.35)
    end)
end

local function createMarker(party, mobId, stage, relative)
    local marker = Instance.new("Part")
    marker.Name = "DungeonMarker_" .. mobId
    marker.Size = Vector3.one
    marker.Transparency = 1
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanQuery = false
    marker.CanTouch = false
    marker.Position = dungeonBase(party) + relative
    marker:SetAttribute("MobId", mobId)
    marker:SetAttribute("ZoneId", party.Zone)
    marker:SetAttribute("DungeonId", party.Id)
    marker:SetAttribute("DungeonStage", stage)
    marker:SetAttribute("DungeonNoRespawn", true)
    marker.Parent = party.Model
    return marker
end

local function spawnWave(party, stage, mobId, positions)
    party.Stage = stage
    party.AliveInStage = #positions

    for _, relative in ipairs(positions) do
        local marker = createMarker(party, mobId, stage, relative)
        SpawnRequest:Fire(marker)
    end
end

local function startBossPhases(party)
    task.spawn(function()
        task.wait(8)

        if party.Destroyed or party.Completed or party.Stage ~= 3 then
            return
        end

        message(party.Leader, "Phase 2 : des Acolytes répondent à l'appel du boss !")

        for _, relative in ipairs({
            Vector3.new(-18, 4, -118),
            Vector3.new(18, 4, -118),
        }) do
            local marker = createMarker(party, "MistAcolyte", 30, relative)
            SpawnRequest:Fire(marker)
        end

        task.wait(8)

        local cycle = 0
        while not party.Destroyed and not party.Completed and party.Stage == 3 do
            cycle += 1
            local base = dungeonBase(party)

            local offsets = cycle % 2 == 0
                and {
                    Vector3.new(-20, 1.1, -140),
                    Vector3.new(12, 1.1, -125),
                    Vector3.new(25, 1.1, -155),
                }
                or {
                    Vector3.new(20, 1.1, -140),
                    Vector3.new(-12, 1.1, -125),
                    Vector3.new(-25, 1.1, -155),
                }

            for _, offset in ipairs(offsets) do
                warningCircle(party, base + offset, 10)
            end

            task.wait(9)
        end
    end)
end

local function advance(party)
    if party.Destroyed or party.Completed then
        return
    end

    if party.Stage == 0 then
        message(party.Leader, "Étape 1 : brise la première garde.")
        spawnWave(party, 1, "MistAcolyte", {
            Vector3.new(-10, 4, 40),
            Vector3.new(10, 4, 40),
            Vector3.new(0, 4, 18),
        })

    elseif party.Stage == 1 then
        message(party.Leader, "Étape 2 : les Gardiens runiques s'éveillent.")
        spawnWave(party, 2, "StoneWarden", {
            Vector3.new(-14, 4, -45),
            Vector3.new(14, 4, -45),
        })

    elseif party.Stage == 2 then
        message(party.Leader, "Boss : Seigneur de l'Écho.")
        spawnWave(party, 3, "EchoLord", {
            Vector3.new(0, 5, -140),
        })
        startBossPhases(party)
    end
end

local function buildDungeon(party)
    local base = dungeonBase(party)

    local model = Instance.new("Model")
    model.Name = "Dungeon_" .. party.Id
    model:SetAttribute("DungeonId", party.Id)
    model.Parent = dungeons
    party.Model = model

    local floorColor = party.Zone == "A2"
        and Color3.fromRGB(93, 109, 127)
        or Color3.fromRGB(117, 82, 70)

    -- Trois grandes salles reliées : très lisible pour mobile.
    for _, z in ipairs({70, -35, -140}) do
        part(
            model,
            "Floor",
            Vector3.new(70, 2, 70),
            base + Vector3.new(0, 0, z),
            floorColor,
            Enum.Material.Slate
        )
    end

    for _, z in ipairs({18, -88}) do
        part(
            model,
            "Bridge",
            Vector3.new(20, 2, 42),
            base + Vector3.new(0, 0, z),
            Color3.fromRGB(72, 76, 86),
            Enum.Material.Rock
        )
    end

    for _, z in ipairs({70, -35, -140}) do
        for _, x in ipairs({-35, 35}) do
            part(
                model,
                "Wall",
                Vector3.new(3, 18, 70),
                base + Vector3.new(x, 9, z),
                Color3.fromRGB(61, 66, 78),
                Enum.Material.Slate
            )
        end
    end

    -- Spawn du groupe dans la première salle.
    party.RespawnPosition = base + Vector3.new(0, 5, 92)

    for index, player in ipairs(membersArray(party)) do
        player:SetAttribute("VBDungeonId", party.Id)

        local character = player.Character
        if character then
            character:PivotTo(
                CFrame.new(base + Vector3.new((index - 3) * 5, 5, 92))
            )

            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

    party.Stage = 0
    advance(party)
end

local function allocateSlot(zoneId)
    for slot = 1, MAX_SLOTS do
        if not usedSlots[zoneId][slot] then
            usedSlots[zoneId][slot] = true
            return slot
        end
    end
end

local function startParty(party)
    if party.Started or party.Destroyed then
        return
    end

    local slot = allocateSlot(party.Zone)
    if not slot then
        message(party.Leader, "Toutes les instances sont occupées. Réessaie dans quelques instants.")
        return
    end

    party.Started = true
    party.Slot = slot
    staging[party.Zone] = nil
    active[party.Id] = party
    sendPartyState(party)
    buildDungeon(party)
end

local function joinStaging(player, zoneId)
    if memberships[player] then
        message(player, "Tu es déjà dans un groupe.")
        return
    end

    local party = staging[zoneId]

    if not party then
        nextPartyId += 1
        party = {
            Id = zoneId .. "_" .. nextPartyId,
            Zone = zoneId,
            Members = {},
            Leader = player,
            Started = false,
            Destroyed = false,
            Completed = false,
            Stage = 0,
        }
        staging[zoneId] = party
    end

    local count = 0
    for _ in pairs(party.Members) do
        count += 1
    end

    if count >= MAX_MEMBERS then
        message(player, "Le groupe est complet (5 joueurs).")
        return
    end

    party.Members[player] = true
    memberships[player] = party
    message(player, player == party.Leader and "Groupe créé. Tu es leader." or "Tu rejoins le groupe d'expédition.")
    sendPartyState(party)
end

local function addGate(zoneId, relative, titleText)
    local zone = C.Zones[zoneId]
    local model = Instance.new("Model")
    model.Name = "DungeonGate_" .. zoneId
    model.Parent = decor

    local stone = part(
        model,
        "Stone",
        Vector3.new(8, 10, 3),
        zone.Origin + relative,
        zone.Color,
        Enum.Material.Slate
    )
    model.PrimaryPart = stone

    local gui = Instance.new("BillboardGui")
    gui.Adornee = stone
    gui.Size = UDim2.fromOffset(260, 70)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 100
    gui.Parent = model

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = titleText .. "\nGroupe 1–5 joueurs"
    label.TextColor3 = zone.Color
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextSize = 17
    label.TextWrapped = true
    label.Parent = gui

    local join = Instance.new("ProximityPrompt")
    join.Name = "Join"
    join.ActionText = "Créer / rejoindre groupe"
    join.ObjectText = "Pierre d'expédition"
    join.HoldDuration = 0.25
    join.MaxActivationDistance = 13
    join.RequiresLineOfSight = false
    join.Parent = stone

    join.Triggered:Connect(function(player)
        joinStaging(player, zoneId)
    end)

    local start = Instance.new("ProximityPrompt")
    start.Name = "Start"
    start.ActionText = "Lancer le donjon"
    start.ObjectText = "Leader uniquement"
    start.HoldDuration = 0.8
    start.MaxActivationDistance = 13
    start.RequiresLineOfSight = false
    start.KeyboardKeyCode = Enum.KeyCode.F
    start.Parent = stone

    start.Triggered:Connect(function(player)
        local party = memberships[player]

        if not party or party.Zone ~= zoneId or party.Started then
            message(player, "Rejoins d'abord un groupe d'expédition.")
            return
        end

        if party.Leader ~= player then
            message(player, "Seul le leader peut lancer le donjon.")
            return
        end

        startParty(party)
    end)
end

addGate("A2", Vector3.new(-105, 31, 90), "Sanctuaire des Échos")
addGate("H2", Vector3.new(-105, 29, 90), "Faille de Khar")

MobDied.Event:Connect(function(dungeonId, mobId, stage)
    local party = active[dungeonId]

    if not party or party.Destroyed or party.Completed then
        return
    end

    if stage == party.Stage then
        party.AliveInStage = math.max(0, (party.AliveInStage or 1) - 1)

        if party.AliveInStage == 0 then
            if party.Stage < 3 then
                advance(party)
            elseif party.Stage == 3 and mobId == "EchoLord" then
                party.Completed = true

                for player in pairs(party.Members) do
                    message(player, "Donjon terminé ! Retour au camp dans 10 secondes.")
                end

                task.delay(10, function()
                    destroyParty(party, true)
                end)
            end
        end
    end
end)

PartyRemote.OnServerEvent:Connect(function(player, action)
    if action == "Leave" then
        removeMember(player, true)
    end
end)

local function bindDungeonRespawn(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.8)

        local party = memberships[player]
        if not party
            or party.Destroyed
            or not party.Started
            or not party.RespawnPosition then
            return
        end

        if not character.Parent then
            return
        end

        player:SetAttribute("VBDungeonId", party.Id)
        character:PivotTo(CFrame.new(party.RespawnPosition))

        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

Players.PlayerAdded:Connect(bindDungeonRespawn)
for _, player in ipairs(Players:GetPlayers()) do
    bindDungeonRespawn(player)
end

Players.PlayerRemoving:Connect(function(player)
    removeMember(player, false)
end)

print("[Valbrume V2.1 FIXED] Party + donjon chargés.")

Generation.Complete(world, "Dungeon")
Generation.Complete(world, "Ready")

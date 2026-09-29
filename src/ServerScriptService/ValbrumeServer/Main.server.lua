local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local Package = game.ReplicatedStorage:WaitForChild("Valbrume")
local C = require(Package.Config)
local W = require(script.Parent.WorldBuilder)
local Data = require(script.Parent.PlayerDataService)

local Request = Package.Request
local State = Package.State
local Effects = Package.Effects

local Generation = require(script.Parent.WorldGeneration)
local world = W.Build()
Generation.Begin(world)
local states = {}
local enemies = {}
local random = Random.new()
local shuttingDown = false

local DungeonSpawnRequest = script.Parent:WaitForChild("DungeonSpawnRequest")
local DungeonMobDied = script.Parent:WaitForChild("DungeonMobDied")
local WorldMobDiedV23 = script.Parent:WaitForChild("WorldMobDiedV23")
local StoryRewardV23 = script.Parent:WaitForChild("StoryRewardV23")

Players.CharacterAutoLoads = false

Data.Configure(script.Parent:GetAttribute("EnableSaving") == true)

local function now()
    return workspace:GetServerTimeNow()
end

local function characterParts(player)
    local character = player.Character
    if not character then
        return nil, nil, nil
    end

    return character,
        character:FindFirstChild("HumanoidRootPart"),
        character:FindFirstChildOfClass("Humanoid")
end

local function living(player)
    local profile = Data.Get(player)
    local character, root, humanoid = characterParts(player)

    if not profile
        or not profile.Class
        or not character
        or not root
        or not humanoid
        or humanoid.Health <= 0 then
        return nil
    end

    return root, humanoid, profile
end

local function notify(player, message)
    if player.Parent then
        State:FireClient(player, "Message", message)
    end
end

local function emit(info)
    for _, player in ipairs(Players:GetPlayers()) do
        local _, root = characterParts(player)

        if root and (root.Position - info.Position).Magnitude <= 210 then
            Effects:FireClient(player, info)
        end
    end
end

local function computeStats(profile)
    local class = C.Classes[profile.Class]
    if not class then
        return nil
    end

    local stats = {
        Health = class.Health + (profile.Level - 1) * 24,
        Power = class.Power + (profile.Level - 1) * 3,
        Armor = class.Armor + (profile.Level - 1),
    }

    for _, id in pairs(profile.Equipment) do
        local item = C.Items[id]
        if item then
            stats.Health += item.Health
            stats.Power += item.Power
            stats.Armor += item.Armor
        end
    end

    return stats
end

local function applyStats(player, fullHeal)
    local profile = Data.Get(player)
    local state = states[player]
    local character, root, humanoid = characterParts(player)

    if not profile or not state or not character or not root or not humanoid then
        return
    end

    root.Anchored = false

    local stats = computeStats(profile)
    if not stats then
        return
    end

    humanoid.MaxHealth = stats.Health
    humanoid.Health = fullHeal
        and stats.Health
        or math.min(humanoid.Health, stats.Health)

    humanoid.WalkSpeed = state.HasteUntil > now() and 25 or 16

    if fullHeal then
        state.Mana = 100
    end

    local weapon = C.Items[profile.Equipment.Weapon]
    W.EquipVisual(character, profile.Class, weapon and weapon.Tier or 1)
end

local function push(player)
    local profile = Data.Get(player)
    local state = states[player]

    if not profile or not state or not player.Parent then
        return
    end

    local _, _, humanoid = characterParts(player)
    local stats = computeStats(profile)

    State:FireClient(player, "State", {
        Zone = state.Zone or profile.Zone,
        Class = profile.Class,
        Level = profile.Level,
        XP = profile.XP,
        NextXP = C.RequiredXP(profile.Level),
        Gold = profile.Gold,
        Inventory = table.clone(profile.Inventory),
        Equipment = table.clone(profile.Equipment),
        QuestIndex = profile.QuestIndex,
        QuestActive = profile.QuestActive,
        QuestProgress = profile.QuestProgress,

        Health = humanoid and humanoid.Health or 0,
        MaxHealth = stats and stats.Health or 100,
        Mana = state.Mana,
        Stats = stats,

        Cooldowns = table.clone(state.Cooldowns),
        GCD = state.GCD,
        CastStart = state.CastStart,
        CastEnd = state.CastEnd,
        CastName = state.CastName,

        Saving = Data.Enabled,
    })
end

local function grantItem(player, id)
    local profile = Data.Get(player)
    local item = C.Items[id]

    if not profile or not item then
        return
    end

    if profile.Inventory[id] then
        profile.Gold += 5
        return
    end

    profile.Inventory[id] = true
    notify(player, "Loot : " .. item.Name .. " — disponible dans le sac.")
end

local function grantXP(player, amount)
    local profile = Data.Get(player)
    if not profile or profile.Level >= C.MaxLevel then
        return
    end

    profile.XP += amount
    local leveled = false

    while profile.Level < C.MaxLevel
        and profile.XP >= C.RequiredXP(profile.Level) do
        profile.XP -= C.RequiredXP(profile.Level)
        profile.Level += 1
        leveled = true
    end

    if profile.Level >= C.MaxLevel then
        profile.XP = 0
    end

    if leveled then
        applyStats(player, true)
        notify(player, "Niveau " .. profile.Level .. " !")

        local _, root = characterParts(player)
        if root then
            emit({
                Kind = "Ring",
                Position = root.Position,
                Radius = 7,
                Duration = 0.7,
                Color = Color3.fromRGB(248, 214, 104),
            })
        end
    end
end

StoryRewardV23.Event:Connect(function(player, xp, gold, itemId)
    local profile = Data.Get(player)
    if not profile then return end

    profile.Gold += math.max(0, math.floor(tonumber(gold) or 0))
    grantXP(player, math.max(0, math.floor(tonumber(xp) or 0)))

    if type(itemId) == "string" and C.Items[itemId] then
        grantItem(player, itemId)
    end

    push(player)
end)

local function questProgress(player, kind, target)
    local profile = Data.Get(player)

    if not profile or not profile.QuestActive then
        return
    end

    local quest = C.Quests[profile.QuestIndex]

    if quest and quest.Kind == kind and quest.Target == target then
        local previous = profile.QuestProgress
        profile.QuestProgress = math.min(quest.Count, previous + 1)

        if previous < quest.Count and profile.QuestProgress == quest.Count then
            notify(player, "Objectif terminé : retourne voir Nora.")
        end
    end
end

local function clearLine(origin, destination, ignored, targetModel)
    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = ignored

    local result = workspace:Raycast(
        origin,
        destination - origin,
        parameters
    )

    return not result
        or (targetModel and result.Instance:IsDescendantOf(targetModel))
end

local function addThreat(enemy, player, amount)
    local entry = enemy.Threat[player] or {Amount = 0, Time = 0}
    entry.Amount += amount
    entry.Time = now()
    enemy.Threat[player] = entry
end

local function damageEnemy(player, enemy, amount, stun)
    if not enemy or not enemy.Alive or enemy.Returning then
        return
    end

    local state = states[player]
    if not state or not living(player) then
        return
    end

    local damage = math.max(
        1,
        math.floor(amount * 100 / (100 + enemy.Definition.Armor))
    )

    addThreat(enemy, player, damage)
    state.LastCombat = now()

    if stun then
        enemy.StunUntil = math.max(enemy.StunUntil, now() + stun)
    end

    local hitPosition = enemy.Root.Position + Vector3.new(0, 2, 0)
    enemy.Humanoid:TakeDamage(damage)

    emit({
        Kind = "Hit",
        Position = hitPosition,
        Amount = damage,
        Color = Color3.fromRGB(255, 224, 144),
    })
end

local function damagePlayer(player, amount)
    local root, humanoid, profile = living(player)
    local state = states[player]

    if not root or not state then
        return
    end

    local stats = computeStats(profile)
    local damage = amount * 100 / (100 + stats.Armor)

    if state.GuardUntil > now() then
        damage *= 0.5
    end

    damage = math.max(1, math.floor(damage))
    state.LastCombat = now()
    humanoid:TakeDamage(damage)

    emit({
        Kind = "Hit",
        Position = root.Position + Vector3.new(0, 3, 0),
        Amount = damage,
        Color = Color3.fromRGB(247, 116, 113),
    })
end

local function validEnemyTarget(player, model, range)
    if typeof(model) ~= "Instance" or not model:IsA("Model") then
        return nil
    end

    local enemy = enemies[model]
    local root = living(player)

    if not root
        or not enemy
        or not enemy.Alive
        or enemy.Returning
        or enemy.Humanoid.Health <= 0
        or not model:IsDescendantOf(world.Enemies) then
        return nil
    end

    if (root.Position - enemy.Root.Position).Magnitude > range then
        return nil
    end

    if not clearLine(
        root.Position + Vector3.new(0, 1, 0),
        enemy.Root.Position,
        {player.Character},
        model
    ) then
        return nil
    end

    return enemy
end

local function useAbility(player, index, targetModel)
    if type(index) ~= "number"
        or index % 1 ~= 0
        or index < 1
        or index > 4 then
        return
    end

    local root, _, profile = living(player)
    local state = states[player]

    if not root or not state then
        return
    end

    local skill = C.Classes[profile.Class].Skills[index]
    local time = now()

    if state.CastEnd > time
        or state.GCD > time
        or state.Cooldowns[index] > time then
        return
    end

    if state.Mana < skill.Cost then
        notify(player, "Ressource insuffisante.")
        return
    end

    if skill.Effect == "Damage"
        and not validEnemyTarget(player, targetModel, skill.Range) then
        notify(player, "Choisis une cible vivante, à portée et en vue.")
        return
    end

    state.Mana -= skill.Cost
    state.GCD = time + 1
    state.Cooldowns[index] = time + skill.Cooldown
    state.LastCombat = time
    state.CastId += 1

    local castId = state.CastId
    local castCharacter = player.Character
    local startPosition = root.Position

    state.CastStart = time
    state.CastEnd = time + skill.Cast
    state.CastName = skill.Name

    push(player)

    task.delay(skill.Cast, function()
        local currentRoot, _, currentProfile = living(player)
        local currentState = states[player]

        if not currentRoot
            or not currentState
            or currentState.CastId ~= castId
            or player.Character ~= castCharacter then
            return
        end

        currentState.CastEnd = 0
        currentState.CastName = ""

        if skill.Cast > 0
            and (currentRoot.Position - startPosition).Magnitude > 6 then
            notify(player, "Incantation interrompue par le déplacement.")
            push(player)
            return
        end

        local stats = computeStats(currentProfile)
        local color = C.Classes[currentProfile.Class].Color
        local power = (skill.Base or 0) + stats.Power * (skill.Scale or 0)

        if skill.Effect == "Damage" then
            local enemy = validEnemyTarget(player, targetModel, skill.Range)

            if enemy then
                emit({
                    Kind = "Bolt",
                    Position = currentRoot.Position + Vector3.new(0, 1, 0),
                    Target = enemy.Root.Position,
                    Color = color,
                })
                damageEnemy(player, enemy, power, skill.Stun)
            else
                notify(player, "La cible n'est plus disponible.")
            end

        elseif skill.Effect == "Blast" then
            local hits = 0

            for model, enemy in pairs(enemies) do
                if hits >= 8 then
                    break
                end

                if validEnemyTarget(player, model, skill.Radius) then
                    damageEnemy(player, enemy, power, skill.Stun)
                    hits += 1
                end
            end

            emit({
                Kind = "Ring",
                Position = currentRoot.Position,
                Radius = skill.Radius,
                Duration = 0.6,
                Color = color,
            })

        elseif skill.Effect == "Taunt" then
            for model, enemy in pairs(enemies) do
                if validEnemyTarget(player, model, skill.Radius) then
                    local highest = 0
                    for _, entry in pairs(enemy.Threat) do
                        highest = math.max(highest, entry.Amount)
                    end

                    addThreat(enemy, player, highest + 100)
                    enemy.ForcedTarget = player
                    enemy.ForcedUntil = now() + skill.Duration
                end
            end

            emit({
                Kind = "Ring",
                Position = currentRoot.Position,
                Radius = skill.Radius,
                Duration = 0.5,
                Color = color,
            })

        elseif skill.Effect == "Guard" then
            currentState.GuardUntil = now() + skill.Duration
            notify(player, "Protection : dégâts reçus réduits de 50 %.")

            emit({
                Kind = "Ring",
                Position = currentRoot.Position,
                Radius = 5,
                Duration = skill.Duration,
                Color = color,
            })

        elseif skill.Effect == "Haste" then
            currentState.HasteUntil = now() + skill.Duration
            notify(player, "Élan : vitesse augmentée.")

        elseif skill.Effect == "Heal" then
            local totalHealed = 0

            for _, ally in ipairs(Players:GetPlayers()) do
                local allyRoot, allyHumanoid = living(ally)

                if allyRoot
                    and (allyRoot.Position - currentRoot.Position).Magnitude <= skill.Radius
                    and clearLine(
                        currentRoot.Position,
                        allyRoot.Position,
                        {player.Character},
                        ally.Character
                    ) then
                    local amount = math.min(
                        power,
                        allyHumanoid.MaxHealth - allyHumanoid.Health
                    )

                    allyHumanoid.Health += amount
                    totalHealed += amount

                    emit({
                        Kind = "Hit",
                        Position = allyRoot.Position + Vector3.new(0, 3, 0),
                        Amount = math.floor(amount),
                        Healing = true,
                        Color = Color3.fromRGB(116, 233, 158),
                    })
                end
            end

            if totalHealed > 0 then
                for _, enemy in pairs(enemies) do
                    if next(enemy.Threat)
                        and (enemy.Root.Position - currentRoot.Position).Magnitude < 80 then
                        addThreat(enemy, player, totalHealed * 0.5)
                    end
                end
            end
        end

        push(player)
    end)
end

-- Navigation limitée : une requête de chemin à la fois par ennemi.
local function moveEnemy(enemy, destination)
    enemy.Desired = destination

    if clearLine(
        enemy.Root.Position,
        destination,
        {world.Enemies},
        enemy.Target and enemy.Target.Character or nil
    ) then
        enemy.Waypoints = nil
        enemy.Humanoid:MoveTo(destination)
        return
    end

    if enemy.Waypoints then
        local waypoint = enemy.Waypoints[enemy.WaypointIndex]

        if waypoint
            and (waypoint.Position - enemy.Root.Position).Magnitude < 4.5 then
            enemy.WaypointIndex += 1
            waypoint = enemy.Waypoints[enemy.WaypointIndex]
        end

        if waypoint then
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                enemy.Humanoid.Jump = true
            end
            enemy.Humanoid:MoveTo(waypoint.Position)
        end
    end

    if enemy.PathPending or now() < enemy.NextPath then
        return
    end

    enemy.PathPending = true
    enemy.NextPath = now() + 1.4

    local goal = destination
    local start = enemy.Root.Position

    task.spawn(function()
        local path = PathfindingService:CreatePath({
            AgentRadius = 2 * enemy.Definition.Scale,
            AgentHeight = 6 * enemy.Definition.Scale,
            AgentCanJump = true,
            WaypointSpacing = 5,
        })

        local ok = pcall(function()
            path:ComputeAsync(start, goal)
        end)

        enemy.PathPending = false

        if not enemy.Alive then
            return
        end

        if ok
            and path.Status == Enum.PathStatus.Success
            and enemy.Desired
            and (enemy.Desired - goal).Magnitude < 15 then
            enemy.Waypoints = path:GetWaypoints()
            enemy.WaypointIndex = 2
        end
    end)
end

local function beginReturn(enemy)
    if enemy.Returning then
        return
    end

    enemy.Returning = true
    enemy.ReturnStarted = now()
    enemy.Threat = {}
    enemy.Target = nil
    enemy.ForcedTarget = nil
    enemy.Waypoints = nil
    enemy.Humanoid.Health = enemy.Humanoid.MaxHealth
    enemy.Model:SetAttribute("Evading", true)
end

local spawnEnemy

spawnEnemy = function(marker)
    local mobId = marker:GetAttribute("MobId")
    local definition = C.Mobs[mobId]

    if not definition or not marker:IsDescendantOf(workspace) then
        return
    end

    local model, humanoid, root = W.CreateEnemy(mobId, marker, world.Enemies)

    local dungeonIdForModel = marker:GetAttribute("DungeonId")
    if dungeonIdForModel then
        model:SetAttribute("DungeonId", dungeonIdForModel)
    end

    local enemy = {
        Model = model,
        Humanoid = humanoid,
        Root = root,
        Home = root.Position,
        Definition = definition,
        MobId = mobId,
        Alive = true,
        Threat = {},
        Returning = false,
        StunUntil = 0,
        ForcedUntil = 0,
        NextAttack = 0,
        NextSlam = now() + 6,
        WindupUntil = 0,
        NextPath = 0,
        PathPending = false,
        WaypointIndex = 2,
    }

    enemies[model] = enemy

    model.Destroying:Connect(function()
        enemies[model] = nil
    end)

    humanoid.Died:Connect(function()
        if not enemy.Alive then
            return
        end

        enemy.Alive = false
        enemies[model] = nil

        local dungeonId = marker:GetAttribute("DungeonId")
        if dungeonId then
            DungeonMobDied:Fire(
                dungeonId,
                mobId,
                marker:GetAttribute("DungeonStage") or 0
            )
        end

        for player, contribution in pairs(enemy.Threat) do
            local playerRoot, _, profile = living(player)

            if playerRoot
                and contribution.Amount > 0
                and now() - contribution.Time <= 30
                and (playerRoot.Position - root.Position).Magnitude <= 110 then
                profile.Gold += definition.Gold
                grantXP(player, definition.XP)
                questProgress(player, "Kill", mobId)

                if not marker:GetAttribute("DungeonId") then
                    WorldMobDiedV23:Fire(
                        player,
                        mobId,
                        marker:GetAttribute("ZoneId"),
                        root.Position
                    )
                end

                if definition.Boss or random:NextNumber() < 0.40 then
                    local tier = definition.Level >= 6 and 3
                        or definition.Level >= 3 and 2
                        or 1

                    local slot = random:NextNumber() < 0.5 and "Weapon" or "Armor"
                    grantItem(player, profile.Class .. "_" .. slot .. "_" .. tier)
                end

                push(player)
            end
        end

        Debris:AddItem(model, 3)

        if not marker:GetAttribute("DungeonNoRespawn") then
            task.delay(definition.Respawn, function()
                if not shuttingDown and marker:IsDescendantOf(workspace) then
                    spawnEnemy(marker)
                end
            end)
        end
    end)
end

task.spawn(function()
    Generation.Await("SafeSpawns")
    for _, marker in ipairs(world.Spawns:GetChildren()) do spawnEnemy(marker) end
    Generation.Complete(world, "Population")
end)

DungeonSpawnRequest.Event:Connect(function(marker)
    if typeof(marker) == "Instance"
        and marker:IsA("BasePart")
        and marker:IsDescendantOf(workspace) then
        spawnEnemy(marker)
    end
end)

local function updateEnemy(enemy, time)
    if not enemy.Alive or not enemy.Model.Parent then
        return
    end

    if enemy.Root.Position.Y < C.GroundY - 15 then
        enemy.Model:PivotTo(CFrame.new(enemy.Home))
        beginReturn(enemy)
    end

    if enemy.Returning then
        if (enemy.Root.Position - enemy.Home).Magnitude < 5 then
            enemy.Returning = false
            enemy.Model:SetAttribute("Evading", false)
            enemy.Humanoid:MoveTo(enemy.Root.Position)
        elseif time - enemy.ReturnStarted > 9 then
            enemy.Model:PivotTo(CFrame.new(enemy.Home))
            enemy.Root.AssemblyLinearVelocity = Vector3.zero
        else
            moveEnemy(enemy, enemy.Home)
        end
        return
    end

    if enemy.StunUntil > time or enemy.WindupUntil > time then
        enemy.Humanoid:MoveTo(enemy.Root.Position)
        return
    end

    local target
    local bestThreat = -1

    for player, entry in pairs(enemy.Threat) do
        local playerRoot = living(player)

        if not playerRoot
            or (playerRoot.Position - enemy.Home).Magnitude > 95
            or time - entry.Time > 35 then
            enemy.Threat[player] = nil
        elseif entry.Amount > bestThreat then
            target = player
            bestThreat = entry.Amount
        end
    end

    if enemy.ForcedTarget and enemy.ForcedUntil > time then
        local forcedRoot = living(enemy.ForcedTarget)
        if forcedRoot and (forcedRoot.Position - enemy.Home).Magnitude < 95 then
            target = enemy.ForcedTarget
        end
    end

    if not target then
        local nearest = enemy.Definition.Boss and 34 or 27

        for _, player in ipairs(Players:GetPlayers()) do
            local playerRoot = living(player)

            if playerRoot then
                local distance = (playerRoot.Position - enemy.Root.Position).Magnitude

                if distance < nearest
                    and clearLine(
                        enemy.Root.Position,
                        playerRoot.Position,
                        {world.Enemies},
                        player.Character
                    ) then
                    target = player
                    nearest = distance
                end
            end
        end

        if target then
            addThreat(enemy, target, 1)
        end
    end

    if not target then
        if enemy.Humanoid.Health < enemy.Humanoid.MaxHealth
            or (enemy.Root.Position - enemy.Home).Magnitude > 5 then
            beginReturn(enemy)
        end
        return
    end

    local targetRoot = living(target)
    if not targetRoot then
        return
    end

    if (enemy.Root.Position - enemy.Home).Magnitude > 78 then
        beginReturn(enemy)
        return
    end

    enemy.Target = target

    local distance = (targetRoot.Position - enemy.Root.Position).Magnitude
    local attackRange = 5.5 * enemy.Definition.Scale

    if enemy.Definition.Boss and distance < 24 and time >= enemy.NextSlam then
        local center = enemy.Root.Position
        local radius = 19
        local duration = 1.6

        enemy.WindupUntil = time + duration
        enemy.NextSlam = time + 9
        enemy.Humanoid:MoveTo(center)

        emit({
            Kind = "Warning",
            Position = center + Vector3.new(0, 0.6, 0),
            Radius = radius,
            Duration = duration,
            Color = Color3.fromRGB(243, 124, 70),
        })

        task.delay(duration, function()
            if not enemy.Alive or enemy.Returning or enemy.StunUntil > now() then
                return
            end

            for _, player in ipairs(Players:GetPlayers()) do
                local playerRoot = living(player)

                if playerRoot then
                    local delta = playerRoot.Position - center
                    local horizontal = Vector2.new(delta.X, delta.Z).Magnitude

                    if horizontal <= radius
                        and math.abs(delta.Y) <= 10
                        and clearLine(center, playerRoot.Position, {world.Enemies}, player.Character) then
                        damagePlayer(player, enemy.Definition.Damage * 2)
                        addThreat(enemy, player, 1)
                    end
                end
            end

            emit({
                Kind = "Ring",
                Position = center,
                Radius = radius,
                Duration = 0.5,
                Color = Color3.fromRGB(234, 79, 97),
            })
        end)

        return
    end

    if distance <= attackRange then
        enemy.Humanoid:MoveTo(enemy.Root.Position)

        if time >= enemy.NextAttack
            and clearLine(enemy.Root.Position, targetRoot.Position, {world.Enemies}, target.Character) then
            enemy.NextAttack = time + 1.6
            addThreat(enemy, target, 1)
            damagePlayer(target, enemy.Definition.Damage)
        end
    else
        moveEnemy(enemy, targetRoot.Position)
    end
end

local function nearNPC(player, model)
    local root = living(player)
    return root
        and model.PrimaryPart
        and (root.Position - model.PrimaryPart.Position).Magnitude <= 19
end

local function addPrompt(part, action, object, callback)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = action
    prompt.ObjectText = object
    prompt.MaxActivationDistance = 13
    prompt.HoldDuration = 0.15
    prompt.RequiresLineOfSight = false
    prompt.Parent = part

    prompt.Triggered:Connect(callback)
end

local function setupQuestNPC(npc)
    addPrompt(npc.PrimaryPart, "Parler / rendre", npc.Name, function(player)
        local profile = Data.Get(player)
        local state = states[player]
        local npcZone = npc:GetAttribute("ZoneId")

        if not profile
            or not state
            or state.Zone ~= npcZone
            or not nearNPC(player, npc) then
            return
        end

        if now() - state.LastPrompt < 0.5 then
            return
        end
        state.LastPrompt = now()

        local quest = C.Quests[profile.QuestIndex]

        if not quest then
            notify(player, npc.Name .. " : tu as terminé l'expédition de cette zone.")
            return
        end

        if not profile.QuestActive then
            profile.QuestActive = true
            profile.QuestProgress = 0
            notify(player, "Quête acceptée : " .. quest.Name)

        elseif profile.QuestProgress >= quest.Count then
            profile.QuestActive = false
            profile.QuestProgress = 0
            profile.QuestIndex += 1
            profile.Gold += quest.Gold

            grantXP(player, quest.XP)

            if quest.Tier then
                grantItem(player, profile.Class .. "_Weapon_" .. quest.Tier)
            end

            notify(player, "Quête rendue : +" .. quest.XP .. " XP, +" .. quest.Gold .. " or.")

        else
            notify(
                player,
                quest.Description .. "  " .. profile.QuestProgress .. "/" .. quest.Count
            )
        end

        push(player)
    end)
end

for _, npc in ipairs(world.NPCs:GetChildren()) do
    if npc:GetAttribute("Role") == "Quest" then
        setupQuestNPC(npc)
    end
end

local function setupHealerNPC(npc)
    addPrompt(npc.PrimaryPart, "Se reposer", npc.Name, function(player)
        local root, humanoid = living(player)
        local state = states[player]

        if not root
            or not state
            or state.Zone ~= npc:GetAttribute("ZoneId")
            or not nearNPC(player, npc) then
            return
        end

        if now() - state.LastCombat < 8 then
            notify(player, "Termine le combat avant de te reposer.")
            return
        end

        humanoid.Health = humanoid.MaxHealth
        state.Mana = 100
        notify(player, npc.Name .. " : te voilà prêt à repartir.")
        push(player)
    end)
end

for _, npc in ipairs(world.NPCs:GetChildren()) do
    if npc:GetAttribute("Role") == "Heal" then
        setupHealerNPC(npc)
    end
end

for _, crystal in ipairs(world.Collectibles:GetChildren()) do
    addPrompt(crystal.PrimaryPart, "Récolter", "Éclat de brume", function(player)
        local root, _, profile = living(player)
        local state = states[player]

        if not root or not state then
            return
        end

        if (root.Position - crystal.PrimaryPart.Position).Magnitude > 17 then
            return
        end

        local quest = C.Quests[profile.QuestIndex]

        if not profile.QuestActive or not quest or quest.Kind ~= "Collect" then
            notify(player, "Nora pourra te parler de ces cristaux.")
            return
        end

        if (state.Harvested[crystal.Name] or 0) > now() then
            notify(player, "Cherche un autre cristal.")
            return
        end

        state.Harvested[crystal.Name] = now() + 30
        questProgress(player, "Collect", "Shard")
        push(player)
    end)
end

local function loadCharacter(player)
    if not player.Parent or not states[player] or shuttingDown then
        return
    end

    local ok, message = pcall(function()
        player:LoadCharacterAsync()
    end)

    if not ok then
        warn("[Valbrume] Chargement du personnage : " .. tostring(message))
    end
end

local function playerAdded(player)
    Generation.Await("Ready")
    if states[player] then
        return
    end

    local state = {
        Zone = false,
        Mana = 100,
        Cooldowns = {0, 0, 0, 0},
        GCD = 0,
        CastId = 0,
        CastStart = 0,
        CastEnd = 0,
        CastName = "",
        GuardUntil = 0,
        HasteUntil = 0,
        LastCombat = 0,
        LastPrompt = 0,
        RecallUntil = 0,
        Harvested = {},
        Tokens = 16,
        TokenTime = now(),
    }

    states[player] = state

    local profile, errorMessage = Data.Open(player)

    if not profile then
        states[player] = nil
        player:Kick("Chargement du profil impossible : " .. tostring(errorMessage))
        return
    end

    if not player.Parent then
        Data.Close(player)
        states[player] = nil
        return
    end

    state.Zone = profile.Zone

    if profile.Zone and world:FindFirstChild(profile.Zone .. "Spawn") then
        player.RespawnLocation = world[profile.Zone .. "Spawn"]
    else
        player.RespawnLocation = world.Spawn
    end

    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid", 12)
        local root = character:WaitForChild("HumanoidRootPart", 12)

        if not humanoid or not root or not states[player] then
            return
        end

        -- Neutralise la régénération par défaut, remplacée par la boucle RPG.
        local defaultHealth = character:FindFirstChild("Health")
        if defaultHealth and defaultHealth:IsA("Script") then
            defaultHealth.Disabled = true
        end

        state.CastId += 1
        state.CastEnd = 0
        state.CastName = ""
        state.GuardUntil = 0
        state.HasteUntil = 0
        state.Mana = 100

        applyStats(player, true)

        humanoid.Died:Connect(function()
            state.CastId += 1
            state.CastEnd = 0
            state.CastName = ""

            task.delay(4, function()
                loadCharacter(player)
            end)
        end)

        push(player)
    end)

    push(player)
    loadCharacter(player)
end

Request.OnServerEvent:Connect(function(player, action, a, b)
    if type(action) ~= "string" or #action > 24 then
        return
    end

    local state = states[player]
    if not state then
        return
    end

    local time = now()
    state.Tokens = math.min(16, state.Tokens + (time - state.TokenTime) * 10)
    state.TokenTime = time

    if state.Tokens < 1 then
        return
    end
    state.Tokens -= 1

    local profile = Data.Get(player)
    if not profile then
        return
    end

    if action == "Sync" then
        push(player)

    elseif action == "ChooseZone" then
        if profile.Class
            or type(a) ~= "string"
            or not C.Zones[a] then
            return
        end

        state.Zone = a
        push(player)

    elseif action == "ChooseClass" then
        if profile.Class
            or not state.Zone
            or type(a) ~= "string"
            or not C.Classes[a] then
            return
        end

        profile.Zone = state.Zone
        profile.Class = a

        for _, slot in ipairs({"Weapon", "Armor"}) do
            local id = a .. "_" .. slot .. "_1"
            profile.Inventory[id] = true
            profile.Equipment[slot] = id
        end

        local zoneSpawn = world:FindFirstChild(state.Zone .. "Spawn")

        if zoneSpawn and player.Character then
            player.RespawnLocation = zoneSpawn
            player.Character:PivotTo(zoneSpawn.CFrame + Vector3.new(0, 5, 0))

            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end

        applyStats(player, true)
        notify(
            player,
            "Bienvenue dans " .. C.Zones[state.Zone].Short
                .. ". Trouve le donneur de quête près du camp."
        )
        push(player)

    elseif action == "Ability" then
        useAbility(player, a, b)

    elseif action == "Equip" then
        if type(a) ~= "string" or #a > 80 or not living(player) then
            return
        end

        local item = C.Items[a]

        if not item
            or not profile.Inventory[a]
            or item.Class ~= profile.Class
            or item.Level > profile.Level then
            notify(player, "Équipement indisponible pour ton personnage.")
            return
        end

        if time - state.LastCombat < 8 then
            notify(player, "Change d'équipement hors combat.")
            return
        end

        profile.Equipment[item.Slot] = a
        applyStats(player, false)
        notify(player, "Équipé : " .. item.Name)
        push(player)

    elseif action == "Recall" then
        local root = living(player)

        if not root or state.CastEnd > time then
            return
        end

        if time - state.LastCombat < 10 then
            notify(player, "Rappel impossible pendant le combat.")
            return
        end

        if state.RecallUntil > time then
            notify(player, "Le rappel est encore en recharge.")
            return
        end

        state.RecallUntil = time + 30
        state.CastId += 1
        state.CastStart = time
        state.CastEnd = time + 4
        state.CastName = "Retour au village"

        local castId = state.CastId
        local startPosition = root.Position
        local startCharacter = player.Character
        local lastCombat = state.LastCombat

        push(player)

        task.delay(4, function()
            local currentRoot = living(player)

            if not currentRoot
                or not states[player]
                or state.CastId ~= castId
                or player.Character ~= startCharacter then
                return
            end

            state.CastEnd = 0
            state.CastName = ""

            if state.LastCombat ~= lastCombat
                or (currentRoot.Position - startPosition).Magnitude > 6 then
                notify(player, "Rappel interrompu.")
            else
                local zoneSpawn = state.Zone
                    and world:FindFirstChild(state.Zone .. "Spawn")

                if zoneSpawn then
                    player.Character:PivotTo(zoneSpawn.CFrame + Vector3.new(0, 5, 0))
                    currentRoot.AssemblyLinearVelocity = Vector3.zero
                    currentRoot.AssemblyAngularVelocity = Vector3.zero
                end
            end

            push(player)
        end)
    end
end)

Players.PlayerAdded:Connect(function(player)
    task.spawn(playerAdded, player)
end)

Players.PlayerRemoving:Connect(function(player)
    states[player] = nil
    Data.Close(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(playerAdded, player)
end

task.spawn(function()
    local previous = now()
    local nextPush = 0

    while not shuttingDown do
        task.wait(0.2)

        local time = now()
        local dt = math.min(time - previous, 0.5)
        previous = time

        for player, state in pairs(states) do
            local root, humanoid = living(player)

            if root then
                state.Mana = math.min(100, state.Mana + dt * 9)

                humanoid.WalkSpeed = state.HasteUntil > time and 25 or 16

                if time - state.LastCombat > 8 then
                    humanoid.Health = math.min(
                        humanoid.MaxHealth,
                        humanoid.Health + humanoid.MaxHealth * 0.025 * dt
                    )
                end

                if not player:GetAttribute("VBExpansionTravel") and state.Zone and C.Zones[state.Zone] then
                    local zone = C.Zones[state.Zone]
                    local delta = root.Position - zone.Origin

                    -- VBDungeonId and boundary bypass
                    if not player:GetAttribute("VBDungeonId")
                        and (Vector2.new(delta.X, delta.Z).Magnitude > zone.Boundary
                            or root.Position.Y < -40) then
                        local zoneSpawn = world:FindFirstChild(state.Zone .. "Spawn")

                        if zoneSpawn then
                            player.Character:PivotTo(zoneSpawn.CFrame + Vector3.new(0, 5, 0))
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero
                            notify(player, "Frontière de " .. zone.Short .. " : retour au camp.")
                        end
                    end
                end
            end
        end

        for _, enemy in pairs(enemies) do
            updateEnemy(enemy, time)
        end

        if time >= nextPush then
            nextPush = time + 0.5

            for player in pairs(states) do
                push(player)
            end
        end

        Lighting.ClockTime = (Lighting.ClockTime + dt * 0.02) % 24
    end
end)

task.spawn(function()
    while not shuttingDown do
        task.wait(45)

        for player in pairs(states) do
            if shuttingDown then
                break
            end

            if Data.Enabled then
                task.spawn(Data.Save, player, false)
            end
        end
    end
end)

game:BindToClose(function()
    shuttingDown = true

    for player in pairs(Data.Sessions) do
        task.spawn(Data.Close, player)
    end

    local deadline = os.clock() + 25

    while next(Data.Sessions) and os.clock() < deadline do
        task.wait(0.1)
    end
end)

print("[Valbrume] Serveur initialisé.")

Generation.Complete(world, "Core")

local Players = game:GetService("Players")

local function horizontalDistance(a, b)
    return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function currentWorld()
    return workspace:FindFirstChild("ValbrumeWorld")
end

local function expansionSpawn(world, zoneId)
    local expansion = world and world:FindFirstChild("ExpansionV25")
    local zones = expansion and expansion:FindFirstChild("Zones")
    return zones and zones:FindFirstChild(zoneId .. "_ExpansionSpawn")
end

local function nearestHomeSpawn(world, position)
    if not world then
        return nil
    end

    local best
    local bestDistance = math.huge

    for _, name in ipairs({"A2Spawn", "H2Spawn"}) do
        local spawn = world:FindFirstChild(name)
        if spawn and spawn:IsA("BasePart") then
            local distance = horizontalDistance(position, spawn.Position)
            if distance < bestDistance then
                bestDistance = distance
                best = spawn
            end
        end
    end

    return best, bestDistance
end

local function inKnownGameplayArea(player, root)
    local world = currentWorld()
    if not world or not root then
        return false
    end

    local expansionZone = player:GetAttribute("VBExpansionZone")
    if expansionZone then
        local spawn = expansionSpawn(world, expansionZone)
        if spawn then
            return horizontalDistance(root.Position, spawn.Position) <= 520
        end
    end

    local _, distance = nearestHomeSpawn(world, root.Position)
    return distance <= 520
end

local function safeSpawnFor(player, root)
    local world = currentWorld()
    if not world then
        return nil
    end

    local expansionZone = player:GetAttribute("VBExpansionZone")
    if expansionZone then
        local spawn = expansionSpawn(world, expansionZone)
        if spawn then
            return spawn
        end
    end

    local spawn = nearestHomeSpawn(world, root.Position)
    return spawn
end

local function inspectPlayer(player)
    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        return
    end

    -- Prévoit une future cinématique sans que le watchdog la casse.
    if player:GetAttribute("VBCinematicLock") then
        return
    end

    local gameplayArea = inKnownGameplayArea(player, root)

    -- Un HRP ancré dans A2/H2/Expansion est anormal dans Valbrume.
    -- On ne touche PAS au lobby de sélection situé en hauteur.
    if root.Anchored and gameplayArea then
        root.Anchored = false
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        warn(
            "[Valbrume Stability] HRP désancré automatiquement pour",
            player.Name
        )
    end

    -- Dernier filet de sécurité sous la carte.
    if root.Position.Y < -80 and gameplayArea then
        local spawn = safeSpawnFor(player, root)
        if spawn then
            root.Anchored = false
            character:PivotTo(spawn.CFrame + Vector3.new(0, 6, 0))
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            warn(
                "[Valbrume Stability] récupération sous-map pour",
                player.Name
            )
        end
    end
end

task.spawn(function()
    while true do
        task.wait(1)

        for _, player in ipairs(Players:GetPlayers()) do
            inspectPlayer(player)
        end
    end
end)

print("[Valbrume V2.5.1] CharacterStabilityService actif.")

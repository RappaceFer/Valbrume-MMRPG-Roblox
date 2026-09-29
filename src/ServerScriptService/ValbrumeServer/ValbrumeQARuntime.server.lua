local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local failures = {}
local warnings = {}

local function fail(message)
    table.insert(failures, message)
end

local function info(message)
    table.insert(warnings, message)
end

local function horizontalDistance(a, b)
    return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function waitForExpansion()
    local world = require(script.Parent.WorldGeneration).Await("Ready")
    return world, world.ExpansionV25
end
require(script.Parent.WorldGeneration).Await("Ready")

local server = ServerScriptService:FindFirstChild("ValbrumeServer")
if not server then
    fail("ValbrumeServer absent")
else
    if server:FindFirstChild("WeaponVisualService") then
        fail("WeaponVisualService expérimental encore actif")
    end

    for _, name in ipairs({
        "Main",
        "WorldBuilder",
        "ZoneExpansionService",
        "CharacterStabilityService",
    }) do
        if not server:FindFirstChild(name) then
            fail("Service absent : " .. name)
        end
    end

    if not server:FindFirstChild("ZoneGroundingService") then
        info("ZoneGroundingService absent")
    end
end

local world, expansion = waitForExpansion(10)

if not world then
    fail("ValbrumeWorld absent")
else
    for _, name in ipairs({"Decor", "NPCs", "Collectibles", "Spawns", "Enemies"}) do
        if not world:FindFirstChild(name) then
            fail("Dossier monde absent : " .. name)
        end
    end

    if not expansion then
        fail("ExpansionV25 absente après attente de stabilité")
    else
        local zones = expansion:FindFirstChild("Zones")
        if not zones then
            fail("ExpansionV25.Zones absent")
        else
            for _, zoneId in ipairs({"S3", "N4", "O5", "V6"}) do
                if not zones:FindFirstChild(zoneId .. "_ExpansionSpawn") then
                    fail("Spawn expansion absent : " .. zoneId)
                end
            end
        end
    end
end

local function nearGameplaySpawn(root)
    if not world or not root then
        return false
    end

    for _, name in ipairs({"A2Spawn", "H2Spawn"}) do
        local spawn = world:FindFirstChild(name)
        if spawn
            and horizontalDistance(root.Position, spawn.Position) <= 520 then
            return true
        end
    end

    if expansion then
        local zones = expansion:FindFirstChild("Zones")
        if zones then
            for _, zoneId in ipairs({"S3", "N4", "O5", "V6"}) do
                local spawn = zones:FindFirstChild(zoneId .. "_ExpansionSpawn")
                if spawn
                    and horizontalDistance(root.Position, spawn.Position) <= 520 then
                    return true
                end
            end
        end
    end

    return false
end

for _, player in ipairs(Players:GetPlayers()) do
    local character = player.Character

    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not root then
            fail(player.Name .. " : rig incomplet")
        else
            if root.Anchored then
                if nearGameplaySpawn(root) then
                    fail(
                        player.Name
                            .. " : HumanoidRootPart ancré en zone de gameplay"
                    )
                else
                    info(
                        player.Name
                            .. " : HRP ancré hors zone active (sélection/lobby probable), position="
                            .. tostring(root.Position)
                    )
                end
            end

            for _, descendant in ipairs(character:GetDescendants()) do
                if descendant:IsA("BasePart")
                    and descendant ~= root
                    and descendant.Anchored then
                    fail(
                        player.Name
                            .. " : pièce Character ancrée : "
                            .. descendant:GetFullName()
                    )
                    break
                end
            end
        end
    end
end

if #failures == 0 then
    print("[VALBRUME QA V2.5.1] PASS — aucune erreur critique détectée.")
else
    warn(
        "[VALBRUME QA V2.5.1] FAIL — "
            .. tostring(#failures)
            .. " erreur(s) critique(s)."
    )

    for _, message in ipairs(failures) do
        warn("[VALBRUME QA V2.5.1][CRITIQUE] " .. message)
    end
end

for _, message in ipairs(warnings) do
    warn("[VALBRUME QA V2.5.1][INFO] " .. message)
end

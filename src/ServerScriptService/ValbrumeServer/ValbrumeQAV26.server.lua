local ServerScriptService = game:GetService("ServerScriptService")

require(script.Parent.WorldGeneration).Await("Ready")

local failures = {}
local infos = {}

local function fail(message)
    table.insert(failures, message)
end

local function info(message)
    table.insert(infos, message)
end

local server = ServerScriptService:FindFirstChild("ValbrumeServer")
local world = workspace:FindFirstChild("ValbrumeWorld")

if not server then
    fail("ValbrumeServer absent")
else
    for _, name in ipairs({
        "SafeSpawnDirectorV26",
        "ExpansionWorldContentV26",
        "ExpansionStoryServiceV26",
        "CharacterStabilityService",
        "ZoneExpansionService",
    }) do
        if not server:FindFirstChild(name) then
            fail("Service absent : " .. name)
        end
    end

    if server:FindFirstChild("WeaponVisualService") then
        fail("WeaponVisualService expérimental encore actif")
    end

    if ServerScriptService:FindFirstChild("VBWeaponCalibrationLab") then
        fail("VBWeaponCalibrationLab ne doit pas tourner dans le jeu principal")
    end
end

if not world then
    fail("ValbrumeWorld absent")
else
    local expansion = world:FindFirstChild("ExpansionV25")
    local content = world:FindFirstChild("V26Content")
    local spawns = world:FindFirstChild("Spawns")

    if not expansion then
        fail("ExpansionV25 absente")
    end

    if not content then
        fail("V26Content absent")
    end

    if not spawns then
        fail("Spawns absent")
    else
        local safeHome = 0
        local expansionCount = 0

        for _, marker in ipairs(spawns:GetChildren()) do
            local zoneId = marker:GetAttribute("ZoneId")
            if (zoneId == "A2" or zoneId == "H2") and marker:GetAttribute("VBSafeSpawn") then
                safeHome += 1
            end

            if marker:GetAttribute("VBSafeSpawnFallback") then
                fail("Spawn de secours non validé : " .. marker.Name)
            end

            if marker:GetAttribute("VBExpansionMob") then
                expansionCount += 1
            end
        end

        if safeHome < 30 then
            fail("Moins de 30 marqueurs safe détectés : " .. tostring(safeHome))
        end

        if expansionCount < 36 then
            fail("Moins de 36 spawns expansion détectés : " .. tostring(expansionCount))
        end
    end
end

if #failures == 0 then
    print("[VALBRUME QA V2.6] PASS — expansion gameplay et safe spawns OK.")
else
    warn("[VALBRUME QA V2.6] FAIL — " .. tostring(#failures) .. " erreur(s).")
    for _, message in ipairs(failures) do
        warn("[VALBRUME QA V2.6][CRITIQUE] " .. message)
    end
end

for _, message in ipairs(infos) do
    warn("[VALBRUME QA V2.6][INFO] " .. message)
end

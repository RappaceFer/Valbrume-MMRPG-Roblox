local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace.Terrain

local C = require(ReplicatedStorage:WaitForChild("Valbrume"):WaitForChild("Config"))
local server = script.Parent
local SpawnRequest = server:WaitForChild("DungeonSpawnRequest")

local Generation = require(script.Parent.WorldGeneration)
local world = Generation.Await("Grounding")
local expansion = world.ExpansionV25
local spawns = world:WaitForChild("Spawns")
local enemies = world:WaitForChild("Enemies")
local zonesFolder = expansion:WaitForChild("Zones")

local HOME_SAFE = {
    A2 = {
        Vector3.new(-34,0,88),
        Vector3.new(-5,0,102),
        Vector3.new(30,0,92),

        Vector3.new(82,0,42),
        Vector3.new(108,0,56),
        Vector3.new(126,0,30),

        Vector3.new(-70,0,-22),
        Vector3.new(-92,0,-48),
        Vector3.new(-58,0,-72),

        Vector3.new(-120,0,-98),
        Vector3.new(-146,0,-76),
        Vector3.new(-103,0,-128),

        Vector3.new(154,0,-72),
        Vector3.new(190,0,-96),
        Vector3.new(228,0,-142),
    },

    H2 = {
        Vector3.new(-28,0,88),
        Vector3.new(3,0,100),
        Vector3.new(34,0,84),

        Vector3.new(78,0,44),
        Vector3.new(104,0,58),
        Vector3.new(126,0,30),

        Vector3.new(-70,0,-28),
        Vector3.new(-88,0,-54),
        Vector3.new(-54,0,-80),

        Vector3.new(-126,0,-82),
        Vector3.new(-102,0,-112),
        Vector3.new(-65,0,-136),

        Vector3.new(148,0,-74),
        Vector3.new(184,0,-102),
        Vector3.new(226,0,-142),
    },
}

local EXPANSION_SPAWNS = {
    S3 = {
        {"S3_Brumesang", Vector3.new(-70,0,75)},
        {"S3_Brumesang", Vector3.new(-38,0,96)},
        {"S3_Brumesang", Vector3.new(2,0,108)},
        {"S3_Brumesang", Vector3.new(42,0,90)},

        {"S3_RacineVive", Vector3.new(86,0,34)},
        {"S3_RacineVive", Vector3.new(112,0,6)},
        {"S3_RacineVive", Vector3.new(90,0,-38)},
        {"S3_RacineVive", Vector3.new(-90,0,-62)},

        {"S3_VeilleurSylvestre", Vector3.new(-118,0,-118)},
    },

    N4 = {
        {"N4_RodeurFalaise", Vector3.new(-78,0,72)},
        {"N4_RodeurFalaise", Vector3.new(-42,0,95)},
        {"N4_RodeurFalaise", Vector3.new(4,0,104)},
        {"N4_RodeurFalaise", Vector3.new(46,0,86)},

        {"N4_PilleurSel", Vector3.new(84,0,38)},
        {"N4_PilleurSel", Vector3.new(116,0,10)},
        {"N4_PilleurSel", Vector3.new(86,0,-46)},
        {"N4_PilleurSel", Vector3.new(-82,0,-58)},

        {"N4_GardienNacre", Vector3.new(-115,0,-120)},
    },

    O5 = {
        {"O5_MolosseRouille", Vector3.new(-72,0,76)},
        {"O5_MolosseRouille", Vector3.new(-34,0,100)},
        {"O5_MolosseRouille", Vector3.new(8,0,108)},
        {"O5_MolosseRouille", Vector3.new(50,0,86)},

        {"O5_ForgeEveillee", Vector3.new(84,0,42)},
        {"O5_ForgeEveillee", Vector3.new(112,0,8)},
        {"O5_ForgeEveillee", Vector3.new(86,0,-48)},
        {"O5_ForgeEveillee", Vector3.new(-86,0,-62)},

        {"O5_MaitreFourneau", Vector3.new(112,0,86)},
    },

    V6 = {
        {"V6_SpectreEcho", Vector3.new(-74,0,74)},
        {"V6_SpectreEcho", Vector3.new(-40,0,98)},
        {"V6_SpectreEcho", Vector3.new(4,0,106)},
        {"V6_SpectreEcho", Vector3.new(46,0,84)},

        {"V6_SentinelleCristal", Vector3.new(82,0,38)},
        {"V6_SentinelleCristal", Vector3.new(112,0,2)},
        {"V6_SentinelleCristal", Vector3.new(84,0,-48)},
        {"V6_SentinelleCristal", Vector3.new(-82,0,-62)},

        {"V6_NoyauResonant", Vector3.new(-104,0,96)},
    },
}

local function expansionSpawn(zoneId)
    return zonesFolder:FindFirstChild(zoneId .. "_ExpansionSpawn")
end

local function zoneOrigin(zoneId)
    if C.Zones[zoneId] then
        return C.Zones[zoneId].Origin
    end

    local spawn = expansionSpawn(zoneId)
    if spawn then
        return Vector3.new(spawn.Position.X, 0, spawn.Position.Z)
    end

    return nil
end

local function terrainHit(worldX, worldZ)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {Terrain}
    params.IgnoreWater = false

    return workspace:Raycast(
        Vector3.new(worldX, 340, worldZ),
        Vector3.new(0, -700, 0),
        params
    )
end

local candidateOffsets = {
    Vector2.new(0,0),
    Vector2.new(8,0), Vector2.new(-8,0),
    Vector2.new(0,8), Vector2.new(0,-8),
    Vector2.new(12,12), Vector2.new(-12,12),
    Vector2.new(12,-12), Vector2.new(-12,-12),
    Vector2.new(20,0), Vector2.new(-20,0),
    Vector2.new(0,20), Vector2.new(0,-20),
    Vector2.new(20,20), Vector2.new(-20,20),
    Vector2.new(20,-20), Vector2.new(-20,-20),
    Vector2.new(30,10), Vector2.new(-30,10),
    Vector2.new(30,-10), Vector2.new(-30,-10),
}

-- Search outward before considering an explicitly unsafe fallback.
for radius = 40, 160, 20 do
    for step = 0, 15 do
        local angle = step * math.pi / 8
        table.insert(candidateOffsets, Vector2.new(math.cos(angle), math.sin(angle)) * radius)
    end
end

local reserved = {}
local obstacles = OverlapParams.new()
obstacles.FilterType = Enum.RaycastFilterType.Include
obstacles.FilterDescendantsInstances = {world.Decor, world.V23Polish, world.V26Content, world.OpenWorldV28, expansion}
obstacles.RespectCanCollide = true
local function freeVolume(position, radius)
    return #workspace:GetPartBoundsInBox(CFrame.new(position + Vector3.new(0, 5, 0)),
        Vector3.new(radius * 2, 9, radius * 2), obstacles) == 0
end

local function usableGround(x, z)
    local hit = terrainHit(x, z)
    if not hit or hit.Material == Enum.Material.Water or hit.Material == Enum.Material.CrackedLava
        or hit.Normal.Y < math.cos(math.rad(28)) then return nil end
    return hit
end

local function placementClear(position, zoneId, radius)
    local playerSpawn = C.Zones[zoneId] and world:FindFirstChild(zoneId .. "Spawn") or expansionSpawn(zoneId)
    if playerSpawn and Vector2.new(position.X-playerSpawn.Position.X, position.Z-playerSpawn.Position.Z).Magnitude < 45 then
        return false
    end
    for _,other in reserved do
        if Vector2.new(position.X-other.position.X, position.Z-other.position.Z).Magnitude < radius + other.radius + 10 then
            return false
        end
    end
    -- Exclude lava footprints even where a crust lies above the damage plane.
    for _,hazard in world.OpenWorldV28.Hazards:GetChildren() do
        if hazard:IsA("BasePart") then
            local p = hazard.CFrame:PointToObjectSpace(position)
            if math.abs(p.X) < hazard.Size.X/2+radius+8 and math.abs(p.Z) < hazard.Size.Z/2+radius+8 then return false end
        end
    end
    if not freeVolume(position, radius) then return false end
    -- Footprint and two traversable exit directions, with bounded slope/step.
    for _,delta in {Vector2.new(radius,0),Vector2.new(-radius,0),Vector2.new(0,radius),Vector2.new(0,-radius)} do
        local hit = usableGround(position.X+delta.X, position.Z+delta.Y)
        if not hit or math.abs(hit.Position.Y-position.Y) > radius*.5 then return false end
    end
    local exits = 0
    for _,direction in {Vector2.xAxis,-Vector2.xAxis,Vector2.yAxis,-Vector2.yAxis} do
        local good, lastY = true, position.Y
        for distance = 6, 18, 6 do
            local hit = usableGround(position.X+direction.X*distance, position.Z+direction.Y*distance)
            if not hit or math.abs(hit.Position.Y-lastY)>3 or not freeVolume(hit.Position, 2.5) then good=false; break end
            lastY = hit.Position.Y
        end
        if good then exits += 1 end
    end
    return exits >= 2
end

local function safeSurface(zoneId, desired, allowHigher)
    local origin = zoneOrigin(zoneId)
    if not origin then
        return nil
    end

    local zoneGround = C.Zones[zoneId] and C.Zones[zoneId].GroundY
    local maxRise = allowHigher and 70 or 34
    local radius = allowHigher and 5 or 3.5
    local minNormalY = math.cos(math.rad(28))

    for _, offset in ipairs(candidateOffsets) do
        local x = origin.X + desired.X + offset.X
        local z = origin.Z + desired.Z + offset.Y
        local hit = terrainHit(x, z)

        if Vector2.new(x-origin.X,z-origin.Z).Magnitude <= 285 and hit
            and hit.Material ~= Enum.Material.Water
            and hit.Material ~= Enum.Material.CrackedLava
            and hit.Normal.Y >= minNormalY then

            if not zoneGround
                or (hit.Position.Y >= zoneGround - 12
                    and hit.Position.Y <= zoneGround + maxRise) then
                if placementClear(hit.Position, zoneId, radius) then
                    table.insert(reserved, {position=hit.Position, radius=radius})
                    return hit.Position + Vector3.new(0, 3.2, 0)
                end
            end
        end
    end

    return nil
end

local function fallbackPosition(zoneId)
    if C.Zones[zoneId] then
        local spawn = world:FindFirstChild(zoneId .. "Spawn")
        return spawn and spawn.Position + Vector3.new(18, 4, 18)
    end

    local spawn = expansionSpawn(zoneId)
    return spawn and spawn.Position + Vector3.new(24, 4, 24)
end

local movedHome = 0
local homeFallbacks = 0

for _, zoneId in ipairs({"A2", "H2"}) do
    for index, desired in ipairs(HOME_SAFE[zoneId]) do
        local marker = spawns:FindFirstChild(zoneId .. "_Spawn_" .. index)

        if marker and marker:IsA("BasePart") then
            local boss = index == #HOME_SAFE[zoneId]
            local safe = safeSurface(zoneId, desired, boss)

            if safe then
                marker.Position = safe
                marker:SetAttribute("VBSafeSpawn", true)
                marker:SetAttribute("VBSafeSpawnFallback", false)
                movedHome += 1
            else
                local fallback = fallbackPosition(zoneId)
                if fallback then
                    marker.Position = fallback + Vector3.new(index % 4 * 7, 0, math.floor(index / 4) * 7)
                    -- A fallback has not passed terrain/slope/water validation.
                    marker:SetAttribute("VBSafeSpawn", false)
                    marker:SetAttribute("VBSafeSpawnFallback", true)
                    homeFallbacks += 1
                end
            end
        end
    end
end

-- Recrée uniquement les marqueurs d'expansion V2.6.
for _, marker in ipairs(spawns:GetChildren()) do
    if marker:GetAttribute("VBExpansionMob") then
        marker:Destroy()
    end
end

local expansionMarkers = {}

for _, zoneId in ipairs({"S3", "N4", "O5", "V6"}) do
    for index, info in ipairs(EXPANSION_SPAWNS[zoneId]) do
        local mobId = info[1]
        local desired = info[2]
        local boss = index == #EXPANSION_SPAWNS[zoneId]
        local validatedPosition = safeSurface(zoneId, desired, true)
        local position = validatedPosition or fallbackPosition(zoneId)

        if position then
            local marker = Instance.new("Part")
            marker.Name = "V26_" .. zoneId .. "_Spawn_" .. index
            marker.Size = Vector3.one
            marker.Position = position
            marker.Anchored = true
            marker.Transparency = 1
            marker.CanCollide = false
            marker.CanTouch = false
            marker.CanQuery = false
            marker:SetAttribute("MobId", mobId)
            marker:SetAttribute("ZoneId", zoneId)
            marker:SetAttribute("VBExpansionMob", true)
            marker:SetAttribute("VBSafeSpawn", validatedPosition ~= nil)
            marker:SetAttribute("VBSafeSpawnFallback", validatedPosition == nil)
            marker.Parent = spawns
            table.insert(expansionMarkers, marker)
        end
    end
end

-- Main creates the population once, after final marker placement.
print(
    "[Valbrume V2.6] SafeSpawnDirector :",
    movedHome,
    "spawns A2/H2 validés,",
    homeFallbacks,
    "fallback(s),",
    #expansionMarkers,
    "spawns expansion."
)

Generation.Complete(world, "SafeSpawns")

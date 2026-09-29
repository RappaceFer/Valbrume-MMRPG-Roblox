-- Valbrume: test local ONE TILE. Reuse candidate 0.2.4. Play / SERVER only.
local Policy = (function()
-- Pure array policy for ONE Studio round-trip experiment, not a terrain generator.
-- Roblox documents LiquidOccupancy=0 when solid=1 and material~=Air.
-- Only that normalization is permitted. All material and solid data stay unchanged.
local P = {}
local names = {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"}
local epsilon = 1 / 255 + 0.00001
local function occupancy(v)
    return type(v) == "number" and v == v and v >= 0 and v <= 1
end
function P.copy(data, size)
    local out = {}
    for _, name in ipairs(names) do
        assert(type(data[name]) == "table", "Missing channel: " .. name)
        out[name] = {}
        for x = 1, size.X do
            out[name][x] = {}
            for y = 1, size.Y do
                out[name][x][y] = {}
                for z = 1, size.Z do
                    local value = data[name][x][y][z]
                    assert(value ~= nil, "Incomplete channel: " .. name)
                    if name ~= "SolidMaterial" then
                        assert(occupancy(value), "Invalid occupancy: " .. name)
                    end
                    out[name][x][y][z] = value
                end
            end
        end
    end
    return out -- Size and every other metadata key are intentionally excluded.
end
function P.canonical(data, size, air)
    local out, normalized = P.copy(data, size), 0
    for x = 1, size.X do for y = 1, size.Y do for z = 1, size.Z do
        if out.SolidMaterial[x][y][z] ~= air
            and out.SolidOccupancy[x][y][z] == 1
            and out.LiquidOccupancy[x][y][z] > 0 then
            out.LiquidOccupancy[x][y][z] = 0
            normalized = normalized + 1
        end
    end end end
    return out, normalized
end
function P.equal(a, b, size, tolerance)
    for _, name in ipairs(names) do
        for x = 1, size.X do for y = 1, size.Y do for z = 1, size.Z do
            local av, bv = a[name][x][y][z], b[name][x][y][z]
            local equal = av == bv
            if name ~= "SolidMaterial" then
                equal = occupancy(av) and occupancy(bv) and math.abs(av - bv) <= tolerance
            end
            if not equal then
                return false, string.format("%s cell=(%d,%d,%d) expected=%s actual=%s",
                    name, x, y, z, tostring(av), tostring(bv))
            end
        end end end
    end
    return true
end
-- Clear and restore precisely the same small region. No higher/lower surface is designed.
-- On failure, restore the canonical snapshot; never forward the raw Size metadata.
function P.roundTrip(adapter, before, size, air)
    local desired, count = P.canonical(before, size, air)
    local empty = P.copy(desired, size)
    for x = 1, size.X do for y = 1, size.Y do for z = 1, size.Z do
        empty.SolidMaterial[x][y][z] = air
        empty.SolidOccupancy[x][y][z] = 0
        empty.LiquidOccupancy[x][y][z] = 0
    end end end
    local unchanged, mismatch = P.equal(before, adapter.read(), size, 0)
    assert(unchanged, "Terrain changed before test; no write: " .. tostring(mismatch))
    local function verify()
        local last
        for attempt = 1, 3 do
            local same, detail = P.equal(desired, adapter.read(), size, epsilon)
            if same then return end
            last = detail
            if attempt < 3 then adapter.waitRestore() end
        end
        error("Channel readback mismatch: " .. tostring(last))
    end
    local ok, err = xpcall(function()
        adapter.write(empty)
        adapter.waitWrite()
        adapter.write(desired)
        adapter.waitWrite()
        verify()
    end, debug.traceback)
    if not ok then
        local restored, restoreError = pcall(function()
            adapter.restore(P.copy(desired, size))
            adapter.waitRestore()
            verify()
        end)
        error("Canary failed: " .. tostring(err) .. "; canonicalTileRestored="
            .. tostring(restored) .. "; " .. tostring(restoreError))
    end
    return {canonicalReadback = true, normalizedFullSolidLiquidCells = count,
        tolerance = epsilon, rawBitIdentityClaimed = false}
end
return P

end)()
-- TEST ONLY, in candidate 0.2.4, Play / Server, AFTER Ready.
-- Temporarily clears/restores ONE 28 x 640 x 28 stud region (7,840 cells).
-- No saved Source edits, no avatar movement, no DataStores, no production use.
-- Stop Play afterwards. Do not preserve runtime changes or publish this candidate.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning(),
    "Use the candidate in Studio Play / SERVER after Ready.")
local world = workspace:FindFirstChild("ValbrumeWorld")
local root = workspace:FindFirstChild("ValbrumeContinents")
assert(world and root and world:GetAttribute("GenerationReady") == true, "World not Ready")
assert(root:GetAttribute("CandidateVersion") == "continents-candidate-0.2.4", "Use candidate 0.2.4")
assert(not root:GetAttribute("TerrainCanaryBusy"), "Test already running")
local generation = world:GetAttribute("GenerationId")
local terrain = workspace.Terrain
local x, z = -1962.0330907564604, -1056.6750321948148 -- failing S3_P6 sample from the log
local min = Vector3.new(-1976, -256, -1072)
local max = Vector3.new(-1948, 384, -1044)
local size = {X = 7, Y = 160, Z = 7}
local region = Region3.new(min, max)
local names = {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"}
local started = os.clock()
local result = {version = "terrain-canary-1.0", generationId = generation,
    point = {x = x, z = z}, bounds = {min.X,min.Y,min.Z,max.X,max.Y,max.Z},
    writesAttempted = 0, scope = "ONE_TILE_NOT_SIX_LINKS", studioTest = true}
local function emit(kind, data)
    print("[VALBRUME TERRAIN CANARY] " .. HttpService:JSONEncode({type = kind, data = data}))
end
local function identity()
    assert(RunService:IsRunning() and workspace:FindFirstChild("ValbrumeWorld") == world
        and workspace:FindFirstChild("ValbrumeContinents") == root
        and world:GetAttribute("GenerationId") == generation, "World/session changed")
end
local function guard()
    identity()
    assert(os.clock() - started < 30, "Test budget exceeded")
end
local function params(brute, respect)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Include
    p.FilterDescendantsInstances = {terrain}
    p.IgnoreWater = false
    p.RespectCanCollide = respect or false
    p.CollisionGroup = "Default"
    if brute then
        local available = pcall(function() p.BruteForceAllSlow = true end)
        if not available then return nil end
    end
    return p
end
local function ray(p, top)
    if not p then return {available = false} end
    local hit = workspace:Raycast(Vector3.new(x, top, z), Vector3.new(0, -1400, 0), p)
    return {available = true, hit = hit ~= nil, terrain = hit and hit.Instance == terrain or false,
        y = hit and hit.Position.Y or nil, material = hit and hit.Material.Name or nil}
end
local function queries()
    return {normal = ray(params(false,false),384), high = ray(params(false,false),1024),
        collision = ray(params(false,true),384), brute = ray(params(true,false),384)}
end
local function read()
    identity()
    local data = terrain:ReadVoxelChannels(region,4,names)
    assert(data.Size.X == size.X and data.Size.Y == size.Y and data.Size.Z == size.Z, "Wrong array size")
    return data
end
local function write(data, restore)
    if restore then identity() else guard() end
    result.writesAttempted = result.writesAttempted + 1
    terrain:WriteVoxelChannels(region,4,{SolidMaterial=data.SolidMaterial,
        SolidOccupancy=data.SolidOccupancy,LiquidOccupancy=data.LiquidOccupancy})
end
local function waitFrame(restore)
    for _ = 1, 3 do RunService.PostSimulation:Wait() end
    if restore then identity() else guard() end
end
print("=== VALBRUME_TERRAIN_CANARY_BEGIN ===")
root:SetAttribute("TerrainCanaryBusy",true)
local ok, err = xpcall(function()
    guard()
    result.terrainFlags = {canCollide = terrain.CanCollide, canQuery = terrain.CanQuery,
        collisionGroup = terrain.CollisionGroup,
        defaultGroupCollides = PhysicsService:CollisionGroupsAreCollidable("Default",terrain.CollisionGroup)}
    result.before = queries()
    local before = read()
    local ix = math.floor((x - min.X) / 4) + 1
    local iz = math.floor((z - min.Z) / 4) + 1
    local solidCells, liquidCells, top = 0,0,nil
    for iy = 1, size.Y do
        if before.SolidMaterial[ix][iy][iz] ~= Enum.Material.Air and before.SolidOccupancy[ix][iy][iz] > 0 then
            solidCells = solidCells + 1
            top = min.Y + (iy - 1 + before.SolidOccupancy[ix][iy][iz]) * 4
        end
        if before.LiquidOccupancy[ix][iy][iz] > 0 then liquidCells = liquidCells + 1 end
    end
    result.exactColumn = {ix = ix, iz = iz, solidCells = solidCells, liquidCells = liquidCells,
        voxelTopEstimate = top, note = "Column sample, not reconstructed surface height"}
    emit("BEFORE",result)
    if result.before.normal.terrain then result.status = "ALREADY_QUERYABLE_NO_WRITE"; return end
    if solidCells == 0 then result.status = "EXACT_COLUMN_NO_SOLID_NO_WRITE"; return end
    if not terrain.CanQuery or not terrain.CanCollide or not result.terrainFlags.defaultGroupCollides then
        result.status = "FILTER_SETTINGS_REVIEW_NO_WRITE"; return
    end
    result.roundTrip = Policy.roundTrip({read = read,
        write = function(data) write(data,false) end,
        restore = function(data) write(data,true) end,
        waitWrite = function() waitFrame(false) end,
        waitRestore = function() waitFrame(true) end,
    },before,size,Enum.Material.Air)
    task.wait(1)
    guard()
    result.after = queries()
    result.status = result.after.normal.terrain and "ONE_TILE_RAY_RECOVERED" or "ONE_TILE_STILL_MISSING"
    result.walkabilityValidated = false
end,debug.traceback)
if not ok then result.status = "ERROR_STOP_PLAY"; result.error = tostring(err) end
if root.Parent then root:SetAttribute("TerrainCanaryBusy",nil) end
result.seconds = os.clock() - started
emit("RESULT",result)
print("=== VALBRUME_TERRAIN_CANARY_END ===")
if not ok then warn("Stop Play. Do not save runtime changes. " .. tostring(err)) end

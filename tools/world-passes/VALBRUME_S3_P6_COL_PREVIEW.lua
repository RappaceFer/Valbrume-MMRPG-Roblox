-- VALBRUME S3 <-> P6 : preview col forestier / montagneux
-- Studio PLAY / SERVER uniquement. Les modifications disparaissent quand Play s'arrête.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning(),
    "S3_P6 preview: lancer en Studio Play, contexte Server")

local world = workspace:FindFirstChild("ValbrumeWorld")
local continents = workspace:FindFirstChild("ValbrumeContinents")
assert(world and continents and world:GetAttribute("GenerationReady") == true,
    "S3_P6 preview: attendre Generation Ready")
assert(continents:GetAttribute("CandidateVersion") == "continents-candidate-0.2.5",
    "S3_P6 preview: utiliser VALBRUME_CONTINENTS_CANDIDATE_0_2_5")

local Terrain = workspace.Terrain
local path = {
    {-1700, 29, -760},
    {-1790, 30, -860},
    {-1880, 32, -965},
    {-1970, 35, -1070},
    {-2028, 36, -1140},
}
local STEP = 12
local LATERAL = {-48,-32,-16,0,16,32,48}
local FOUNDATION = -64
local CLEAR_TOP = 150

local function inProtectedP6(x,z)
    return x <= -2048 and x >= -3072 and z <= -1152 and z >= -2304
end

local function lerp(a,b,t) return a + (b-a)*t end
local writes, skipped = 0, 0

print("=== VALBRUME_S3_P6_COL_PREVIEW_BEGIN ===")

for seg = 1, #path-1 do
    local a,b = path[seg],path[seg+1]
    local dx,dz = b[1]-a[1], b[3]-a[3]
    local len = math.sqrt(dx*dx + dz*dz)
    local nx,nz = -dz/len, dx/len
    local n = math.max(1, math.ceil(len/STEP))

    for i = (seg==1 and 0 or 1), n do
        local t = i/n
        local cx = lerp(a[1],b[1],t)
        local cz = lerp(a[3],b[3],t)
        local cy = lerp(a[2],b[2],t)

        for _,off in ipairs(LATERAL) do
            local x,z = cx + nx*off, cz + nz*off
            if inProtectedP6(x,z) then
                skipped += 1
            else
                local y = cy - math.abs(off)*0.072
                local clearBottom = y + 7
                if CLEAR_TOP > clearBottom then
                    Terrain:FillBlock(
                        CFrame.new(x, (clearBottom+CLEAR_TOP)/2, z),
                        Vector3.new(18, CLEAR_TOP-clearBottom, 18),
                        Enum.Material.Air
                    )
                end
                Terrain:FillBlock(
                    CFrame.new(x, (FOUNDATION+y-2)/2, z),
                    Vector3.new(18, (y-2)-FOUNDATION, 18),
                    Enum.Material.Ground
                )
                Terrain:FillBlock(
                    CFrame.new(x, y-0.5, z),
                    Vector3.new(18, 3, 18),
                    Enum.Material.Grass
                )
                writes += 3
            end
        end

        if i % 3 == 0 then
            for _,side in ipairs({-1,1}) do
                local off = 67*side
                local x,z = cx + nx*off, cz + nz*off
                if not inProtectedP6(x,z) then
                    local shoulderY = cy - 5
                    Terrain:FillBall(Vector3.new(x, shoulderY-8, z), 14, Enum.Material.Rock)
                    writes += 1
                end
            end
        end

        if i % 8 == 0 then RunService.PostSimulation:Wait() end
    end
end

for _=1,4 do RunService.PostSimulation:Wait() end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = {Terrain}
rp.IgnoreWater = false

local samples, missing, water, steep, abrupt = 0,0,0,0,0
local previous
for seg = 1, #path-1 do
    local a,b = path[seg],path[seg+1]
    local dx,dz = b[1]-a[1], b[3]-a[3]
    local len = math.sqrt(dx*dx+dz*dz)
    local n = math.max(1, math.ceil(len/8))
    for i=(seg==1 and 0 or 1),n do
        local t=i/n
        local x,z=lerp(a[1],b[1],t),lerp(a[3],b[3],t)
        local hit=workspace:Raycast(Vector3.new(x,220,z),Vector3.new(0,-420,0),rp)
        samples += 1
        if not hit then
            missing += 1
            previous=nil
        else
            if hit.Material==Enum.Material.Water then water += 1 end
            local slope=math.deg(math.acos(math.clamp(hit.Normal.Y,-1,1)))
            if slope>30 then steep += 1 end
            if previous then
                local d=hit.Position-previous
                local horizontal=Vector2.new(d.X,d.Z).Magnitude
                if horizontal>.01 and math.deg(math.atan(math.abs(d.Y)/horizontal))>25 then
                    abrupt += 1
                end
            end
            previous=hit.Position
        end
    end
end

print(string.format(
    "[VALBRUME S3_P6 COL] samples=%d missing=%d water=%d steep=%d abrupt=%d terrainWrites=%d protectedSkipped=%d",
    samples,missing,water,steep,abrupt,writes,skipped
))
print("=== VALBRUME_S3_P6_COL_PREVIEW_END ===")

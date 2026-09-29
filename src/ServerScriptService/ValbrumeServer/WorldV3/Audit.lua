-- Read-only sampling of the authored corridors. Not a whole-map certificate.
-- Terrain and physical support are measured separately: a bridge is not a void.
local G = require(script.Parent.Geometry)
local A = {}
local function slope(n) return math.deg(math.acos(math.clamp(n.Y,-1,1))) end
local function emit(kind,data)
    print(game:GetService("HttpService"):JSONEncode({type=kind,data=data}))
end
function A.run(world,layout)
    local run = game:GetService("RunService")
    assert(run:IsStudio() and run:IsRunning() and run:IsServer(), "Scan: Play, contexte Server obligatoire")
    assert(world and world:GetAttribute("GenerationReady") == true, "Monde pas encore Ready")
    assert(world.OpenWorldV28:GetAttribute("GeographyRevision") == layout.Version, "Revision du monde incorrecte")
    local terrainParams = RaycastParams.new()
    terrainParams.FilterType = Enum.RaycastFilterType.Include
    terrainParams.FilterDescendantsInstances = {workspace.Terrain}
    terrainParams.IgnoreWater = false
    local supportParams = RaycastParams.new()
    supportParams.FilterType = Enum.RaycastFilterType.Include
    local include = {workspace.Terrain}
    for _, name in ipairs({"Decor","V23Polish","V26Content","ExpansionV25","OpenWorldV28"}) do
        local child = world:FindFirstChild(name)
        if child then include[#include+1] = child end
    end
    supportParams.FilterDescendantsInstances = include
    supportParams.IgnoreWater, supportParams.RespectCanCollide = true,true
    local summary = {version=layout.Version,routes=0,samples=0,flaggedSamples=0,
        terrainMissing=0,unsupported=0,water=0,lava=0,steep=0,grade=0,obstacles=0,surfaceMismatch=0}
    print("=== VALBRUME_WORLD_V3_AUDIT_BEGIN ===")
    emit("META",{version=layout.Version,generationId=world:GetAttribute("GenerationId"),
        context="Server",step=layout.Audit.Step,offsets=layout.Audit.Offsets,
        note="Echantillons, pas des trous uniques. Routes V3.1, pas les axes approximatifs V1."})
    local ok,err = xpcall(function()
        local started = os.clock()
        for _, route in ipairs(layout.Routes) do
            local result = {name=route.Id,samples=0,flaggedSamples=0,records=0,omitted=0,
                terrainMissing=0,unsupported=0,water=0,lava=0,steep=0,grade=0,obstacles=0,surfaceMismatch=0}
            for _, offset in ipairs(layout.Audit.Offsets) do
                local previous
                G.walkSamples(route,layout.Audit.Step,function(x,z,nx,nz,index)
                    assert(world == workspace:FindFirstChild("ValbrumeWorld"), "World replaced during audit")
                    assert(os.clock()-started < 60, "Audit deadline exceeded")
                    x,z = x+nx*offset,z+nz*offset
                    local origin = Vector3.new(x,layout.MaxY+32,z)
                    local ray = Vector3.new(0,layout.MinY-layout.MaxY-64,0)
                    local terrain = workspace:Raycast(origin,ray,terrainParams)
                    local support = workspace:Raycast(origin,ray,supportParams)
                    local flags = {}
                    local function flag(key)
                        if not flags[key] then flags[key]=true; result[key]=result[key]+1 end
                    end
                    if not terrain then flag("terrainMissing") end
                    if not support then flag("unsupported") end
                    if terrain then
                        if terrain.Material == Enum.Material.Water then flag("water") end
                        if terrain.Material == Enum.Material.CrackedLava then flag("lava") end
                        if slope(terrain.Normal) > layout.Audit.MaxSlope then flag("steep") end
                        local expected = G.field(layout.Routes,x,z)
                        if expected and math.abs(terrain.Position.Y-expected.Height) > layout.Audit.MaxSurfaceError then
                            flag("surfaceMismatch")
                        end
                    end
                    if support then
                        local point = support.Position
                        if terrain and point.Y-terrain.Position.Y > 6 then flag("obstacles") end
                        if previous then
                            local delta = point-previous
                            local horizontal = Vector2.new(delta.X,delta.Z).Magnitude
                            if horizontal > .01 and math.deg(math.atan(math.abs(delta.Y)/horizontal)) > layout.Audit.MaxGrade then
                                flag("grade")
                            end
                            -- Chest-height obstruction test complements the vertical floor query.
                            if delta.Magnitude > .01 and workspace:Raycast(previous+Vector3.new(0,3,0),delta,supportParams) then
                                flag("obstacles")
                            end
                        end
                        previous = point
                    else previous = nil end
                    result.samples = result.samples+1
                    if next(flags) then
                        result.flaggedSamples = result.flaggedSamples+1
                        if result.records < layout.Audit.MaxRecordsPerRoute then
                            result.records = result.records+1
                            emit("SAMPLE",{route=route.Id,index=index,offset=offset,x=x,z=z,
                                terrainY=terrain and terrain.Position.Y or nil,
                                supportY=support and support.Position.Y or nil,
                                support=support and support.Instance:GetFullName() or nil,flags=flags})
                        else result.omitted = result.omitted+1 end
                    end
                    if index % 100 == 0 then task.wait() end
                end)
            end
            summary.routes = summary.routes+1
            for key in pairs(summary) do
                if type(summary[key]) == "number" and result[key] then summary[key]=summary[key]+result[key] end
            end
            emit("ROUTE",result)
        end
        summary.status = summary.flaggedSamples == 0 and "SAMPLED_OK" or "FLAGGED"
    end,debug.traceback)
    if not ok then summary.status="ERROR"; summary.error=tostring(err) end
    emit("SUMMARY",summary)
    print("=== VALBRUME_WORLD_V3_AUDIT_END ===")
    return summary
end
return A

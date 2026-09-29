-- Read-only support gate, using the SAME six polylines plus two lateral bands.
-- Never interprets a support gate as full walkability/performance certification.
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local P=require(script.Parent.ContinentLinkPlan)
local A={}
local function emit(kind,data) print(HttpService:JSONEncode({type=kind,data=data})) end
function A.run(world)
    assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning(),"Studio Play / Server required")
    assert(world.Parent==workspace and workspace:FindFirstChild("ValbrumeWorld")==world
        and world:GetAttribute("GenerationReady")==true,"World not Ready")
    local root=workspace:FindFirstChild("ValbrumeContinents")
    assert(root and root:GetAttribute("LinkRepairVersion")==P.Version,"Six-link patch not applied")
    local generation=world:GetAttribute("GenerationId")
    local tp=RaycastParams.new();tp.FilterType=Enum.RaycastFilterType.Include
    tp.FilterDescendantsInstances={workspace.Terrain};tp.IgnoreWater=false
    local sp=RaycastParams.new();sp.FilterType=Enum.RaycastFilterType.Include
    sp.FilterDescendantsInstances={workspace.Terrain,root,world};sp.IgnoreWater=true;sp.RespectCanCollide=true
    local total={version=P.Version,routes=0,samples=0,terrainMissing=0,unsupported=0,
        water=0,steep=0,abruptGrade=0,manualTraversalPending=true}
    for _,link in ipairs(P.Links) do
        local stats={id=link.Id,samples=0,terrainMissing=0,unsupported=0,water=0,
            steep=0,abruptGrade=0,details=0,omitted=0}
        for _,offset in ipairs(P.CheckOffsets) do
            local previous
            for i=1,#link.Points-1 do
                local a,b=link.Points[i],link.Points[i+1]
                local dx,dz=b[1]-a[1],b[3]-a[3]
                local distance=math.sqrt(dx*dx+dz*dz)
                local count=math.max(1,math.ceil(distance/P.CheckStep))
                for n=(i==1 and 0 or 1),count do
                    assert(workspace:FindFirstChild("ValbrumeWorld")==world and world:GetAttribute("GenerationId")==generation,"World replaced during audit")
                    local x=a[1]+dx*n/count-dz/distance*offset
                    local z=a[3]+dz*n/count+dx/distance*offset
                    local origin,ray=Vector3.new(x,384,z),Vector3.new(0,-896,0)
                    local th,sh=workspace:Raycast(origin,ray,tp),workspace:Raycast(origin,ray,sp)
                    local flags={}
                    local function flag(name) flags[#flags+1]=name;stats[name]=stats[name]+1 end
                    if not th then flag("terrainMissing") end
                    if not sh then flag("unsupported") end
                    if th and th.Material==Enum.Material.Water then flag("water") end
                    if sh then
                        if sh.Normal.Y<math.cos(math.rad(35)) then flag("steep") end
                        if previous then
                            local d=sh.Position-previous
                            if Vector2.new(d.X,d.Z).Magnitude>.01 and math.abs(d.Y)>Vector2.new(d.X,d.Z).Magnitude*math.tan(math.rad(35)) then flag("abruptGrade") end
                        end
                        previous=sh.Position
                    else previous=nil end
                    stats.samples=stats.samples+1
                    if #flags>0 then
                        if stats.details<P.MaxDetails then
                            stats.details=stats.details+1
                            emit("LINK_SUPPORT_SAMPLE",{id=link.Id,offset=offset,x=x,z=z,flags=flags,
                                terrainY=th and th.Position.Y,supportY=sh and sh.Position.Y})
                        else stats.omitted=stats.omitted+1 end
                    end
                    if stats.samples%160==0 then task.wait() end
                end
            end
        end
        stats.supportGate=(stats.terrainMissing==0 and stats.unsupported==0) and "SUPPORT_SAMPLED_OK" or "REPAIR_REQUIRED"
        emit("LINK_SUPPORT",stats)
        total.routes=total.routes+1
        for _,key in ipairs({"samples","terrainMissing","unsupported","water","steep","abruptGrade"}) do total[key]=total[key]+stats[key] end
    end
    total.status=(total.terrainMissing==0 and total.unsupported==0) and "SUPPORT_SAMPLED_OK" or "REPAIR_REQUIRED"
    emit("LINK_SUPPORT_SUMMARY",total)
    return total
end
return A

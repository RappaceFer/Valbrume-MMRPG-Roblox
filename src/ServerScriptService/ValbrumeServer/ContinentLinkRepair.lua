-- Candidate 0.2.2: fill only confirmed missing Terrain support on the six audited links.
-- No ReadVoxelChannels/WriteVoxelChannels writes: native terrain that already raycasts is untouched.
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local P=require(script.Parent.ContinentLinkPlan)
local R={}
local active,finishedWorld,finishedGeneration,lastReport
local function lerp(a,b,t) return a+(b-a)*t end
function R.apply(world)
    assert(RunService:IsServer() and RunService:IsRunning(),"Six-link repair: running server only")
    local root=workspace:FindFirstChild("ValbrumeContinents")
    local terrain=workspace.Terrain
    local generation=world:GetAttribute("GenerationId")
    assert(type(generation)=="string" and root and root:FindFirstChild("ImportedRegions"),"Incomplete candidate")
    if finishedWorld==world and finishedGeneration==generation then return lastReport end
    assert(not active,"A six-link repair is already running")
    assert(world:GetAttribute("GenerationReady")~=true,"Repair must run before Ready")
    local started=os.clock()
    local function valid()
        return workspace:FindFirstChild("ValbrumeWorld")==world and world.Parent==workspace
            and workspace:FindFirstChild("ValbrumeContinents")==root
            and world:GetAttribute("GenerationId")==generation
    end
    local function guard()
        assert(valid(),"World changed; restart Play")
        assert(os.clock()-started<=P.MaxSeconds,"Six-link repair budget exceeded; restart Play")
    end
    local tp=RaycastParams.new()
    tp.FilterType=Enum.RaycastFilterType.Include
    tp.FilterDescendantsInstances={terrain}
    tp.IgnoreWater=false
    local report={version=P.Version,samples=0,existing=0,filled=0,postMissing=0,writes=0,seconds=0}
    active=true
    root:SetAttribute("LinkRepairStatus","BUILDING")
    local ok,err=xpcall(function()
        -- Same centre/lateral samples as ContinentLinkAudit. 16x16 patches overlap
        -- the adjacent 12-stud samples and the +/-16 lateral bands.
        for _,link in ipairs(P.Links) do
            for _,offset in ipairs(P.CheckOffsets) do
                for i=1,#link.Points-1 do
                    local a,b=link.Points[i],link.Points[i+1]
                    local dx,dz=b[1]-a[1],b[3]-a[3]
                    local distance=math.sqrt(dx*dx+dz*dz)
                    local count=math.max(1,math.ceil(distance/P.CheckStep))
                    for n=(i==1 and 0 or 1),count do
                        guard()
                        local t=n/count
                        local x=lerp(a[1],b[1],t)-dz/distance*offset
                        local z=lerp(a[3],b[3],t)+dx/distance*offset
                        local y=lerp(a[2],b[2],t)
                        local hit=workspace:Raycast(Vector3.new(x,384,z),Vector3.new(0,-896,0),tp)
                        report.samples=report.samples+1
                        if hit then
                            report.existing=report.existing+1
                        else
                            local bottom=P.FoundationY
                            assert(y>bottom+4 and y<P.MaxY,"Unsafe six-link fill height")
                            terrain:FillBlock(
                                CFrame.new(x,(bottom+y)/2,z),
                                Vector3.new(P.FillFootprint,y-bottom,P.FillFootprint),
                                Enum.Material[link.Material]
                            )
                            report.filled=report.filled+1
                            report.writes=report.writes+1
                        end
                        if report.samples%128==0 then RunService.PostSimulation:Wait() end
                    end
                end
            end
        end
        for _=1,3 do RunService.PostSimulation:Wait();guard() end
        for _,link in ipairs(P.Links) do
            for _,offset in ipairs(P.CheckOffsets) do
                for i=1,#link.Points-1 do
                    local a,b=link.Points[i],link.Points[i+1]
                    local dx,dz=b[1]-a[1],b[3]-a[3]
                    local distance=math.sqrt(dx*dx+dz*dz)
                    local count=math.max(1,math.ceil(distance/P.CheckStep))
                    for n=(i==1 and 0 or 1),count do
                        guard()
                        local t=n/count
                        local x=lerp(a[1],b[1],t)-dz/distance*offset
                        local z=lerp(a[3],b[3],t)+dx/distance*offset
                        if not workspace:Raycast(Vector3.new(x,384,z),Vector3.new(0,-896,0),tp) then
                            report.postMissing=report.postMissing+1
                        end
                    end
                end
            end
        end
        assert(report.postMissing==0,"Six-link support verification still has missing Terrain")
    end,debug.traceback)
    active=false
    report.seconds=os.clock()-started
    if not ok then
        root:SetAttribute("LinkRepairStatus","FAILED_PARTIAL")
        world:SetAttribute("GenerationError","Six links: "..tostring(err))
        error("Six-link repair interrupted. Stop Play; do not publish: "..tostring(err))
    end
    root:SetAttribute("LinkRepairVersion",P.Version)
    root:SetAttribute("LinkRepairStatus","APPLIED_AUDIT_PENDING")
    root:SetAttribute("LinkRepairColumnsFilled",report.filled)
    root:SetAttribute("LinkRepairSeconds",report.seconds)
    finishedWorld,finishedGeneration,lastReport=world,generation,report
    print("[VALBRUME SIX LINKS] "..HttpService:JSONEncode(report))
    return report
end
return R

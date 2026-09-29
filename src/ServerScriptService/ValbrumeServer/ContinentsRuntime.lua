-- Runtime adaptation for the offline-assembled candidate. Server only.
-- Does NOT rebuild imported maps, assign quests, enable saving, or trust client remotes.
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Atlas=require(game:GetService("ReplicatedStorage").Valbrume.ContinentAtlas)
local Terrain=workspace.Terrain
local R={}
local function valid(world)
    return workspace:FindFirstChild("ValbrumeWorld")==world and world.Parent==workspace
end
local function terrainParams()
    local p=RaycastParams.new()
    p.FilterType=Enum.RaycastFilterType.Include
    p.FilterDescendantsInstances={Terrain}
    p.IgnoreWater=false
    return p
end
function R.prepare(world)
    assert(RunService:IsServer(),"Continents: server only")
    assert(valid(world),"Obsolete generated world")
    local root=workspace:FindFirstChild("ValbrumeContinents")
    assert(root and root:FindFirstChild("ImportedRegions"),"Open the complete candidate RBXL, not a script-only installation")
    for id,info in pairs(Atlas.Imported) do
        local region=root.ImportedRegions:FindFirstChild(id)
        assert(region and region:IsA("Model"),"Missing imported map "..id)
        region:SetAttribute("RegionId",id)
        region:SetAttribute("Continent",Atlas.Regions[id].Continent)
        region:SetAttribute("OriginalSource",info.Source)
    end
    -- The legacy builders clear rectangular areas around their six cores on every Play.
    -- Repair only low/missing columns of those OUTER RIMS. Do not fill their central
    -- canyons, rivers or imported caves. Widths derive from their 650/720-stud clear boxes.
    local rims={
        {-900,0,296,328,26,Enum.Material.Grass}, {900,0,296,328,23,Enum.Material.Sand},
        {-1520,-560,304,364,27,Enum.Material.Grass}, {-1520,560,304,364,33,Enum.Material.Slate},
        {1520,-560,304,364,29,Enum.Material.Ground}, {1520,560,304,364,30,Enum.Material.Slate},
    }
    local params=terrainParams()
    local checked,written=0,0
    local started=os.clock()
    for _,r in ipairs(rims) do
        for x=r[1]-r[4]+4,r[1]+r[4]-4,8 do
            for z=r[2]-r[4]+4,r[2]+r[4]-4,8 do
                local distance=math.max(math.abs(x-r[1]),math.abs(z-r[2]))
                if distance>=r[3] then
                    assert(valid(world),"World changed during rim repair")
                    assert(os.clock()-started<45,"Rim repair timeout; restart Play, do not publish")
                    local h=workspace:Raycast(Vector3.new(x,384,z),Vector3.new(0,-768,0),params)
                    checked=checked+1
                    if not h or (h.Material~=Enum.Material.Water and h.Position.Y<r[5]-24) then
                        Terrain:FillBlock(CFrame.new(x,(r[5]-96)/2,z),Vector3.new(8,r[5]+96,8),r[6])
                        written=written+1
                    end
                    if checked%512==0 then RunService.PostSimulation:Wait() end
                end
            end
        end
    end
    RunService.PostSimulation:Wait()
    -- Six-link native repair runs after legacy terrain writes, before Biome/Ready.
    require(script.Parent.ContinentLinkRepair).apply(world)
    root:SetAttribute("CandidateVersion","continents-candidate-0.2")
    root:SetAttribute("RimColumnsPatched",written)
    print("[VALBRUME CONTINENTS] "..HttpService:JSONEncode({version=Atlas.Version,checked=checked,patched=written,seconds=os.clock()-started}))
end
local function emit(kind,data)
    print(HttpService:JSONEncode({type=kind,data=data}))
end
function R.audit(world)
    assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning(),"Audit: Studio Play / Server")
    assert(valid(world) and world:GetAttribute("GenerationReady")==true,"World not Ready")
    local root=workspace:FindFirstChild("ValbrumeContinents")
    local summary={version="continents-candidate-0.2",regions=0,parts=0,foreignSources=0,unanchored=0,samples=0,flagged=0,terrainMissing=0,unsupported=0}
    print("=== VALBRUME_CONTINENTS_AUDIT_BEGIN ===")
    local ok,err=xpcall(function()
        assert(root and root:FindFirstChild("ImportedRegions"),"ImportedRegions missing")
        emit("META",{version=summary.version,atlasVersion=Atlas.Version,generationId=world:GetAttribute("GenerationId"),context="Server",note="Prospecting samples; not a walkability, asset-loading or performance certificate"})
        for id,info in pairs(Atlas.Imported) do
            local model=root.ImportedRegions:FindFirstChild(id)
            assert(model,"Missing region "..id)
            local stats={id=id,parts=0,foreignSources=0,unanchored=0,expectedParts=info.Parts}
            for _,o in ipairs(model:GetDescendants()) do
                if o:IsA("BasePart") then
                    stats.parts=stats.parts+1
                    if not o.Anchored then stats.unanchored=stats.unanchored+1 end
                end
                if o:IsA("LuaSourceContainer") then stats.foreignSources=stats.foreignSources+1 end
            end
            summary.regions=summary.regions+1
            summary.parts=summary.parts+stats.parts
            summary.foreignSources=summary.foreignSources+stats.foreignSources
            summary.unanchored=summary.unanchored+stats.unanchored
            emit("IMPORTED_REGION",stats)
        end
        local tp=terrainParams()
        local support=RaycastParams.new()
        support.FilterType=Enum.RaycastFilterType.Include
        support.FilterDescendantsInstances={Terrain,root,world}
        support.RespectCanCollide=true
        support.IgnoreWater=true
        local started=os.clock()
        for _,route in ipairs(Atlas.Probes) do
            local stats={id=route.Id,samples=0,flagged=0,terrainMissing=0,unsupported=0,water=0,lava=0,steep=0,abruptGrade=0,elevatedSupport=0,obstructed=0,records=0,omitted=0}
            local previous
            for i=1,#route.Points-1 do
                local a,b=route.Points[i],route.Points[i+1]
                local dx,dz=b[1]-a[1],b[2]-a[2]
                local n=math.max(1,math.ceil(math.sqrt(dx*dx+dz*dz)/12))
                for j=(i==1 and 0 or 1),n do
                    assert(valid(world) and os.clock()-started<60,"Audit interrupted")
                    local x,z=a[1]+dx*j/n,a[2]+dz*j/n
                    local origin=Vector3.new(x,384,z)
                    local ray=Vector3.new(0,-896,0)
                    local th=workspace:Raycast(origin,ray,tp)
                    local sh=workspace:Raycast(origin,ray,support)
                    local flags={}
                    local function flag(k) flags[#flags+1]=k; stats[k]=stats[k]+1 end
                    if not th then flag("terrainMissing") end
                    if not sh then flag("unsupported") end
                    if th then
                        if th.Material==Enum.Material.Water then flag("water") end
                        if th.Material==Enum.Material.CrackedLava then flag("lava") end
                    end
                    if sh then
                        local slope=math.deg(math.acos(math.clamp(sh.Normal.Y,-1,1)))
                        if slope>35 then flag("steep") end
                        if th and sh.Position.Y-th.Position.Y>8 then flag("elevatedSupport") end
                        if previous then
                            local d=sh.Position-previous
                            local horizontal=Vector2.new(d.X,d.Z).Magnitude
                            if horizontal>.01 and math.deg(math.atan(math.abs(d.Y)/horizontal))>35 then flag("abruptGrade") end
                            if d.Magnitude>.01 and workspace:Raycast(previous+Vector3.new(0,3,0),d,support) then flag("obstructed") end
                        end
                        previous=sh.Position
                    else previous=nil end
                    stats.samples=stats.samples+1
                    if #flags>0 or not sh then
                        stats.flagged=stats.flagged+1
                        if stats.records<20 then
                            stats.records=stats.records+1
                            emit("SAMPLE",{route=route.Id,x=x,z=z,terrainY=th and th.Position.Y,supportY=sh and sh.Position.Y,unsupported=not sh,flags=flags})
                        else stats.omitted=stats.omitted+1 end
                    end
                    if stats.samples%100==0 then task.wait() end
                end
            end
            summary.samples=summary.samples+stats.samples
            summary.flagged=summary.flagged+stats.flagged
            summary.terrainMissing=summary.terrainMissing+stats.terrainMissing
            summary.unsupported=summary.unsupported+stats.unsupported
            emit("PROSPECTING_LINE",stats)
        end
        summary.sixLinks=require(script.Parent.ContinentLinkAudit).run(world)
        summary.patchVersion=summary.sixLinks.version
        -- The unambiguous central water band excludes the intentional far-coast details.
        local waterOK,waterTotal=0,0
        for z=-2400,2800,80 do
            local h=workspace:Raycast(Vector3.new(0,250,z),Vector3.new(0,-500,0),tp)
            waterTotal=waterTotal+1
            if h and h.Material==Enum.Material.Water then waterOK=waterOK+1 end
        end
        summary.centralSeaSamples=waterTotal
        summary.centralSeaWater=waterOK
        summary.status=(summary.flagged==0 and summary.sixLinks.status=="SUPPORT_SAMPLED_OK" and summary.foreignSources==0 and summary.unanchored==0 and waterOK==waterTotal) and "SAMPLED_OK" or "REVIEW_REQUIRED"
        summary.manualTraversalPending=true
        summary.mobileProfilePending=true
    end,debug.traceback)
    if not ok then summary.status="ERROR";summary.error=tostring(err) end
    emit("SUMMARY",summary)
    print("=== VALBRUME_CONTINENTS_AUDIT_END ===")
    return summary
end
return R

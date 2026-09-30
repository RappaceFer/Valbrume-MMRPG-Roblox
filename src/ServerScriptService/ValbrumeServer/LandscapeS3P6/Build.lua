-- Native Studio worksite, BEFORE Biome/Ready. Stops before any mutation if preflight fails.
-- The 0.2.5 support repair is NOT replaced. No gameplay, coast or imported-core edit.
local RS=game:GetService("RunService")
local HS=game:GetService("HttpService")
local P=require(script.Parent.Plan)
local F=require(script.Parent.Field)
local V=require(script.Parent.Voxels)
local A=require(script.Parent.Audit)
local V3=require(script.Parent.Parent.WorldV3.Layout)
local B={}
local busy,lastWorld,lastGeneration,lastReport,lastPath
local function emit(kind,data)
    print("[VALBRUME S3 P6] "..HS:JSONEncode({type=kind,data=data}))
end
local function bounds(part)
    local cf,h=part.CFrame,part.Size*.5
    local right,up,look=cf.RightVector,cf.UpVector,cf.LookVector
    local ex=math.abs(right.X)*h.X+math.abs(up.X)*h.Y+math.abs(look.X)*h.Z
    local ez=math.abs(right.Z)*h.X+math.abs(up.Z)*h.Y+math.abs(look.Z)*h.Z
    return {cf.X-ex,cf.Z-ez,cf.X+ex,cf.Z+ez}
end
function B.run(world)
    assert(RS:IsStudio() and RS:IsRunning() and RS:IsServer(),"Landscape worksite: Studio Play / Server only; do not publish")
    local root=workspace:FindFirstChild("ValbrumeContinents")
    assert(root and root:GetAttribute("CandidateVersion")==P.BaseCandidate,"Use complete candidate 0.2.5 base")
    local generation=world:GetAttribute("GenerationId")
    assert(type(generation)=="string" and world:GetAttribute("GenerationReady")~=true,"Wrong generation phase")
    if world==lastWorld and generation==lastGeneration then return lastReport end
    assert(not busy,"Landscape already building")
    local started=os.clock()
    local function identity()
        assert(RS:IsRunning() and workspace:FindFirstChild("ValbrumeWorld")==world and world.Parent==workspace
            and workspace:FindFirstChild("ValbrumeContinents")==root
            and world:GetAttribute("GenerationId")==generation,"Landscape world/session changed")
    end
    local function guard() identity();assert(os.clock()-started<P.MaxSeconds,"Landscape budget exceeded") end
    local terrain=workspace.Terrain
    local path=F.path(P)
    local tiles=F.tiles(P,path)
    local size={X=P.TileSize/4,Y=(P.MaxY-P.MinY)/4,Z=P.TileSize/4}
    local report={version=P.Version,scope="S3_P6_APPROACH_ONLY",generationId=generation,
        plannedTiles=#tiles,changedTiles=0,columns=0,voxels=0,writes=0,
        normalizedFullSolidLiquidCells=0,waterSkipped=0,emptySkipped=0,ceilingSkipped=0,
        thinRoofSkipped=0,limitedCutFill=0,maxCut=0,maxFill=0,protectedObjects=0,
        before={},after={},supportRegressions=0,visualApproval=false,manualTraversal=false}
    local plans,written,objects={},{},{}
    busy=true
    root:SetAttribute("LandscapeStatus","PREFLIGHT")
    local ok,err=xpcall(function()
        local tp=RaycastParams.new();tp.FilterType=Enum.RaycastFilterType.Include
        tp.FilterDescendantsInstances={terrain};tp.IgnoreWater=false
        local function anchor(pt)
            local hit=workspace:Raycast(Vector3.new(pt.x,384,pt.z),Vector3.new(0,-896,0),tp)
            assert(hit and hit.Material~=Enum.Material.Water,"Endpoint has no dry Terrain; no sculpture")
            assert(hit.Position.Y>P.MinY+16 and hit.Position.Y<P.MaxY-16,"Endpoint outside vertical limits")
            return hit.Position.Y
        end
        local h0,h1=anchor(path.points[1]),anchor(path.points[#path.points])
        report.endpoints={start={x=path.points[1].x,z=path.points[1].z,y=h0},
            finish={x=path.points[#path.points].x,z=path.points[#path.points].z,y=h1}}
        -- Conservatively protect static object footprints even when CanQuery=false.
        -- Buildings, quest markers, NPCs and existing trees are never moved/deleted.
        local boxes={}
        for _,o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") and o~=terrain and o.Anchored and (o.CanCollide or o.Transparency<1
                or o:IsA("SpawnLocation") or o:GetAttribute("MobId")~=nil) then
                local r=bounds(o)
                if r[1]<-1510 and r[3]>-2230 and r[2]<-580 and r[4]>-1340 then
                    boxes[#boxes+1]=r
                    objects[#objects+1]={object=o,parent=o.Parent,cf=o.CFrame,size=o.Size}
                end
            end
        end
        assert(#boxes<=P.MaxObjects,"Too many nearby objects; inspect before sculpting")
        report.protectedObjects=#boxes
        local beforeAudit=A.run(world,path,guard)
        report.before=A.public(beforeAudit)
        for ti,tile in ipairs(tiles) do
            guard()
            local region=Region3.new(Vector3.new(tile.x,P.MinY,tile.z),Vector3.new(tile.x+32,P.MaxY,tile.z+32))
            local read=terrain:ReadVoxelChannels(region,4,V.Names)
            assert(read.Size.X==size.X and read.Size.Y==size.Y and read.Size.Z==size.Z,"Invalid native tile shape")
            local original,normalized=V.canonical(read,size,Enum.Material.Air)
            local after=V.copy(original,size)
            local edits={}
            for ix=1,size.X do for iz=1,size.Z do
                local x,z=tile.x+(ix-.5)*4,tile.z+(iz-.5)*4
                local w,n=F.weight(P,path,x,z,boxes,V3)
                if w>.0001 then
                    local surface,why=V.surface(original,ix,iz,P,Enum.Material.Air)
                    if not surface then
                        local k=why.."Skipped";report[k]=report[k]+1
                    else
                        local height,profile=F.height(P,path,surface.height,w,n,h0,h1)
                        local delta=height-surface.height
                        if (profile-surface.height < -P.MaxCut or profile-surface.height > P.MaxFill) then report.limitedCutFill=report.limitedCutFill+1 end
                        local material=surface.material
                        if w>.5 then material=Enum.Material.Grass end
                        local tread=7+1.5*math.sin(n.s/73)
                        if w>.85 and n.d<tread then material=Enum.Material.Ground end
                        -- Canonical input is retained if the volume does not actually change.
                        if math.abs(delta)>.04 or (w>.85 and material~=surface.material) then
                            local count,first=V.sculpt(after,ix,iz,surface,height,material,P,Enum.Material.Air,Enum.Material.Ground)
                            if not count then report.thinRoofSkipped=report.thinRoofSkipped+1
                            elseif count>0 then
                                edits[#edits+1]={x=ix,z=iz,first=first}
                                report.columns=report.columns+1;report.voxels=report.voxels+count
                                report.maxCut=math.max(report.maxCut,-delta);report.maxFill=math.max(report.maxFill,delta)
                            end
                        end
                    end
                end
            end end
            if #edits>0 then
                report.normalizedFullSolidLiquidCells=report.normalizedFullSolidLiquidCells+normalized
                plans[#plans+1]={region=region,before=original,after=after,edits=edits,x=tile.x,z=tile.z}
            end
            assert(report.columns<=P.MaxColumns,"Column budget exceeded before writes")
            if ti%12==0 then task.wait() end
        end
        assert(report.columns>0,"No unprotected soil to reshape; no write performed")
        emit("PLAN",{version=P.Version,endpoints=report.endpoints,tiles=#plans,columns=report.columns,
            protectedObjects=report.protectedObjects,waterSkipped=report.waterSkipped,emptySkipped=report.emptySkipped})
        root:SetAttribute("LandscapeStatus","BUILDING")
        local function write(region,data)
            guard()
            terrain:WriteVoxelChannels(region,4,{SolidMaterial=data.SolidMaterial,
                SolidOccupancy=data.SolidOccupancy,LiquidOccupancy=data.LiquidOccupancy})
            report.writes=report.writes+1
        end
        for ti,p in ipairs(plans) do
            guard()
            local current=V.canonical(terrain:ReadVoxelChannels(p.region,4,V.Names),size,Enum.Material.Air)
            local same,diff=V.equal(p.before,current,size)
            assert(same,"Concurrent Terrain edit before write: "..tostring(diff))
            local cleared=V.copy(p.before,size)
            V.clearEdits(cleared,p.edits,size.Y,Enum.Material.Air)
            written[#written+1]=p -- includes partial API writes in rollback scope
            write(p.region,cleared);RS.PostSimulation:Wait();guard()
            write(p.region,p.after);RS.PostSimulation:Wait();guard()
            same,diff=V.equal(p.after,terrain:ReadVoxelChannels(p.region,4,V.Names),size)
            assert(same,"Landscape readback mismatch "..p.x..","..p.z.." "..tostring(diff))
            report.changedTiles=report.changedTiles+1
            if ti%20==0 then emit("PROGRESS",{done=ti,total=#plans}) end
        end
        for _=1,3 do RS.PostSimulation:Wait();guard() end
        local afterAudit=A.run(world,path,guard)
        report.after=A.public(afterAudit)
        report.supportRegressions=A.supportRegressions(beforeAudit,afterAudit)
        assert(report.supportRegressions==0,"New missing support after landscape; restoring worksite")
        for _,entry in ipairs(objects) do
            assert(entry.object.Parent==entry.parent and entry.object.CFrame==entry.cf and entry.object.Size==entry.size,
                "Nearby static object changed during worksite")
        end
        report.status=afterAudit.status
    end,debug.traceback)
    if not ok then
        report.status="FAILED_NO_WRITE"
        report.error=tostring(err)
        if #written>0 then
            local restored,why=pcall(function()
                -- Restoration does not reuse the expired build budget. Identity is always checked BEFORE writing.
                for i=#written,1,-1 do
                    identity();local p=written[i]
                    terrain:WriteVoxelChannels(p.region,4,{SolidMaterial=p.before.SolidMaterial,
                        SolidOccupancy=p.before.SolidOccupancy,LiquidOccupancy=p.before.LiquidOccupancy})
                    RS.PostSimulation:Wait();identity()
                    local equal,diff=V.equal(p.before,terrain:ReadVoxelChannels(p.region,4,V.Names),size)
                    assert(equal,"Restoration readback "..tostring(diff))
                end
            end)
            report.canonicalWorksiteRestored=restored
            report.restorationError=not restored and tostring(why) or nil
            report.status=restored and "FAILED_RESTORED" or "FAILED_PARTIAL_STOP_PLAY"
        end
        busy=false
        root:SetAttribute("LandscapeStatus",report.status)
        world:SetAttribute("GenerationError","LandscapeS3P6: "..tostring(err))
        emit("ERROR",report)
        error("Landscape interrupted. Stop Play; do not publish: "..tostring(err))
    end
    report.seconds=os.clock()-started
    root:SetAttribute("LandscapeRevision",P.Version)
    root:SetAttribute("LandscapeStatus","APPLIED_REVIEW_REQUIRED")
    -- Invisible editor focus target: select this Model and press F to inspect the worksite.
    local marker=Instance.new("Model");marker.Name="S3_P6_Worksite"
    local box=Instance.new("Part");box.Name="CameraFocus";box.Anchored=true
    box.CanCollide=false;box.CanTouch=false;box.CanQuery=false;box.Transparency=1
    box.Size=Vector3.new(580,100,630);box.CFrame=CFrame.new(-1870,45,-955)
    box.Parent=marker;marker.PrimaryPart=box;marker.Parent=root
    busy=false;lastWorld=world;lastGeneration=generation;lastReport=report;lastPath=path
    emit("BUILD",report)
    return report
end
function B.audit(world)
    assert(world==lastWorld and world:GetAttribute("GenerationId")==lastGeneration,"Wrong worksite generation")
    print("=== VALBRUME_S3_P6_LANDSCAPE_AUDIT_BEGIN ===")
    local ok,err=xpcall(function()
        local started=os.clock()
        local result=A.run(world,lastPath,function()
            assert(workspace:FindFirstChild("ValbrumeWorld")==world and world:GetAttribute("GenerationReady")==true
                and os.clock()-started<30,"Post-ready landscape audit interrupted")
        end)
        emit("POST_READY",A.public(result))
    end,debug.traceback)
    if not ok then emit("AUDIT_ERROR",{error=tostring(err),status="ERROR"}) end
    print("=== VALBRUME_S3_P6_LANDSCAPE_AUDIT_END ===")
end
return B

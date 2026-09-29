-- Studio-only snapshot. Clones decor and native Terrain; never edits the source map.
local C = {}
local removed = {Script=true,LocalScript=true,ModuleScript=true,RemoteEvent=true,RemoteFunction=true,
 UnreliableRemoteEvent=true,BindableEvent=true,BindableFunction=true,Tool=true,Humanoid=true,
 Animator=true,AnimationController=true,SpawnLocation=true,ProximityPrompt=true,ClickDetector=true,
 TouchTransmitter=true,Sound=true,SurfaceGui=true,BillboardGui=true,ScreenGui=true}
local function reject(o)
    return removed[o.ClassName] or o:IsA("JointInstance") or o:IsA("Constraint") or o:IsA("BodyMover")
end
local function sanitize(root,bounds)
    local dropped,parts=0,0
    for _,o in ipairs(root:GetDescendants()) do
        if o.Parent then
            local outside=false
            if bounds and o:IsA("BasePart") then
                local p=o.Position
                outside=p.X<bounds[1] or p.X>=bounds[4] or p.Z<bounds[3] or p.Z>=bounds[6]
            end
            if reject(o) or outside then dropped=dropped+1; o:Destroy()
            elseif o:IsA("BasePart") then
                parts=parts+1; o.Anchored=true
                o.AssemblyLinearVelocity=Vector3.zero; o.AssemblyAngularVelocity=Vector3.zero
                if o:IsA("Seat") or o:IsA("VehicleSeat") then o.Disabled=true end
            elseif o:IsA("Model") then
                o.ModelStreamingMode=Enum.ModelStreamingMode.Default
            end
        end
    end
    for _,o in ipairs(root:GetDescendants()) do
        assert(not reject(o),"Unexpected active object: "..o:GetFullName())
    end
    assert(parts>0,"No geometry captured")
    return dropped,parts
end
function C.capture(id,sourceRoot,bounds,anchor,filterParts)
    local run=game:GetService("RunService")
    assert(run:IsStudio(),"Studio only")
    if run:IsRunning() then assert(run:IsServer(),"Capture in Play / Server, not Client") end
    local result=Instance.new("Model"); result.Name=id
    local ok,err=xpcall(function()
        local decor=Instance.new("Model"); decor.Name="Decor"; decor.Parent=result
        for _,o in ipairs(sourceRoot:GetChildren()) do
            if not o:IsA("Terrain") and not o:IsA("Camera") and not o:IsA("SpawnLocation") and not reject(o) then
                assert(o.Archivable,"Not archivable: "..o:GetFullName())
                local copy=o:Clone(); assert(copy,"Clone failed: "..o.Name); copy.Parent=decor
            end
        end
        local dropped,parts=sanitize(decor,filterParts and bounds or nil)
        -- CopyRegion uses inclusive cell bounds; retain returned SizeInCells as ground truth.
        local min=Vector3int16.new(math.floor(bounds[1]/4),math.floor(bounds[2]/4),math.floor(bounds[3]/4))
        local max=Vector3int16.new(math.ceil(bounds[4]/4)-1,math.ceil(bounds[5]/4)-1,math.ceil(bounds[6]/4)-1)
        local region=workspace.Terrain:CopyRegion(Region3int16.new(min,max))
        region.Name="NativeTerrain"; region.Parent=result
        result:SetAttribute("Format","ValbrumeNativeMap/1")
        result:SetAttribute("SourceId",id)
        result:SetAttribute("SourceAnchor",Vector3.new(anchor[1],anchor[2],anchor[3]))
        result:SetAttribute("MinCell",Vector3.new(min.X,min.Y,min.Z))
        result:SetAttribute("SizeCells",region.SizeInCells)
        result:SetAttribute("Parts",parts)
        result:SetAttribute("RemovedObjects",dropped)
        result:SetAttribute("CapturedAt",os.time())
        result:SetAttribute("SourceScale",1)
        print("[VALBRUME CAPTURE] "..id.." : "..parts.." parts; terrain "..tostring(region.SizeInCells))
    end,debug.traceback)
    if not ok then result:Destroy(); error(err) end
    return result
end
return C

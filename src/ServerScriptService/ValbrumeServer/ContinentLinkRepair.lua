-- Candidate 0.2: native repair restricted to six surveyed links, during Play only.
-- Existing voxel shapes (including native caves/water) are preserved. We refresh
-- their local collision representation where raycasts and voxel data disagree.
-- Genuinely empty columns are filled only outside source maps and protected V3.
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local P=require(script.Parent.ContinentLinkPlan)
local G=require(script.Parent.ContinentLinkGeometry)
local V=require(script.Parent.ContinentLinkVoxels)
local Atlas=require(game:GetService("ReplicatedStorage").Valbrume.ContinentAtlas)
local V3=require(script.Parent.WorldV3.Layout)
local R={}
local active,finishedWorld,finishedGeneration,lastReport
local channels={"SolidMaterial","SolidOccupancy","LiquidOccupancy"}
function R.apply(world)
    assert(RunService:IsServer() and RunService:IsRunning(),"Six-link repair: running server only")
    local root=workspace:FindFirstChild("ValbrumeContinents")
    local terrain=workspace.Terrain
    local generation=world:GetAttribute("GenerationId")
    assert(type(generation)=="string" and root and root:FindFirstChild("ImportedRegions"),"Incomplete candidate")
    if finishedWorld==world and finishedGeneration==generation then return lastReport end
    assert(not active,"A six-link repair is already running")
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
    assert(valid() and world:GetAttribute("GenerationReady")~=true,"Repair must run before Ready")
    local tiles=G.tiles(P,V3,Atlas) -- validates identities, bounds and budget BEFORE any write
    local report={version=P.Version,tiles=#tiles,checked=0,filled=0,refreshed=0,
        writes=0,protectedEmpty=0,partSupportedEmpty=0,outOfSlab=0,nativeRayMismatch=0}
    local tp=RaycastParams.new()
    tp.FilterType=Enum.RaycastFilterType.Include
    tp.FilterDescendantsInstances={terrain};tp.IgnoreWater=false
    local sp=RaycastParams.new()
    sp.FilterType=Enum.RaycastFilterType.Include
    sp.FilterDescendantsInstances={world,root,terrain};sp.IgnoreWater=true;sp.RespectCanCollide=true
    local sy=(P.MaxY-P.MinY)/4
    active=true
    root:SetAttribute("LinkRepairStatus","BUILDING")
    local ok,err=xpcall(function()
        for ti,tile in ipairs(tiles) do
            guard()
            local region=Region3.new(Vector3.new(tile.X,P.MinY,tile.Z),
                Vector3.new(tile.X+P.TileSize,P.MaxY,tile.Z+P.TileSize))
            local before=terrain:ReadVoxelChannels(region,4,channels)
            assert(before.Size.X==16 and before.Size.Y==sy and before.Size.Z==16,"Unexpected native tile dimensions")
            local after,refresh=nil,{}
            for _,c in ipairs(tile.Columns) do
                report.checked=report.checked+1
                local occupied,top=V.top(before,c.IX,c.IZ,sy,P.MinY,Enum.Material.Air)
                local origin=Vector3.new(c.X,512,c.Z)
                local ray=Vector3.new(0,-1024,0)
                local hit=workspace:Raycast(origin,ray,tp)
                if occupied then
                    -- A top outside the measured slab must not be interpreted as a missing column.
                    if not hit or (hit.Position.Y<P.MaxY and math.abs(hit.Position.Y-top)>8) then
                        report.nativeRayMismatch=report.nativeRayMismatch+1
                        refresh[#refresh+1]=c
                    end
                elseif hit then
                    report.outOfSlab=report.outOfSlab+1
                elseif c.ProtectedSource then
                    -- Do NOT replace native-map terrain/caves based on a guessed altitude.
                    report.protectedEmpty=report.protectedEmpty+1
                elseif workspace:Raycast(origin,ray,sp) then
                    report.partSupportedEmpty=report.partSupportedEmpty+1
                else
                    after=after or V.copy(before,16,sy,16)
                    V.fillEmpty(after,c.IX,c.IZ,sy,P.MinY,P.FoundationY,
                        G.fillHeight(P,c),Enum.Material[c.Material],Enum.Material.Air)
                    report.filled=report.filled+1
                end
            end
            if after or #refresh>0 then
                after=after or V.copy(before,16,sy,16)
                -- Native occupied columns are never changed in the FINAL state.
                guard()
                V.commit({
                    write=function(data) terrain:WriteVoxelChannels(region,4,data) end,
                    waitFrame=function() RunService.PostSimulation:Wait();guard() end,
                    read=function() return terrain:ReadVoxelChannels(region,4,channels) end,
                },before,after,refresh,16,sy,16,Enum.Material.Air)
                report.writes=report.writes+1
                report.refreshed=report.refreshed+#refresh
            end
            if ti%32==0 then
                print(string.format("[VALBRUME SIX LINKS] %d/%d tiles, refreshed=%d, filled=%d",ti,#tiles,report.refreshed,report.filled))
                RunService.PostSimulation:Wait()
            end
        end
        for _=1,3 do RunService.PostSimulation:Wait();guard() end
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
    root:SetAttribute("LinkRepairColumnsRefreshed",report.refreshed)
    root:SetAttribute("LinkRepairSeconds",report.seconds)
    finishedWorld,finishedGeneration,lastReport=world,generation,report
    print("[VALBRUME SIX LINKS] "..HttpService:JSONEncode(report))
    return report
end
return R

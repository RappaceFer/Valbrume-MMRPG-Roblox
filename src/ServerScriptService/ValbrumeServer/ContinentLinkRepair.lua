-- Candidate 0.2.5: preserve six-link fills; rebuild Terrain query state only on residual links proven by the canary.
-- The bounded round-trip never designs new native relief. It canonicalizes only Roblox's documented
-- full-solid liquid overlap before restoring the same voxel channels.
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local P=require(script.Parent.ContinentLinkPlan)
local R={}
local active,finishedWorld,finishedGeneration,lastReport
local CHANNELS={"SolidMaterial","SolidOccupancy","LiquidOccupancy"}
local EPSILON=1/255+.00001
local TARGET_REFRESH={S3_P6=true,O5_P8=true,V6_P7=true}
local function lerp(a,b,t) return a+(b-a)*t end
local function validOcc(v) return type(v)=="number" and v==v and v>=0 and v<=1 end
local function copyChannels(data,size)
    local out={}
    for _,name in ipairs(CHANNELS) do
        assert(type(data[name])=="table","Missing channel "..name)
        out[name]={}
        for x=1,size.X do
            out[name][x]={}
            for y=1,size.Y do
                out[name][x][y]={}
                for z=1,size.Z do
                    local v=data[name][x][y][z]
                    assert(v~=nil,"Incomplete voxel channel")
                    if name~="SolidMaterial" then assert(validOcc(v),"Invalid occupancy") end
                    out[name][x][y][z]=v
                end
            end
        end
    end
    return out
end
local function canonical(data,size)
    local out=copyChannels(data,size)
    local normalized=0
    for x=1,size.X do for y=1,size.Y do for z=1,size.Z do
        if out.SolidMaterial[x][y][z]~=Enum.Material.Air
            and out.SolidOccupancy[x][y][z]==1
            and out.LiquidOccupancy[x][y][z]>0 then
            out.LiquidOccupancy[x][y][z]=0
            normalized=normalized+1
        end
    end end end
    return out,normalized
end
local function equalChannels(a,b,size)
    for _,name in ipairs(CHANNELS) do
        for x=1,size.X do for y=1,size.Y do for z=1,size.Z do
            local av,bv=a[name][x][y][z],b[name][x][y][z]
            if name=="SolidMaterial" then
                if av~=bv then return false,name,x,y,z,av,bv end
            else
                if not(validOcc(av) and validOcc(bv)) or math.abs(av-bv)>EPSILON then
                    return false,name,x,y,z,av,bv
                end
            end
        end end end
    end
    return true
end
local function samplePoints(link)
    local out={}
    for _,offset in ipairs(P.CheckOffsets) do
        for i=1,#link.Points-1 do
            local a,b=link.Points[i],link.Points[i+1]
            local dx,dz=b[1]-a[1],b[3]-a[3]
            local distance=math.sqrt(dx*dx+dz*dz)
            local count=math.max(1,math.ceil(distance/P.CheckStep))
            for n=(i==1 and 0 or 1),count do
                local t=n/count
                out[#out+1]={
                    x=lerp(a[1],b[1],t)-dz/distance*offset,
                    z=lerp(a[3],b[3],t)+dx/distance*offset,
                    y=lerp(a[2],b[2],t),offset=offset,segment=i,sample=n,
                }
            end
        end
    end
    return out
end
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
    local function ray(x,z)
        return workspace:Raycast(Vector3.new(x,384,z),Vector3.new(0,-896,0),tp)
    end
    local report={version=P.Version,samples=0,existing=0,filled=0,writes=0,
        residualBefore=0,refreshTiles=0,refreshWrites=0,normalizedFullSolidLiquidCells=0,
        exactSolidMisses=0,exactEmptyMisses=0,postMissing=0,postMissingByLink={},seconds=0}
    active=true
    root:SetAttribute("LinkRepairStatus","BUILDING")
    local ok,err=xpcall(function()
        for _,link in ipairs(P.Links) do
            for _,pt in ipairs(samplePoints(link)) do
                guard();report.samples=report.samples+1
                if ray(pt.x,pt.z) then report.existing=report.existing+1 else
                    local bottom=P.FoundationY
                    assert(pt.y>bottom+4 and pt.y<P.MaxY,"Unsafe six-link fill height")
                    terrain:FillBlock(CFrame.new(pt.x,(bottom+pt.y)/2,pt.z),
                        Vector3.new(P.FillFootprint,pt.y-bottom,P.FillFootprint),Enum.Material[link.Material])
                    report.filled=report.filled+1;report.writes=report.writes+1
                end
                if report.samples%128==0 then RunService.PostSimulation:Wait() end
            end
        end
        for _=1,6 do RunService.PostSimulation:Wait();guard() end
        task.wait(P.PhysicsSettleSeconds);guard()

        local tiles={}
        for _,link in ipairs(P.Links) do
            if TARGET_REFRESH[link.Id] then
                for _,pt in ipairs(samplePoints(link)) do
                    if not ray(pt.x,pt.z) then
                        report.residualBefore=report.residualBefore+1
                        local minX=math.floor(pt.x/P.RefreshTileSize)*P.RefreshTileSize
                        local minZ=math.floor(pt.z/P.RefreshTileSize)*P.RefreshTileSize
                        local key=minX..":"..minZ
                        local item=tiles[key]
                        if not item then item={x=minX,z=minZ,points={}};tiles[key]=item end
                        item.points[#item.points+1]=pt
                    end
                end
            end
        end
        local ordered={}
        for _,tile in pairs(tiles) do ordered[#ordered+1]=tile end
        table.sort(ordered,function(a,b) return a.x==b.x and a.z<b.z or a.x<b.x end)
        assert(#ordered<=P.MaxRefreshTiles,"Too many residual refresh tiles")

        for ti,tile in ipairs(ordered) do
            guard()
            local min=Vector3.new(tile.x,P.MinY,tile.z)
            local max=Vector3.new(tile.x+P.RefreshTileSize,P.MaxY,tile.z+P.RefreshTileSize)
            local region=Region3.new(min,max)
            local before=terrain:ReadVoxelChannels(region,4,CHANNELS)
            local size=before.Size
            assert(size.X==P.RefreshTileSize/4 and size.Y==(P.MaxY-P.MinY)/4
                and size.Z==P.RefreshTileSize/4,"Unexpected refresh tile dimensions")
            local shouldRefresh=false
            for _,pt in ipairs(tile.points) do
                local ix=math.clamp(math.floor((pt.x-tile.x)/4)+1,1,size.X)
                local iz=math.clamp(math.floor((pt.z-tile.z)/4)+1,1,size.Z)
                local solid=false
                for iy=1,size.Y do
                    if before.SolidMaterial[ix][iy][iz]~=Enum.Material.Air
                        and before.SolidOccupancy[ix][iy][iz]>0 then solid=true;break end
                end
                if solid then report.exactSolidMisses=report.exactSolidMisses+1;shouldRefresh=true
                else report.exactEmptyMisses=report.exactEmptyMisses+1 end
            end
            if shouldRefresh then
                local desired,normalized=canonical(before,size)
                local empty=copyChannels(desired,size)
                for x=1,size.X do for y=1,size.Y do for z=1,size.Z do
                    empty.SolidMaterial[x][y][z]=Enum.Material.Air
                    empty.SolidOccupancy[x][y][z]=0
                    empty.LiquidOccupancy[x][y][z]=0
                end end end
                local function write(data)
                    guard()
                    terrain:WriteVoxelChannels(region,4,{SolidMaterial=data.SolidMaterial,
                        SolidOccupancy=data.SolidOccupancy,LiquidOccupancy=data.LiquidOccupancy})
                    report.refreshWrites=report.refreshWrites+1
                end
                local function waitFrames()
                    for _=1,3 do RunService.PostSimulation:Wait() end
                    guard()
                end
                local function verify()
                    local last
                    for attempt=1,3 do
                        local check=terrain:ReadVoxelChannels(region,4,CHANNELS)
                        local same,name,x,y,z,av,bv=equalChannels(desired,check,size)
                        if same then return end
                        last=string.format("%s (%d,%d,%d) expected=%s actual=%s",name,x,y,z,tostring(av),tostring(bv))
                        if attempt<3 then waitFrames() end
                    end
                    error("Refresh readback mismatch tile "..tile.x..","..tile.z.." "..tostring(last))
                end
                local success,why=xpcall(function()
                    write(empty);waitFrames();write(desired);waitFrames();verify()
                end,debug.traceback)
                if not success then
                    local restored,restoreErr=pcall(function()
                        terrain:WriteVoxelChannels(region,4,{SolidMaterial=desired.SolidMaterial,
                            SolidOccupancy=desired.SolidOccupancy,LiquidOccupancy=desired.LiquidOccupancy})
                        for _=1,3 do RunService.PostSimulation:Wait() end
                        assert(valid(),"World changed during refresh rollback")
                        verify()
                    end)
                    error("Residual tile refresh failed "..tile.x..","..tile.z..": "..tostring(why)
                        .."; canonicalTileRestored="..tostring(restored).." "..tostring(restoreErr))
                end
                report.refreshTiles=report.refreshTiles+1
                report.normalizedFullSolidLiquidCells=report.normalizedFullSolidLiquidCells+normalized
            end
            if ti%8==0 then RunService.PostSimulation:Wait();guard() end
        end
        task.wait(P.PhysicsSettleSeconds);guard()

        for _,link in ipairs(P.Links) do
            local missing=0
            for _,pt in ipairs(samplePoints(link)) do
                if not ray(pt.x,pt.z) then missing=missing+1;report.postMissing=report.postMissing+1 end
            end
            report.postMissingByLink[link.Id]=missing
        end
        report.status=(report.postMissing==0) and "SUPPORT_FILLED" or "REFRESH_INCOMPLETE"
    end,debug.traceback)
    active=false
    report.seconds=os.clock()-started
    if not ok then
        root:SetAttribute("LinkRepairStatus","FAILED_PARTIAL")
        world:SetAttribute("GenerationError","Six links 0.2.5: "..tostring(err))
        error("Six-link repair interrupted. Stop Play; do not publish: "..tostring(err))
    end
    root:SetAttribute("LinkRepairVersion",P.Version)
    root:SetAttribute("LinkRepairStatus",report.status=="SUPPORT_FILLED" and "APPLIED_AUDIT_PENDING" or "REFRESH_INCOMPLETE")
    root:SetAttribute("LinkRepairColumnsFilled",report.filled)
    root:SetAttribute("LinkRepairRefreshTiles",report.refreshTiles)
    root:SetAttribute("LinkRepairSeconds",report.seconds)
    finishedWorld,finishedGeneration,lastReport=world,generation,report
    print("[VALBRUME SIX LINKS] "..HttpService:JSONEncode(report))
    return report
end
return R

-- Read-only sampling. A clear raycast is NOT a complete movement/gameplay test.
local A={}
function A.run(layout)
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    if game:GetService("RunService"):IsRunning() then
        assert(game:GetService("RunService"):IsServer(),"Audit in Server context")
    end
    local byId={};for _,r in ipairs(layout.Regions) do byId[r.Id]=r end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances={workspace.Terrain};params.IgnoreWater=false
    local solid=RaycastParams.new();solid.FilterType=Enum.RaycastFilterType.Include
    solid.FilterDescendantsInstances={workspace:FindFirstChild("ValbrumeContinentsV4"),workspace.Terrain}
    solid.RespectCanCollide=true;solid.IgnoreWater=true
    local H=game:GetService("HttpService")
    print("=== VALBRUME_CONTINENTS_V4_AUDIT_BEGIN ===")
    for _,link in ipairs(layout.Links) do
        local a,b=byId[link[1]],byId[link[2]]
        local count=math.ceil(math.sqrt((a.X-b.X)^2+(a.Z-b.Z)^2)/8)
        local report={from=a.Id,to=b.Id,samples=count+1,missingTerrain=0,water=0,steep=0,
            heightChanges=0,solidSupportMissing=0,maxDelta=0,anomalies={},note="Straight-line candidate; not an authored final road"}
        local last
        for i=0,count do
            local x,z=a.X+(b.X-a.X)*i/count,a.Z+(b.Z-a.Z)*i/count
            local origin=Vector3.new(x,layout.TopY+32,z);local dir=Vector3.new(0,-640,0)
            local hit=workspace:Raycast(origin,dir,params);local physical=workspace:Raycast(origin,dir,solid)
            local issue=false
            if not physical then report.solidSupportMissing=report.solidSupportMissing+1;issue=true end
            if not hit then report.missingTerrain=report.missingTerrain+1;issue=true;last=nil
            else
                if hit.Material==Enum.Material.Water then report.water=report.water+1;issue=true end
                if hit.Normal.Y<math.cos(math.rad(32)) then report.steep=report.steep+1;issue=true end
                if last then
                    local d=math.abs(hit.Position.Y-last);report.maxDelta=math.max(report.maxDelta,d)
                    if d>5 then report.heightChanges=report.heightChanges+1;issue=true end
                end
                last=hit.Position.Y
            end
            if issue and #report.anomalies<80 then
                report.anomalies[#report.anomalies+1]={x=x,z=z,y=hit and hit.Position.Y,
                    material=hit and hit.Material.Name,support=physical and physical.Instance:GetFullName()}
            end
        end
        print(H:JSONEncode(report))
    end
    print("=== VALBRUME_CONTINENTS_V4_AUDIT_END ===")
end
return A

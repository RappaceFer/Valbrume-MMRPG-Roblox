-- Same dense measurements before/after. Terrain, collision support and headroom.
-- Broadphase box hits are potential obstacles, NOT proof of exact mesh collision.
local P=require(script.Parent.Plan)
local F=require(script.Parent.Field)
local A={}
function A.run(world,path,guard)
    local terrain=workspace.Terrain
    local root=workspace:FindFirstChild("ValbrumeContinents")
    local tp=RaycastParams.new();tp.FilterType=Enum.RaycastFilterType.Include
    tp.FilterDescendantsInstances={terrain};tp.IgnoreWater=false
    local sp=RaycastParams.new();sp.FilterType=Enum.RaycastFilterType.Include
    sp.FilterDescendantsInstances={terrain,world,root};sp.IgnoreWater=true;sp.RespectCanCollide=true
    local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Include
    op.FilterDescendantsInstances={world,root};op.RespectCanCollide=true;op.MaxParts=0
    local r={samples=0,missing=0,unsupported=0,water=0,steep=0,grade=0,
        headroom=0,decorBounds=0,sweep=0,details={},support={},endpoints={},
        step=P.AuditStep,offsets=P.AuditOffsets,manualTraversalPending=true,visualPending=true}
    local n=math.ceil((path.length+P.EndpointProbe*2)/P.AuditStep)
    for _,offset in ipairs(P.AuditOffsets) do
        local previous
        for i=0,n do
            guard()
            local s=-P.EndpointProbe+(path.length+P.EndpointProbe*2)*i/n
            local x,z,nx,nz=F.at(path,s);x=x+nx*offset;z=z+nz*offset
            local origin,down=Vector3.new(x,384,z),Vector3.new(0,-896,0)
            local th,sh=workspace:Raycast(origin,down,tp),workspace:Raycast(origin,down,sp)
            local bounds
            local flags={};local function flag(k) r[k]=r[k]+1;flags[#flags+1]=k end
            if not th then flag("missing") end
            if not sh then flag("unsupported") end
            if th and th.Material==Enum.Material.Water then flag("water") end
            if sh then
                if sh.Normal.Y<math.cos(math.rad(P.MaxSlope)) then flag("steep") end
                local pos=sh.Position
                local up=workspace:Raycast(pos+Vector3.new(0,.6,0),Vector3.new(0,P.Headroom,0),sp)
                if up then flag("headroom") end
                local center=pos+Vector3.new(0,.6+P.Headroom/2,0)
                bounds=workspace:GetPartBoundsInBox(CFrame.new(center),Vector3.new(P.AvatarWidth,P.Headroom,P.AvatarWidth),op)
                if #bounds>0 then flag("decorBounds") end
                if previous then
                    local d=pos-previous
                    local horizontal=math.sqrt(d.X*d.X+d.Z*d.Z)
                    if horizontal>.01 and math.abs(d.Y)/horizontal>math.tan(math.rad(P.MaxGrade)) then flag("grade") end
                    -- Upper body swept between samples, complemented by the overlap above.
                    if d.Magnitude>.01 and d.Magnitude<1000 then
                        local hit=workspace:Blockcast(CFrame.new(previous+Vector3.new(0,3.5,0)),
                            Vector3.new(P.AvatarWidth,4,P.AvatarWidth),d,sp)
                        if hit then flag("sweep") end
                    end
                end
                previous=pos
            else previous=nil end
            r.samples=r.samples+1
            r.support[#r.support+1]={terrain=th~=nil,solid=sh~=nil}
            if s<0 or s>path.length then r.endpoints[#r.endpoints+1]={x=x,z=z,y=sh and sh.Position.Y,offset=offset} end
            if #flags>0 and #r.details<P.MaxDetails then
                r.details[#r.details+1]={x=x,z=z,offset=offset,s=s,flags=flags,
                    terrainY=th and th.Position.Y,supportY=sh and sh.Position.Y,
                    support=sh and sh.Instance:GetFullName(),decor=bounds and bounds[1] and bounds[1]:GetFullName()}
            end
            if r.samples%100==0 then task.wait() end
        end
    end
    r.status=(r.missing+r.unsupported+r.water+r.steep+r.grade+r.headroom+r.decorBounds+r.sweep==0)
        and "GEOMETRY_SAMPLED_OK" or "REVIEW_REQUIRED"
    return r
end
function A.public(result)
    local out={};for k,v in pairs(result) do if k~="support" then out[k]=v end end
    return out
end
function A.supportRegressions(before,after)
    assert(#before.support==#after.support,"Different before/after samples")
    local count=0
    for i,a in ipairs(before.support) do
        local b=after.support[i]
        if (a.terrain and not b.terrain) or (a.solid and not b.solid) then count=count+1 end
    end
    return count
end
return A

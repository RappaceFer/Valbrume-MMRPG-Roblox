-- Numerical geometry only. No DataModel access and no hidden height fallback.
local F = {}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
function F.smooth(t)
    t=clamp(t,0,1)
    return t*t*t*(t*(t*6-15)+10)
end
local function finite(x) return type(x)=="number" and x==x and math.abs(x)<math.huge end
function F.path(plan)
    assert(#plan.Points>=2 and plan.Resolution==4 and plan.TileSize==32,"Invalid plan")
    local points, length = {},0
    for i=1,#plan.Points-1 do
        local p0=plan.Points[math.max(1,i-1)]
        local p1,p2=plan.Points[i],plan.Points[i+1]
        local p3=plan.Points[math.min(#plan.Points,i+2)]
        local n=math.max(2,math.ceil(math.sqrt((p2[1]-p1[1])^2+(p2[2]-p1[2])^2)/4))
        for j=(i==1 and 0 or 1),n do
            local t=j/n
            local function axis(k)
                return .5*(2*p1[k]+(-p0[k]+p2[k])*t
                    +(2*p0[k]-5*p1[k]+4*p2[k]-p3[k])*t*t
                    +(-p0[k]+3*p1[k]-3*p2[k]+p3[k])*t*t*t)
            end
            local x,z=axis(1),axis(2)
            assert(finite(x) and finite(z) and x< -500,"Invalid path coordinate")
            local last=points[#points]
            if last then length=length+math.sqrt((x-last.x)^2+(z-last.z)^2) end
            points[#points+1]={x=x,z=z,s=length}
        end
    end
    assert(length>plan.EndFade*2,"Path too short for end transitions")
    return {points=points,length=length}
end
function F.at(path,s)
    local ps=path.points
    local a,b=ps[1],ps[2]
    if s>=path.length then a,b=ps[#ps-1],ps[#ps]
    elseif s>0 then
        for i=1,#ps-1 do if s<=ps[i+1].s then a,b=ps[i],ps[i+1];break end end
    end
    local d=b.s-a.s; assert(d>0,"Duplicate path point")
    local t=(s-a.s)/d
    return a.x+(b.x-a.x)*t,a.z+(b.z-a.z)*t,-(b.z-a.z)/d,(b.x-a.x)/d
end
function F.nearest(path,x,z)
    local best
    for i=1,#path.points-1 do
        local a,b=path.points[i],path.points[i+1]
        local dx,dz=b.x-a.x,b.z-a.z
        local d2=dx*dx+dz*dz
        local t=clamp(((x-a.x)*dx+(z-a.z)*dz)/d2,0,1)
        local rx,rz=x-a.x-t*dx,z-a.z-t*dz
        local distance=math.sqrt(rx*rx+rz*rz)
        if not best or distance<best.d then
            best={d=distance,s=a.s+t*math.sqrt(d2),side=(rx*(-dz)+rz*dx)>=0 and 1 or -1}
        end
    end
    return best
end
function F.rectDistance(x,z,r,half)
    half=half or 0
    local dx=math.max(r[1]-(x+half),(x-half)-r[3],0)
    local dz=math.max(r[2]-(z+half),(z-half)-r[4],0)
    return math.sqrt(dx*dx+dz*dz)
end
function F.weight(plan,path,x,z,boxes,v3)
    local n=F.nearest(path,x,z)
    local outer=plan.OuterRadius+10*math.sin(n.s/87)+6*n.side*math.sin(n.s/121)
    if n.d>=outer then return 0,n end
    local w=(1-F.smooth((n.d-plan.CoreRadius)/(outer-plan.CoreRadius)))
        *F.smooth(n.s/plan.EndFade)*F.smooth((path.length-n.s)/plan.EndFade)
    for _,r in ipairs(plan.ProtectedSources) do
        w=math.min(w,F.smooth((F.rectDistance(x,z,r,2)-plan.SourceMoat)/plan.SourceFeather))
    end
    if v3 then
        for _,c in pairs(v3.Regions) do
            local d=math.sqrt((x-c[1])^2+(z-c[3])^2)-3
            w=math.min(w,F.smooth((d-160)/48))
        end
        for _,r in ipairs(v3.Routes) do
            for i=1,#r.Points-1 do
                local a,b=r.Points[i],r.Points[i+1]
                local dx,dz=b[1]-a[1],b[3]-a[3]
                local t=clamp(((x-a[1])*dx+(z-a[3])*dz)/(dx*dx+dz*dz),0,1)
                local d=math.sqrt((x-a[1]-t*dx)^2+(z-a[3]-t*dz)^2)
                w=math.min(w,F.smooth((d-r.Outer-8)/32))
            end
        end
    end
    for _,r in ipairs(boxes or {}) do
        w=math.min(w,F.smooth((F.rectDistance(x,z,r,2)-plan.ObjectMoat)/plan.ObjectFeather))
    end
    return w,n
end
function F.height(plan,path,native,w,n,h0,h1)
    assert(finite(native) and finite(h0) and finite(h1),"Missing measured height")
    local t=n.s/path.length
    local profile=h0+(h1-h0)*t+plan.Crest*math.sin(math.pi*t)^2
    local shoulder=math.max(0,n.d-plan.CoreRadius)
    local target=profile-math.min(n.d,plan.CoreRadius)*.022
        +math.sin(n.s/65+n.side)*math.min(shoulder*.055,3)
    local desired=native+w*clamp(target-native,-plan.MaxCut,plan.MaxFill)
    return desired,profile
end
function F.tiles(plan,path)
    local minx,minz,maxx,maxz=math.huge,math.huge,-math.huge,-math.huge
    for _,p in ipairs(path.points) do
        minx=math.min(minx,p.x);minz=math.min(minz,p.z)
        maxx=math.max(maxx,p.x);maxz=math.max(maxz,p.z)
    end
    local r=plan.OuterRadius+20; local tiles={}
    for x=math.floor((minx-r)/32)*32,math.floor((maxx+r)/32)*32,32 do
        for z=math.floor((minz-r)/32)*32,math.floor((maxz+r)/32)*32,32 do
            local n=F.nearest(path,x+16,z+16)
            if n.d<r+24 then
                local protected=false
                for _,b in ipairs(plan.ProtectedSources) do
                    if x<=b[3] and x+32>=b[1] and z<=b[4] and z+32>=b[2] then protected=true end
                end
                if not protected then tiles[#tiles+1]={x=x,z=z} end
            end
        end
    end
    assert(#tiles>0 and #tiles<=plan.MaxTiles,"Tile budget exceeded")
    return tiles
end
return F

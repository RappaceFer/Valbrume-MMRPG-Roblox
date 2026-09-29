-- Pure numerical helpers; no DataModel access. Shared by builder and local tests.
local G = {}
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
local function clamp(n,a,b) return math.max(a,math.min(b,n)) end
local function segment(x,z,a,b)
    local dx,dz=b[1]-a[1],b[3]-a[3]
    local t=clamp(((x-a[1])*dx+(z-a[3])*dz)/(dx*dx+dz*dz),0,1)
    local ox,oz=x-a[1]-dx*t,z-a[3]-dz*t
    return ox*ox+oz*oz,a[2]+(b[2]-a[2])*t
end
function G.sourceProtected(p,x,z)
    for _,b in ipairs(p.SourceBounds) do
        if x>=b[1] and x<b[3] and z>=b[2] and z<b[4] then return true end
    end
    return false
end
function G.v3Protected(v3,x,z)
    -- Full V3 shoulders, plus one voxel of clearance, not just its visible road.
    for _,r in ipairs(v3.Routes) do
        for i=1,#r.Points-1 do
            if segment(x,z,r.Points[i],r.Points[i+1]) <= (r.Outer+4)^2 then return true end
        end
    end
    return false
end
function G.at(p,v3,x,z)
    if math.abs(x)<400 or G.v3Protected(v3,x,z) then return nil end
    -- Keep the six camps and their immediate gameplay spaces out of the write masks.
    for _,c in pairs(v3.Regions) do
        if (x-c[1])^2+(z-c[3])^2<128^2 then return nil end
    end
    local distance,height,which=math.huge,nil,nil
    for _,r in ipairs(p.Links) do
        for i=1,#r.Points-1 do
            local d,y=segment(x,z,r.Points[i],r.Points[i+1])
            if d<distance then distance,height,which=d,y,r end
        end
    end
    if distance>=p.OuterRadius^2 then return nil end
    return {Height=height, Distance=math.sqrt(distance), Link=which.Id,
        Material=which.Material, ProtectedSource=G.sourceProtected(p,x,z)}
end
function G.fillHeight(p,info)
    local t=clamp((info.Distance-p.CoreRadius)/(p.OuterRadius-p.CoreRadius),0,1)
    -- Feather the new embankment. Central 64 studs stay at the numerical datum.
    return info.Height-12*(t*t*(3-2*t))
end
function G.tiles(p,v3,atlas)
    assert(p.Resolution==4 and p.TileSize==64,"Unexpected voxel/tile size")
    assert(p.MinY%4==0 and p.MaxY%4==0 and p.MaxY>p.MinY,"Invalid vertical range")
    assert(p.CoreRadius>0 and p.OuterRadius>p.CoreRadius,"Invalid radii")
    assert(p.MaxTiles>0 and p.MaxTiles<=640 and p.MaxSeconds>0 and p.MaxSeconds<=85,"Invalid budgets")
    assert(p.FoundationY>=p.MinY and p.FoundationY<p.MaxY,"Invalid foundation")
    assert(#p.Links==6 and #atlas.Probes==6,"Expected exactly six original probes")
    assert(v3.Version=="3.1.0" and #v3.Routes==6,"V3 layout changed; review protections")
    local ids,candidates={},{}
    for ri,r in ipairs(p.Links) do
        assert(not ids[r.Id] and r.Id==atlas.Probes[ri].Id,"Link identity/order changed")
        ids[r.Id]=true
        assert(#r.Points>=2 and #r.Points==#atlas.Probes[ri].Points,"Probe shape changed")
        for i,a in ipairs(r.Points) do
            assert(#a==3 and finite(a[1]) and finite(a[2]) and finite(a[3]),"Non-finite point")
            local old=atlas.Probes[ri].Points[i]
            assert(a[1]==old[1] and a[3]==old[2],"Do not silently move an audit line")
            assert(math.abs(a[1])>400+p.OuterRadius and a[2]>p.FoundationY+24 and a[2]<p.MaxY-8,"Unsafe point")
            if i>1 then
                local b=r.Points[i-1]
                local distance=math.sqrt((a[1]-b[1])^2+(a[3]-b[3])^2)
                assert(a[1]*b[1]>0 and distance>1,"Zero length / cross-sea segment")
                assert(math.abs(a[2]-b[2])/distance<.25,"Fallback grade too steep")
                for tx=math.floor((math.min(a[1],b[1])-p.OuterRadius)/64),math.floor((math.max(a[1],b[1])+p.OuterRadius)/64) do
                    for tz=math.floor((math.min(a[3],b[3])-p.OuterRadius)/64),math.floor((math.max(a[3],b[3])+p.OuterRadius)/64) do
                        candidates[tx..":"..tz]={X=tx*64,Z=tz*64}
                    end
                end
            end
        end
    end
    local tiles={}
    for _,tile in pairs(candidates) do
        local columns={}
        for ix=1,16 do for iz=1,16 do
            local x,z=tile.X+(ix-.5)*4,tile.Z+(iz-.5)*4
            local info=G.at(p,v3,x,z)
            if info then
                info.X,info.Z,info.IX,info.IZ=x,z,ix,iz
                columns[#columns+1]=info
            end
        end end
        if #columns>0 then tile.Columns=columns;tiles[#tiles+1]=tile end
    end
    table.sort(tiles,function(a,b) return a.X==b.X and a.Z<b.Z or a.X<b.X end)
    assert(#tiles<=p.MaxTiles,"Tile budget exceeded BEFORE terrain writes")
    return tiles
end
return G

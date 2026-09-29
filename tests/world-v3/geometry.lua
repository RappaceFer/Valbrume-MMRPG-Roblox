local dir = ROOT.."/src/ServerScriptService/ValbrumeServer/WorldV3/"
local G,L = dofile(dir.."Geometry.lua"),dofile(dir.."Layout.lua")
math.clamp = function(x,a,b) return math.max(a,math.min(b,x)) end
G.validate(L)
local tiles,seen = G.plan(L),{}
for _,t in ipairs(tiles) do
    local k=t.X..":"..t.Z
    assert(not seen[k] and t.X%64==0 and t.Z%64==0)
    seen[k]=true
end
assert(#tiles<=L.MaxTiles)
local samples, maxGrade = 0,0
for _,r in ipairs(L.Routes) do
    for _,offset in ipairs({-20,-8,0,8,20}) do
        local prev
        G.walkSamples(r,3,function(x,z,nx,nz)
            x,z=x+nx*offset,z+nz*offset
            local s=assert(G.field(L.Routes,x,z))
            assert(math.abs(s.Weight-1)<1e-9, "Lane outside solid core")
            assert(math.abs(G.surface(s,nil,L.MinY)-s.Height)<1e-9)
            assert(seen[(math.floor(x/64)*64)..":"..(math.floor(z/64)*64)], "Tile coverage gap")
            if prev then
                local d=math.sqrt((x-prev.x)^2+(z-prev.z)^2)
                if d>.01 then
                    local grade=math.deg(math.atan(math.abs(s.Height-prev.y)/d))
                    maxGrade=math.max(maxGrade,grade)
                    assert(grade<=L.MaxDesignSlope, "Modelled grade too steep")
                end
            end
            prev={x=x,y=s.Height,z=z}; samples=samples+1
        end)
    end
end
assert(not G.field(L.Routes,0,0), "Unexpected ocean corridor")
assert(not G.field(L.Routes,3000,3000), "Unexpected staging edit")
local cases=0
for _,alter in ipairs({
    function(l) l.Routes[2].Id=l.Routes[1].Id end,
    function(l) l.Routes[1].Points[2]=l.Routes[1].Points[1] end,
    function(l) l.Routes[1].Points[2][2]=160 end,
    function(l) l.Routes[1].Points[2][1]=0/0 end,
    function(l) l.Resolution=2 end,
    function(l) l.MaxTiles=1 end,
}) do
    local l=dofile(dir.."Layout.lua"); alter(l)
    assert(not pcall(G.plan,l), "Invalid layout accepted"); cases=cases+1
end
print(string.format("PASS: geometry %d sampled points, %d unique tiles, max modelled grade %.3f deg",samples,#tiles,maxGrade))
print("PASS: 6 invalid-layout cases rejected before writes")
-- Test production SHA-1 in Lua 5.4 via a bit32-compatible shim.
bit32 = {}
bit32.band=function(a,...) for _,b in ipairs({...}) do a=a&b end return a&0xffffffff end
bit32.bor=function(a,...) for _,b in ipairs({...}) do a=a|b end return a&0xffffffff end
bit32.bxor=function(a,...) for _,b in ipairs({...}) do a=a~b end return a&0xffffffff end
bit32.bnot=function(a) return (~a)&0xffffffff end
bit32.lrotate=function(a,n) return ((a<<n)|(a>>(32-n)))&0xffffffff end
local hash=dofile(ROOT.."/tools/world-v3/GitBlobHash.lua")
assert(hash("")=="e69de29bb2d1d6434b8b29ae775ad8c2e48c5391")
assert(hash("test\n")=="9daeafb9864cf43055ae93beb0afd6c7d144bfa4")
assert(hash("test\r\n")==hash("test\n"))
local f=assert(io.open(ROOT.."/src/ServerScriptService/ValbrumeServer/WorldGeneration.lua","rb"))
assert(hash(f:read("*a"))=="939989bf9d63ea3ece408f910aa8ed566a1f286c"); f:close()
print("PASS: Git blob fingerprints (empty, text, CRLF, real baseline source)")

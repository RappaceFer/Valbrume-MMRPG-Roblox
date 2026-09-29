-- Pure numeric geometry. No Instances, Terrain writes or module side effects.
local G = {}
local function clamp(x, a, b) return math.max(a, math.min(b, x)) end
local function smooth(t) return t * t * (3 - 2 * t) end
local function finite(x) return type(x) == "number" and x == x and math.abs(x) < math.huge end

function G.validate(layout)
    assert(layout.Resolution == 4, "Terrain resolution must be 4")
    assert(layout.TileSize > 0 and layout.TileSize % 4 == 0, "Unaligned tile size")
    assert(layout.MinY % 4 == 0 and layout.MaxY % 4 == 0 and layout.MaxY > layout.MinY, "Invalid vertical bounds")
    assert((layout.TileSize / 4)^2 * ((layout.MaxY - layout.MinY) / 4) <= 4194304, "Oversized voxel tile")
    local ids = {}
    for _, r in ipairs(layout.Routes) do
        assert(type(r.Id) == "string" and not ids[r.Id], "Duplicate or invalid route ID")
        ids[r.Id] = true
        assert(r.Core >= 16 and r.Outer > r.Core + 16 and #r.Points >= 2, "Invalid corridor")
        for i, p in ipairs(r.Points) do
            assert(finite(p[1]) and finite(p[2]) and finite(p[3]), "Non-finite point")
            assert(p[2] > layout.MinY + 16 and p[2] < layout.MaxY - 24, "Point outside edit bounds")
            if i > 1 then
                local q = r.Points[i-1]
                local distance = math.sqrt((p[1]-q[1])^2 + (p[3]-q[3])^2)
                assert(distance > 1, "Zero-length segment in " .. r.Id)
                -- Smoothstep has maximum derivative 1.5, not 1.
                assert(1.5 * math.abs(p[2]-q[2]) / distance <= math.tan(math.rad(layout.MaxDesignSlope)),
                    "Excessive designed grade in " .. r.Id)
            end
        end
    end
end

function G.segment(a, b, x, z)
    local dx, dz = b[1]-a[1], b[3]-a[3]
    local d2 = dx*dx + dz*dz
    assert(d2 > 0, "Zero-length segment")
    local t = clamp(((x-a[1])*dx + (z-a[3])*dz)/d2, 0, 1)
    local px, pz = a[1]+dx*t, a[3]+dz*t
    local length = math.sqrt(d2)
    return {Distance = math.sqrt((x-px)^2+(z-pz)^2),
        Height = a[2]+(b[2]-a[2])*smooth(t), X = px, Z = pz,
        DX = dx/length, DZ = dz/length, T = t}
end

function G.route(route, x, z)
    local best
    for i = 1, #route.Points-1 do
        local hit = G.segment(route.Points[i], route.Points[i+1], x, z)
        if not best or hit.Distance < best.Distance then best = hit end
    end
    return best
end

function G.field(routes, x, z)
    local best, weightedY, weights, influence = nil, 0, 0, 0
    for _, r in ipairs(routes) do
        local s = G.route(r, x, z)
        if s.Distance < r.Outer then
            local w = 1 - smooth(clamp((s.Distance-r.Core)/(r.Outer-r.Core), 0, 1))
            weightedY = weightedY + w*s.Height
            weights = weights + w
            influence = math.max(influence, w)
            if not best or s.Distance/r.Core < best.Distance/best.Route.Core then
                best = s; best.Route = r
            end
        end
    end
    if not best or weights <= 0 then return nil end
    best.Height = weightedY/weights
    best.Weight = influence
    return best
end

function G.surface(sample, originalY, minY)
    if originalY then
        return originalY + (sample.Height-originalY)*sample.Weight
    end
    -- A missing bank is supported with a gentle shoulder, not an abrupt void.
    local d, r = sample.Distance, sample.Route
    local bank = sample.Height - math.max(0, d-r.Core)*0.3
    local edge = smooth(clamp((d-(r.Outer-16))/16, 0, 1))
    return bank + (minY-bank)*edge
end

function G.plan(layout)
    G.validate(layout)
    local size, seen, tiles = layout.TileSize, {}, {}
    local margin = size * math.sqrt(2) / 2
    for _, r in ipairs(layout.Routes) do
        for i = 1, #r.Points-1 do
            local a, b = r.Points[i], r.Points[i+1]
            local minX = math.floor((math.min(a[1], b[1])-r.Outer)/size)
            local maxX = math.floor((math.max(a[1], b[1])+r.Outer)/size)
            local minZ = math.floor((math.min(a[3], b[3])-r.Outer)/size)
            local maxZ = math.floor((math.max(a[3], b[3])+r.Outer)/size)
            for ix = minX, maxX do
                for iz = minZ, maxZ do
                    local key = tostring(ix) .. ":" .. tostring(iz)
                    if not seen[key] and G.segment(a,b,(ix+0.5)*size,(iz+0.5)*size).Distance <= r.Outer+margin then
                        seen[key] = true
                        tiles[#tiles+1] = {X = ix*size, Z = iz*size}
                    end
                end
            end
        end
    end
    assert(#tiles <= layout.MaxTiles, "World V3 tile budget exceeded")
    table.sort(tiles, function(a,b) return a.X == b.X and a.Z < b.Z or a.X < b.X end)
    return tiles
end

function G.walkSamples(route, step, callback)
    assert(step > 0, "Invalid sample step")
    local index = 0
    for i = 1, #route.Points-1 do
        local a, b = route.Points[i], route.Points[i+1]
        local dx, dz = b[1]-a[1], b[3]-a[3]
        local length = math.sqrt(dx*dx+dz*dz)
        local n = math.max(1, math.ceil(length/step))
        for j = (i == 1 and 0 or 1), n do
            local t = j/n
            index = index + 1
            callback(a[1]+dx*t, a[3]+dz*t, -dz/length, dx/length, index)
        end
    end
end
return G

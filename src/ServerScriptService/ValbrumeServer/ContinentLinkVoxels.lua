-- Array-only operations, separately tested without Roblox. Caller supplies materials.
local V = {}
local names={"SolidMaterial","SolidOccupancy","LiquidOccupancy"}
function V.copy(data,sx,sy,sz)
    local out={}
    for _,name in ipairs(names) do
        assert(type(data[name])=="table","Missing channel "..name)
        local dst={};out[name]=dst
        for x=1,sx do
            dst[x]={}
            for y=1,sy do
                local row={};dst[x][y]=row
                for z=1,sz do
                    local value=data[name][x][y][z]
                    assert(value~=nil,"Incomplete voxel array")
                    row[z]=value
                end
            end
        end
    end
    return out
end
function V.top(data,x,z,sy,minY,air)
    local solid,liquid=false,false
    local top
    for y=1,sy do
        local material=data.SolidMaterial[x][y][z]
        local occupancy=data.SolidOccupancy[x][y][z]
        local water=data.LiquidOccupancy[x][y][z]
        assert(type(occupancy)=="number" and occupancy>=0 and occupancy<=1,"Invalid solid occupancy")
        assert(type(water)=="number" and water>=0 and water<=1,"Invalid liquid occupancy")
        if material~=air and occupancy>0 then
            solid=true;top=minY+(y-1+occupancy)*4
        end
        if water>0 then
            liquid=true
            local surface=minY+(y-1+water)*4
            top=top and math.max(top,surface) or surface
        end
    end
    return solid or liquid,top
end
function V.clearColumn(data,x,z,sy,air)
    for y=1,sy do
        data.SolidMaterial[x][y][z]=air
        data.SolidOccupancy[x][y][z]=0
        data.LiquidOccupancy[x][y][z]=0
    end
end
function V.fillEmpty(data,x,z,sy,minY,foundationY,height,material,air)
    assert(not V.top(data,x,z,sy,minY,air),"Never fill an occupied native column")
    for y=1,sy do
        local bottom=minY+(y-1)*4
        if bottom>=foundationY then
            local o=math.max(0,math.min(1,(height-bottom)/4))
            if o>0 then
                data.SolidMaterial[x][y][z]=material
                data.SolidOccupancy[x][y][z]=o
                data.LiquidOccupancy[x][y][z]=0
            end
        end
    end
end
-- Strict validation is retained. Never accept NaN or increase the old tolerance
-- to conceal a failed write. Details distinguish the first channel/cell mismatch.
local function cell(data,x,y,z)
    return {
        material=tostring(data.SolidMaterial[x][y][z]),
        solid=data.SolidOccupancy[x][y][z],
        liquid=data.LiquidOccupancy[x][y][z],
    }
end
function V.equal(a,b,sx,sy,sz,epsilon)
    epsilon=epsilon or 0
    for x=1,sx do for y=1,sy do for z=1,sz do
        for _,name in ipairs(names) do
            local expected,actual=a[name][x][y][z],b[name][x][y][z]
            local same
            if name=="SolidMaterial" then
                same=expected==actual
            else
                same=type(expected)=="number" and type(actual)=="number"
                    and expected==expected and actual==actual
                    and expected>=0 and expected<=1 and actual>=0 and actual<=1
                    and math.abs(expected-actual)<=epsilon
            end
            if not same then
                return false,{channel=name,ix=x,iy=y,iz=z,
                    expected=cell(a,x,y,z),actual=cell(b,x,y,z)}
            end
        end
    end end end
    return true
end
local function describe(d)
    if not d then return "no-cell-detail" end
    local a,b=d.expected,d.actual
    return string.format("channel=%s cell=(%d,%d,%d) expected=(%s,%s,%s) actual=(%s,%s,%s)",
        d.channel,d.ix,d.iy,d.iz,a.material,tostring(a.solid),tostring(a.liquid),
        b.material,tostring(b.solid),tostring(b.liquid))
end
-- ReadVoxelChannels returns Size metadata. All paths, including rollback, use
-- detached copies with ONLY the three writable channels and dense numeric rows.
-- Copy/validation happens before the first write. Never mutate the read snapshot.
function V.commit(adapter,before,after,refresh,sx,sy,sz,air)
    local original=V.copy(before,sx,sy,sz)
    local desired=V.copy(after,sx,sy,sz)
    local attempts=3 -- bounded re-reads only; NEVER retries a destructive write
    local epsilon=1/255+.00001 -- unchanged from candidate 0.2.0
    local context=adapter.context or "unknown tile"
    local function report(phase,detail)
        if adapter.onMismatch then
            -- A diagnostic logger must not prevent restoration of the tile.
            pcall(adapter.onMismatch,phase,detail)
        end
    end
    local function verify(expected,waitFrame,phase)
        local detail
        for attempt=1,attempts do
            local same,diff=V.equal(expected,adapter.read(),sx,sy,sz,epsilon)
            if same then return end
            detail=diff
            if attempt<attempts then waitFrame() end
        end
        report(phase,detail)
        error(phase.." mismatch ["..context.."] "..describe(detail))
    end
    local ok,err=xpcall(function()
        if #refresh>0 then
            local cleared=V.copy(original,sx,sy,sz)
            for _,c in ipairs(refresh) do V.clearColumn(cleared,c.IX,c.IZ,sy,air) end
            adapter.write(cleared)
            adapter.waitFrame()
        end
        adapter.write(desired)
        adapter.waitFrame()
        verify(desired,adapter.waitFrame,"Voxel readback")
    end,debug.traceback)
    if not ok then
        -- The repair deadline is NOT a reason to skip rollback. The adapter's
        -- separate restoration callbacks still check world/session identity.
        local restored,restoreErr=pcall(function()
            local restore=adapter.restore or adapter.write
            local waitRestore=adapter.restoreWaitFrame or adapter.waitFrame
            restore(V.copy(original,sx,sy,sz))
            waitRestore()
            verify(original,waitRestore,"Restoration readback")
        end)
        error("Native tile repair failed ["..context.."]: "..tostring(err)
            .."; tileRestored="..tostring(restored).." "..tostring(restoreErr))
    end
end
return V

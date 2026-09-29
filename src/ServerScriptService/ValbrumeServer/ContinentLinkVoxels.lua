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
function V.equal(a,b,sx,sy,sz,epsilon)
    epsilon=epsilon or 0
    for x=1,sx do for y=1,sy do for z=1,sz do
        if a.SolidMaterial[x][y][z]~=b.SolidMaterial[x][y][z] then return false end
        if math.abs(a.SolidOccupancy[x][y][z]-b.SolidOccupancy[x][y][z])>epsilon then return false end
        if math.abs(a.LiquidOccupancy[x][y][z]-b.LiquidOccupancy[x][y][z])>epsilon then return false end
    end end end
    return true
end
-- Recreate local native collision data only where native occupancy and rays disagree.
-- If a write/wait/verification fails, attempt to restore THIS tile's original channels.
-- Earlier successful tiles remain patched until Stop; caller must mark generation failed.
function V.commit(adapter,before,after,refresh,sx,sy,sz,air)
    local ok,err=xpcall(function()
        if #refresh>0 then
            local cleared=V.copy(before,sx,sy,sz)
            for _,c in ipairs(refresh) do V.clearColumn(cleared,c.IX,c.IZ,sy,air) end
            adapter.write(cleared)
            adapter.waitFrame()
        end
        adapter.write(after)
        adapter.waitFrame()
        assert(V.equal(after,adapter.read(),sx,sy,sz,1/255+.00001),"Voxel readback mismatch")
    end,debug.traceback)
    if not ok then
        local restored,restoreErr=pcall(function()
            adapter.write(before)
            adapter.waitFrame()
            assert(V.equal(before,adapter.read(),sx,sy,sz,1/255+.00001),"Restoration readback mismatch")
        end)
        error("Native tile repair failed: "..tostring(err).."; tileRestored="..tostring(restored).." "..tostring(restoreErr))
    end
end
return V

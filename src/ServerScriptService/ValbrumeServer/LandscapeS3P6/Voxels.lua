-- Native channel editing. Preserve cavities below the top connected soil layer.
local V={}
V.Names={"SolidMaterial","SolidOccupancy","LiquidOccupancy"}
V.Epsilon=1/255+.00001
local function occ(v) return type(v)=="number" and v==v and v>=0 and v<=1 end
function V.copy(data,size)
    local out={}
    for _,k in ipairs(V.Names) do
        assert(type(data[k])=="table","Missing channel "..k)
        out[k]={}
        for x=1,size.X do
            out[k][x]={}
            for y=1,size.Y do
                out[k][x][y]={}
                for z=1,size.Z do
                    local value=data[k][x][y][z]
                    assert(value~=nil and (k=="SolidMaterial" or occ(value)),"Invalid voxel channel")
                    out[k][x][y][z]=value
                end
            end
        end
    end
    return out -- Never forwards Size metadata to WriteVoxelChannels.
end
function V.canonical(data,size,air)
    local out,count=V.copy(data,size),0
    for x=1,size.X do for y=1,size.Y do for z=1,size.Z do
        if out.SolidMaterial[x][y][z]~=air and out.SolidOccupancy[x][y][z]==1
            and out.LiquidOccupancy[x][y][z]>0 then
            out.LiquidOccupancy[x][y][z]=0;count=count+1
        end
    end end end
    return out,count
end
function V.equal(a,b,size)
    for _,k in ipairs(V.Names) do
        for x=1,size.X do for y=1,size.Y do for z=1,size.Z do
            local av,bv=a[k][x][y][z],b[k][x][y][z]
            local same=av==bv
            if k~="SolidMaterial" then same=occ(av) and occ(bv) and math.abs(av-bv)<=V.Epsilon end
            if not same then return false,string.format("%s (%d,%d,%d) %s / %s",k,x,y,z,tostring(av),tostring(bv)) end
        end end end
    end
    return true
end
function V.surface(data,x,z,plan,air)
    local ny=(plan.MaxY-plan.MinY)/4
    for y=1,ny do
        if data.LiquidOccupancy[x][y][z]>0 then return nil,"water" end
    end
    local top
    for y=ny,1,-1 do
        if data.SolidMaterial[x][y][z]~=air and data.SolidOccupancy[x][y][z]>0 then top=y;break end
    end
    if not top then return nil,"empty" end
    if top>=ny-1 then return nil,"ceiling" end
    local bottom=top
    while bottom>1 and data.SolidOccupancy[x][bottom-1][z]>0
        and data.SolidMaterial[x][bottom-1][z]~=air do bottom=bottom-1 end
    return {height=plan.MinY+(top-1+data.SolidOccupancy[x][top][z])*4,
        floor=plan.MinY+(bottom-1)*4,material=data.SolidMaterial[x][top][z]}
end
function V.sculpt(data,x,z,surface,height,topMaterial,plan,air,ground)
    if height<surface.floor+plan.CoverDepth then return nil,"thinRoof" end
    local start=math.max(surface.floor+8,math.min(surface.height,height)-8)
    local first=math.floor((start-plan.MinY)/4)+1
    local count=0
    for y=first,(plan.MaxY-plan.MinY)/4 do
        local bottom=plan.MinY+(y-1)*4
        local amount=math.max(0,math.min(1,(height-bottom)/4))
        local material=amount==0 and air or (bottom>=height-8 and topMaterial or ground)
        if data.SolidMaterial[x][y][z]~=material or math.abs(data.SolidOccupancy[x][y][z]-amount)>V.Epsilon then
            data.SolidMaterial[x][y][z]=material
            data.SolidOccupancy[x][y][z]=amount
            -- Only completely dry columns can reach this function.
            data.LiquidOccupancy[x][y][z]=0
            count=count+1
        end
    end
    return count,first
end
function V.clearEdits(data,edits,ny,air)
    for _,c in ipairs(edits) do
        for y=c.first,ny do
            data.SolidMaterial[c.x][y][c.z]=air
            data.SolidOccupancy[c.x][y][c.z]=0
            data.LiquidOccupancy[c.x][y][c.z]=0
        end
    end
end
return V

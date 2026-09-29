-- Lua 5.4/shared Luau syntax. Deliberately simulated API, not a Roblox engine test.
local root=assert(os.getenv('VALBRUME_LINK_RELEASE'))
local V=dofile(root..'/src/ServerScriptService/ValbrumeServer/ContinentLinkVoxels.lua')
local oldPath=os.getenv('VALBRUME_PREVIOUS_VOXELS')
local old=oldPath and dofile(oldPath)
local names={'SolidMaterial','SolidOccupancy','LiquidOccupancy'}
local allowed={SolidMaterial=true,SolidOccupancy=true,LiquidOccupancy=true}
local cases=0
local function test(name,fn)
    fn();cases=cases+1;print('PASS '..name)
end
local function empty()
    local d={Size={X=2,Y=4,Z=2}}
    for _,name in ipairs(names) do
        d[name]={Size={X=2,Y=4,Z=2}}
        for x=1,2 do
            d[name][x]={}
            for y=1,4 do d[name][x][y]={name=='SolidMaterial' and 'Air' or 0,name=='SolidMaterial' and 'Air' or 0} end
        end
    end
    d.SolidMaterial[1][1][1]='Rock';d.SolidOccupancy[1][1][1]=1
    d.SolidMaterial[1][4][1]='Rock';d.SolidOccupancy[1][4][1]=.5 -- cavity below
    d.LiquidOccupancy[2][2][2]=.6
    return d
end
local function inputs()
    local before=empty();local after=V.copy(before,2,4,2)
    V.fillEmpty(after,1,2,4,0,0,6,'Ground','Air')
    return before,after
end
local function engine(before,settings)
    settings=settings or {}
    local e={state=V.copy(before,2,4,2),writes=0,reads=0,frames=0,restores=0,diagnostics={}}
    local function set(d,restoring)
        for k in pairs(d) do assert(allowed[k],"Unknown channel id '"..k.."'") end
        for _,name in ipairs(names) do
            assert(d[name].Size==nil,'Array metadata leaked')
            assert(type(d[name])=='table')
        end
        e.writes=e.writes+1
        if restoring then e.restores=e.restores+1 end
        if e.writes==settings.failWrite then error('Injected write error') end
        e.state=V.copy(d,2,4,2)
        if e.writes==settings.corruptWrite then
            local channel=settings.channel or 'SolidOccupancy'
            e.state[channel][1][4][1]=settings.value or .2
        end
    end
    local a={context='tile X=-2048 Y=-256 Z=-1344'}
    a.write=function(d) set(d,false) end
    a.read=function()
        e.reads=e.reads+1
        local d=V.copy(e.state,2,4,2)
        if e.reads<=(settings.staleReads or 0) then d=V.copy(before,2,4,2) end
        d.Size={X=2,Y=4,Z=2}
        return d
    end
    a.waitFrame=function()
        e.frames=e.frames+1
        if settings.timeout then error('Repair budget exceeded') end
    end
    a.restore=function(d)
        assert(not settings.worldChanged,'World changed; refusing rollback into a different world')
        set(d,true)
    end
    a.restoreWaitFrame=function() e.frames=e.frames+1 end
    a.onMismatch=function(phase,detail)
        e.diagnostics[#e.diagnostics+1]={phase=phase,detail=detail}
        if settings.loggerError then error('Logger failed') end
    end
    return e,a
end
local function commit(mod,a,b,c)
    return pcall(mod.commit,a,b,c,{{IX=1,IZ=1},{IX=2,IZ=2}},2,4,2,'Air')
end
if old then test('original 0.2 reproduces Size rollback error',function()
    local b,c=inputs();local e,a=engine(b,{corruptWrite=2})
    local ok,err=commit(old,a,b,c)
    assert(not ok and err:find("Unknown channel id 'Size'",1,true),err)
    assert(err:find('tileRestored=false',1,true),err)
end) end

test('successful write strips root and nested Size metadata',function()
    local b,c=inputs();c.Size={X=2,Y=4,Z=2}
    local e,a=engine(b);local ok,err=commit(V,a,b,c);assert(ok,err)
    assert(e.writes==2 and e.frames==2 and e.restores==0)
    assert(V.equal(c,e.state,2,4,2,0));assert(b.Size and c.Size)
    assert(b.SolidOccupancy[1][2][2]==0,'Original mutated')
    assert(e.state.SolidOccupancy[1][2][1]==0,'Cave filled')
    assert(e.state.LiquidOccupancy[2][2][2]==.6,'Native water lost')
end)
test('write failure restores original channels with Size present',function()
    local b,c=inputs();local e,a=engine(b,{failWrite=2})
    local ok,err=commit(V,a,b,c)
    assert(not ok and err:find('tileRestored=true',1,true),err)
    assert(e.restores==1 and V.equal(b,e.state,2,4,2,0))
end)
test('readback corruption is NOT ignored; coordinates reported',function()
    local b,c=inputs();local e,a=engine(b,{corruptWrite=2})
    local ok,err=commit(V,a,b,c)
    assert(not ok and err:find('tileRestored=true',1,true),err)
    assert(err:find('channel=SolidOccupancy cell=(1,4,1)',1,true),err)
    assert(err:find('tile X=-2048',1,true),err)
    assert(e.reads==4 and #e.diagnostics==1 and V.equal(b,e.state,2,4,2,0))
    assert(e.diagnostics[1].detail.expected.solid==.5)
    assert(e.diagnostics[1].detail.actual.solid==.2)
end)
test('material mismatch still fails even at zero occupancy',function()
    local b,c=inputs();c.SolidMaterial[2][4][2]='Sand'
    local same,d=V.equal(b,c,2,4,2,1/255+.00001)
    -- use identical arrays except the empty-cell material
    local x=V.copy(b,2,4,2);x.SolidMaterial[2][4][2]='Sand'
    same,d=V.equal(b,x,2,4,2,1/255+.00001)
    assert(not same and d.channel=='SolidMaterial')
end)
test('bounded stale read succeeds without another write',function()
    local b,c=inputs();local e,a=engine(b,{staleReads=2})
    local ok,err=commit(V,a,b,c);assert(ok,err)
    assert(e.reads==3 and e.writes==2 and #e.diagnostics==0)
end)
test('deadline cannot suppress restoration',function()
    local b,c=inputs();local e,a=engine(b,{timeout=true})
    local ok,err=commit(V,a,b,c)
    assert(not ok and err:find('tileRestored=true',1,true),err)
    assert(e.restores==1 and V.equal(b,e.state,2,4,2,0))
end)
test('diagnostic callback failure cannot suppress restoration',function()
    local b,c=inputs();local e,a=engine(b,{corruptWrite=2,loggerError=true})
    local ok,err=commit(V,a,b,c)
    assert(not ok and err:find('tileRestored=true',1,true),err)
    assert(V.equal(b,e.state,2,4,2,0))
end)
test('world replacement refuses rollback into another world',function()
    local b,c=inputs();local e,a=engine(b,{failWrite=2,worldChanged=true})
    local ok,err=commit(V,a,b,c)
    assert(not ok and err:find('tileRestored=false',1,true),err)
    assert(err:find('World changed',1,true),err)
    assert(e.restores==0)
end)
test('invalid occupancies cannot pass verification',function()
    local b=empty()
    for _,value in ipairs({0/0,math.huge,-.1,1.1}) do
        local c=V.copy(b,2,4,2);c.SolidOccupancy[1][4][1]=value
        assert(not V.equal(b,c,2,4,2,.01))
    end
end)
test('old occupancy tolerance unchanged; larger drift rejected',function()
    local b=empty();local c=V.copy(b,2,4,2)
    c.SolidOccupancy[1][4][1]=.5+1/255
    assert(V.equal(b,c,2,4,2,1/255+.00001))
    c.SolidOccupancy[1][4][1]=.5+.01
    assert(not V.equal(b,c,2,4,2,1/255+.00001))
end)
test('malformed payload is rejected before any write',function()
    local b,c=inputs();c.LiquidOccupancy=nil
    local e,a=engine(b);local ok=commit(V,a,b,c)
    assert(not ok and e.writes==0)
end)
print('VOXEL IO REGRESSION: '..cases..' cases passed; simulated API only.')

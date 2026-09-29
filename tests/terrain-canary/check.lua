local file=assert(io.open(assert(os.getenv('CANARY_ROOT'))..'/tools/terrain-canary/TEST_TERRAIN_S3.lua','r'))
local source=file:read('*a');file:close()
local policy=assert(source:match('local Policy = %(function%(%)\n(.-)\nend%)%(%)'))
local P=assert(load(policy))() -- Only pure array logic is executed, never the Studio command.
local size={X=1,Y=4,Z=1}
local AIR,SAND,ROCK='Air','Sand','Rock'
local function original()
    return {Size=size,OtherMetadata='not writable',
        SolidMaterial={{{SAND},{AIR},{ROCK},{AIR}}},
        SolidOccupancy={{{1},{0},{0.5},{0}}},
        LiquidOccupancy={{{1},{0},{0.8},{1}}}}
end
local cases=0
local function test(name,fn) fn();cases=cases+1;print('PASS '..name) end
local function equal(a,b) assert(P.equal(a,b,size,0)) end
local function engine(start)
    local e={state=P.copy(start,size),writes=0,waits=0}
    function e.read() local out=P.copy(e.state,size);out.Size=size;return out end
    function e.write(d)
        for k in pairs(d) do assert(k=='SolidMaterial' or k=='SolidOccupancy' or k=='LiquidOccupancy','Unknown channel '..k) end
        e.writes=e.writes+1
        e.state=P.canonical(d,size,AIR)
    end
    e.restore=e.write
    function e.waitWrite() e.waits=e.waits+1 end
    e.waitRestore=e.waitWrite
    return e
end
test('normalize only full solid plus liquid',function()
    local c,n=P.canonical(original(),size,AIR)
    assert(n==1 and c.LiquidOccupancy[1][1][1]==0)
    assert(c.LiquidOccupancy[1][3][1]==0.8 and c.LiquidOccupancy[1][4][1]==1)
    assert(c.SolidOccupancy[1][3][1]==0.5 and c.SolidMaterial[1][1][1]==SAND)
end)
test('snapshot stays raw and detached; no Size written',function()
    local a=original();local c=P.canonical(a,size,AIR)
    assert(a.LiquidOccupancy[1][1][1]==1 and a.Size==size and c.Size==nil and c.OtherMetadata==nil)
    c.SolidMaterial[1][1][1]=ROCK;assert(a.SolidMaterial[1][1][1]==SAND)
end)
test('roundtrip preserves geometry, cavities and visible liquid',function()
    local a=original();local e=engine(a);local c=P.canonical(a,size,AIR)
    local r=P.roundTrip(e,a,size,AIR)
    assert(e.writes==2 and r.canonicalReadback and r.normalizedFullSolidLiquidCells==1 and not r.rawBitIdentityClaimed)
    equal(c,e.state);assert(e.state.SolidOccupancy[1][2][1]==0)
end)
test('reject changed preflight without write',function()
    local a=original();local e=engine(a);e.state.SolidOccupancy[1][2][1]=0.6
    assert(not pcall(P.roundTrip,e,a,size,AIR) and e.writes==0)
end)
test('NaN rejected before write',function()
    local a=original();a.SolidOccupancy[1][1][1]=0/0
    assert(not pcall(P.canonical,a,size,AIR))
end)
test('out of range and missing channels rejected',function()
    local a=original();a.LiquidOccupancy[1][1][1]=2
    assert(not pcall(P.canonical,a,size,AIR))
    a=original();a.SolidMaterial=nil;assert(not pcall(P.canonical,a,size,AIR))
end)
test('write error restores canonical data and reports failure',function()
    local a=original();local e=engine(a);local write=e.write;local calls=0
    e.write=function(d) calls=calls+1;if calls==2 then error('injected final write') end;write(d) end
    local ok,err=pcall(P.roundTrip,e,a,size,AIR)
    assert(not ok and string.find(err,'canonicalTileRestored=true',1,true));equal(P.canonical(a,size,AIR),e.state)
end)
test('material change not excused by liquid normalization',function()
    local a=original();local e=engine(a);local write=e.write;local calls=0
    e.write=function(d) calls=calls+1;write(d);if calls==2 then e.state.SolidMaterial[1][1][1]=ROCK end end
    local ok,err=pcall(P.roundTrip,e,a,size,AIR)
    assert(not ok and string.find(err,'SolidMaterial',1,true));equal(P.canonical(a,size,AIR),e.state)
end)
test('visible liquid loss rejected; fallback restore verified',function()
    local a=original();local e=engine(a);local write=e.write;local calls=0
    e.write=function(d) calls=calls+1;write(d);if calls==2 then e.state.LiquidOccupancy[1][3][1]=0 end end
    local ok,err=pcall(P.roundTrip,e,a,size,AIR)
    assert(not ok and string.find(err,'LiquidOccupancy',1,true));equal(P.canonical(a,size,AIR),e.state)
end)
test('restoration failure never reported as success',function()
    local a=original();local e=engine(a);e.write=function() error('write failed') end;e.restore=e.write
    local ok,err=pcall(P.roundTrip,e,a,size,AIR)
    assert(not ok and string.find(err,'canonicalTileRestored=false',1,true))
end)
test('wait failure does not skip restoration',function()
    local a=original();local e=engine(a);e.waitWrite=function() error('timeout') end
    local ok,err=pcall(P.roundTrip,e,a,size,AIR)
    assert(not ok and string.find(err,'canonicalTileRestored=true',1,true));equal(P.canonical(a,size,AIR),e.state)
end)
test('bounded deferred readback accepted without another clear',function()
    local a=original();local e=engine(a);local read=e.read;local calls=0
    e.read=function() calls=calls+1;if calls==2 then return P.copy(a,size) end;return read() end
    assert(P.roundTrip(e,a,size,AIR).canonicalReadback and e.writes==2)
end)
test('near full solid is not silently treated as full',function()
    local a=original();a.SolidOccupancy[1][1][1]=0.999
    local c,n=P.canonical(a,size,AIR);assert(n==0 and c.LiquidOccupancy[1][1][1]==1)
end)
print('RESULT '..cases..' cases; Lua 5.4 mocks only; Roblox not executed')

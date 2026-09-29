"""Local parser and mathematical checks; NOT Roblox engine tests."""
from pathlib import Path
import ctypes as C, json, hashlib, numpy as np
from collections import deque
root=Path(__file__).resolve().parents[1]
lua=C.CDLL('liblua5.4.so.0')
lua.luaL_newstate.restype=C.c_void_p
lua.luaL_openlibs.argtypes=[C.c_void_p]
lua.luaL_loadbufferx.argtypes=[C.c_void_p,C.c_char_p,C.c_size_t,C.c_char_p,C.c_char_p]
lua.lua_pcallk.argtypes=[C.c_void_p,C.c_int,C.c_int,C.c_int,C.c_longlong,C.c_void_p]
lua.lua_tolstring.argtypes=[C.c_void_p,C.c_int,C.POINTER(C.c_size_t)];lua.lua_tolstring.restype=C.c_char_p
lua.lua_settop.argtypes=[C.c_void_p,C.c_int]
lua.lua_close.argtypes=[C.c_void_p]
L=lua.luaL_newstate();lua.luaL_openlibs(L)
def load(src,name,execute=False):
 b=src.encode(); rc=lua.luaL_loadbufferx(L,b,len(b),name.encode(),None)
 if rc:raise AssertionError(lua.lua_tolstring(L,-1,None).decode())
 if execute:
  rc=lua.lua_pcallk(L,0,1,0,0,None)
  if rc:raise AssertionError(lua.lua_tolstring(L,-1,None).decode())
  result=lua.lua_tolstring(L,-1,None).decode()
 else:result=None
 lua.lua_settop(L,0);return result
files=list((root/'modules').glob('*.lua'))+list((root/'exports_studio').glob('*.txt'))+list(root.glob('*.txt'))
count=0
for p in files:
 if p.name in ['BUILD_IN_EMPTY_PLACE.txt','SCAN_WORLD_V4.txt'] or p.parent.name in ['modules','exports_studio']:
  load(p.read_text(),p.name);count+=1
script=f'''package.path={json.dumps(str(root/'modules/?.lua'))}..';'..package.path
local L=require('Layout');local F=require('HeightField');local ids=F.validate(L)
local rows={{}};local points=0
for z=L.Bounds[2],L.Bounds[4],64 do
 local row={{}}
 for x=L.Bounds[1],L.Bounds[3],64 do
  local y=F.sample(L,x,z);assert(y==y and y>L.BottomY and y<L.TopY);points=points+1
  table.insert(row,y>L.SeaY and '1' or '0')
 end
 table.insert(rows,table.concat(row))
end
-- Centre du detroit et pourtour: eau partout dans ce modele numerique.
for z=L.Bounds[2],L.Bounds[4],16 do assert(F.sample(L,0,z)<L.SeaY) end
for x=L.Bounds[1],L.Bounds[3],16 do
 assert(F.sample(L,x,L.Bounds[2])<L.SeaY);assert(F.sample(L,x,L.Bounds[4])<L.SeaY)
end
for z=L.Bounds[2],L.Bounds[4],16 do
 assert(F.sample(L,L.Bounds[1],z)<L.SeaY);assert(F.sample(L,L.Bounds[3],z)<L.SeaY)
end
for _,p in ipairs(L.Links) do
 local a,b=ids[p[1]],ids[p[2]]
 for i=0,200 do assert(F.sample(L,a.X+(b.X-a.X)*i/200,a.Z+(b.Z-a.Z)*i/200)>L.SeaY) end
end
return table.concat(rows,'\\n')
'''
text=load(script,'field tests',True)
a=np.array([[c=='1' for c in row] for row in text.splitlines()]);seen=np.zeros_like(a);sizes=[]
for y,x in np.argwhere(a):
 if seen[y,x]:continue
 seen[y,x]=True;q=deque([(y,x)]);n=0
 while q:
  py,px=q.popleft();n+=1
  for ny,nx in ((py-1,px),(py+1,px),(py,px-1),(py,px+1)):
   if 0<=ny<a.shape[0] and 0<=nx<a.shape[1] and a[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;q.append((ny,nx))
 sizes.append(n)
assert len(sizes)==2, sizes
from lxml import etree as E
xml=E.parse(str(root/'ValbrumeWorldV4Tools.rbxmx'))
embedded=xml.xpath('//Item[@class="ModuleScript"]')
for node in embedded:
 name=node.find('Properties/string').text
 source=node.find('Properties/ProtectedString').text
 assert source==(root/'modules'/f'{name}.lua').read_text()
report={'syntax_common_lua_luau_files':count,'field_samples':int(a.size),'land_components_64stud_grid':len(sizes),'land_component_sample_counts':sizes,'intercontinent_water_strip_checked':True,'ocean_boundary_checked':True,'candidate_link_field_samples':2010,'embedded_modules_exact':len(embedded),'roblox_engine_executed':False,'native_export_import_tested_in_studio':False,'render_collision_mobile_tests':False}
(root/'tests/LOCAL_RESULTS.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2));lua.lua_close(L)

"""Compile shared Lua/Luau syntax and run pure logic tests using Lua 5.4, NOT Roblox."""
from pathlib import Path
import ctypes,os,json
r=Path(__file__).resolve().parents[2]
os.environ['CANARY_ROOT']=str(r)
l=ctypes.CDLL('liblua5.4.so.0')
l.luaL_newstate.restype=ctypes.c_void_p
l.luaL_openlibs.argtypes=[ctypes.c_void_p]
l.luaL_loadfilex.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p];l.luaL_loadfilex.restype=ctypes.c_int
l.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p];l.lua_pcallk.restype=ctypes.c_int
l.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];l.lua_tolstring.restype=ctypes.c_char_p
l.lua_close.argtypes=[ctypes.c_void_p]
def run(file, execute=False):
 s=l.luaL_newstate();l.luaL_openlibs(s)
 code=l.luaL_loadfilex(s,str(file).encode(),None)
 if not code and execute:code=l.lua_pcallk(s,0,0,0,0,None)
 error=l.lua_tolstring(s,-1,None).decode() if code else None
 l.lua_close(s)
 if error:raise AssertionError(error)
for name in ('TEST_TERRAIN_S3.lua',):
 run(r/'tools/terrain-canary'/name)
run(Path(__file__).with_name('check.lua'),True)
print('Standalone syntax accepted; 13 pure-policy cases. Roblox execution pending')

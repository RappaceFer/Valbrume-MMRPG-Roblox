"""Requires liblua5.4. Tests common Lua syntax, not the Roblox engine or Luau compiler."""
import ctypes, ctypes.util, os
from pathlib import Path
root=Path(__file__).resolve().parents[2]
os.environ['VALBRUME_LANDSCAPE_ROOT']=str(root)
lib=ctypes.CDLL(ctypes.util.find_library('lua5.4') or 'liblua5.4.so.0')
lib.luaL_newstate.restype=ctypes.c_void_p
lib.luaL_openlibs.argtypes=[ctypes.c_void_p]
lib.luaL_loadfilex.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p]
lib.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lib.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];lib.lua_tolstring.restype=ctypes.c_char_p
lib.lua_close.argtypes=[ctypes.c_void_p]
state=lib.luaL_newstate();lib.luaL_openlibs(state)
try:
 code=lib.luaL_loadfilex(state,str(Path(__file__).with_name('check.lua')).encode(),None)
 if not code: code=lib.lua_pcallk(state,0,-1,0,0,None)
 if code: raise RuntimeError(lib.lua_tolstring(state,-1,None).decode())
finally: lib.lua_close(state)

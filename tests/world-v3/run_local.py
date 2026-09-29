#!/usr/bin/env python3
"""Run portable Lua syntax/algorithm tests. NOT a Roblox/Luau-engine playtest.
Requires an installed Lua 5.4 shared library (Linux), no third-party Python package.
The production sources deliberately use syntax shared by Lua 5.4 and Luau.
"""
import argparse, ctypes, ctypes.util, importlib.util, json, pathlib, subprocess, sys, tempfile, zipfile
root = pathlib.Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser()
parser.add_argument('--baseline-zip',type=pathlib.Path)
args=parser.parse_args()
libname = ctypes.util.find_library('lua5.4')
if not libname:
    sys.exit('Lua 5.4 shared library missing. This runner does not install dependencies.')
lua = ctypes.CDLL(libname)
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadbufferx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate(); lua.luaL_openlibs(state)
def check(text: str, name: str, run: bool = False):
    raw = text.encode('utf-8')
    status = lua.luaL_loadbufferx(state, raw, len(raw), name.encode(), None)
    if not status and run:
        status = lua.lua_pcallk(state, 0, 0, 0, 0, None)
    if status:
        raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
    lua.lua_settop(state, 0)
try:
    sources = sorted((root/'src/ServerScriptService/ValbrumeServer/WorldV3').glob('*.lua'))
    sources += [root/'src/ServerScriptService/ValbrumeServer/OpenWorldContinentsV28.server.lua']
    sources += sorted((root/'tools/world-v3').glob('*.lua'))
    for path in sources: check(path.read_text(), str(path))
    print(f'PASS: shared Lua/Luau syntax subset ({len(sources)} files)', flush=True)
    check('ROOT = '+repr(str(root)), 'root', True)
    check((root/'tests/world-v3/geometry.lua').read_text(), 'geometry tests', True)
    check((root/'tests/world-v3/voxel_mock.lua').read_text(), 'voxel mock', True)
    spec=importlib.util.spec_from_file_location('release_builder',root/'tools/world-v3/build_release.py')
    builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
    fixtures=[]
    deps=json.loads((root/'tools/world-v3/dependencies.json').read_text())
    archive=zipfile.ZipFile(args.baseline_zip) if args.baseline_zip else None
    try:
        for dep in deps:
            suffix={'Script':'.server.lua','LocalScript':'.client.lua','ModuleScript':'.lua'}[dep['Class']]
            path='src/'+'/'.join(dep['Path'])+suffix
            raw=archive.read(path) if archive else subprocess.check_output(
                ['git','show','48ad1734abc0e94463a94fa4e2f4a2b6f5d41be8:'+path],cwd=root)
            fixtures.append({'Path':dep['Path'],'Class':dep['Class'],'Source':raw.decode('utf-8')})
    finally:
        if archive: archive.close()
    with tempfile.TemporaryDirectory() as tmp:
        release=pathlib.Path(tmp)/'release'
        subprocess.run([sys.executable,str(root/'tools/world-v3/build_release.py'),'--output',str(release)],check=True,stdout=subprocess.DEVNULL)
        for path in release.glob('*.lua'):check(path.read_text(),str(path))
        print('PASS: all 3 generated Command Bar files parse',flush=True)
        check('RELEASE='+builder.lua(str(release))+'\nSOURCE_FIXTURES='+builder.lua(fixtures),'installer fixtures',True)
        check((root/'tests/world-v3/installer_mock.lua').read_text(),'installer mock',True)
finally:
    lua.lua_close(state)

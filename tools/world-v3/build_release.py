#!/usr/bin/env python3
"""Build offline Studio installer from checked-in sources. Python 3, stdlib only.
Usage: python tools/world-v3/build_release.py --output /path/to/release
No network access, no upload, no credentials. Generated payloads are not executables
for Python: they are text for Studio's Command Bar. Review the manifest before use.
"""
import argparse, hashlib, json, pathlib, zipfile
ROOT = pathlib.Path(__file__).resolve().parents[2]
VERSION = '3.1.0'
PREFIX = pathlib.Path('src/ServerScriptService/ValbrumeServer')

def blob_hash(text: str) -> str:
    raw = text.replace('\r\n','\n').encode('utf-8')
    return hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()

def lua_string(s: str) -> str:
    # Lua long strings skip an immediate initial newline; prefix a newline explicitly.
    for n in range(1, 20):
        eq = '=' * n
        if ']' + eq + ']' not in s:
            return '['+eq+'[\n'+s+']'+eq+']'
    raise ValueError('No safe Lua string delimiter')

def lua(value):
    if isinstance(value,str): return lua_string(value)
    if isinstance(value,list): return '{'+','.join(map(lua,value))+'}'
    if isinstance(value,dict): return '{'+','.join('[ '+lua(k)+' ]='+lua(v) for k,v in value.items())+'}'
    raise TypeError(type(value))

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',type=pathlib.Path,required=True)
    args=parser.parse_args(); out=args.output;out.mkdir(parents=True,exist_ok=True)
    runtime=[PREFIX/'OpenWorldContinentsV28.server.lua']+sorted((PREFIX/'WorldV3'/p.name for p in (ROOT/PREFIX/'WorldV3').glob('*.lua')))
    payload=[]
    for path in runtime:
        text=(ROOT/path).read_text(encoding='utf-8')
        bootstrap=path.name.endswith('.server.lua')
        payload.append({'Name':'OpenWorldContinentsV28' if bootstrap else path.stem,
            'Class':'Script' if bootstrap else 'ModuleScript',
            'Kind':'bootstrap' if bootstrap else 'module','Source':text,'Hash':blob_hash(text)})
    dependencies=json.loads((ROOT/'tools/world-v3/dependencies.json').read_text())
    for d in dependencies:
        if d['Path'][-1]=='OpenWorldContinentsV28': d['Hashes'].append(payload[0]['Hash'])
    hashing=(ROOT/'tools/world-v3/GitBlobHash.lua').read_text()
    hashing=hashing.removesuffix('return blobHash\n')
    heading='-- Generated offline from the World V3.1 release. Do not edit the payload.\n'
    install=heading+'local VERSION='+lua(VERSION)+'\n'+hashing+'\nlocal DEPENDENCIES='+lua(dependencies)+'\nlocal PAYLOAD='+lua(payload)+'\n'+(ROOT/'tools/world-v3/Install.template.lua').read_text()
    installed=[{k:v for k,v in p.items() if k!='Source'} for p in payload]
    rollback=heading+'local VERSION='+lua(VERSION)+'\n'+hashing+'\nlocal INSTALLED='+lua(installed)+'\n'+(ROOT/'tools/world-v3/Rollback.template.lua').read_text()
    (out/'01_INSTALL_WORLD_V3_1.lua').write_text(install,encoding='utf-8')
    (out/'02_SCAN_WORLD_V3_1.lua').write_text((ROOT/'tools/world-v3/RunAudit.lua').read_text(),encoding='utf-8')
    (out/'03_ROLLBACK_WORLD_V3_1.lua').write_text(rollback,encoding='utf-8')
    meta={'version':VERSION,'files':[{'path':str(path),'gitBlobSha':p['Hash'],'class':p['Class']} for path,p in zip(runtime,payload)],
        'scope':'6 authored corridors; no gameplay rewrite; no asset pack imported',
        'runtimeValidation':'PENDING Roblox Studio Play and PC/mobile traversal'}
    (out/'RELEASE_MANIFEST.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n')
    if (ROOT/'docs/WORLD_V3_1_INSTALL.md').exists():
        (out/'LIRE_AVANT_INSTALLATION.md').write_text((ROOT/'docs/WORLD_V3_1_INSTALL.md').read_text())
    for path in runtime:
        dest=out/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes((ROOT/path).read_bytes())
    for name in ('01_INSTALL_WORLD_V3_1','02_SCAN_WORLD_V3_1','03_ROLLBACK_WORLD_V3_1'):
        (out/(name+'.txt')).write_bytes((out/(name+'.lua')).read_bytes())
    archive=out.parent/'Valbrume_World_V3_1.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for path in sorted(out.rglob('*')):
            if path.is_file(): z.write(path,path.relative_to(out))
    print(json.dumps({'payload_files':len(payload),'installer_bytes':len(install.encode()),'zip':str(archive)},indent=2))

if __name__=='__main__': main()

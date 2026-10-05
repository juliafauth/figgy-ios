#!/usr/bin/env python3
"""Structural validation. This does not type-check Swift or replace an Xcode build."""
from pathlib import Path
import plistlib,json,zipfile
from PIL import Image
from openstep_parser import OpenStepDecoder
from tree_sitter import Language,Parser
import tree_sitter_swift
R=Path(__file__).resolve().parents[1]
p=Parser(Language(tree_sitter_swift.language()))
files=list(R.rglob('*.swift'))
for f in files:
    t=p.parse(f.read_bytes())
    assert not t.root_node.has_error, f'Swift syntax error: {f}'
project=OpenStepDecoder.ParseFromFile(open(R/'Figgy.xcodeproj/project.pbxproj'))
objects=project['objects'];targets={o['name']:o for o in objects.values() if o.get('isa')=='PBXNativeTarget'}
assert set(targets)=={'Figgy','FiggyLocal','FiggyMessages','FiggyShare','FiggyTests'}
for o in objects.values():
    if o.get('isa')=='PBXFileReference' and o.get('sourceTree')=='<group>':
        assert (R/o['path']).exists(),o['path']
    if o.get('isa')=='PBXBuildFile':
        for k in ['fileRef','productRef']:
            if k in o:assert o[k] in objects
for f in (R/'Config').glob('*.plist'):plistlib.loads(f.read_bytes())
m=plistlib.loads((R/'Config/Messages-Info.plist').read_bytes())
assert 'MSMessagesAppPresentationContextMedia' in m['MSSupportedPresentationContexts']
assert m['NSExtension']['NSExtensionPointIdentifier']=='com.apple.message-payload-provider'
e=plistlib.loads((R/'Config/Figgy.entitlements').read_bytes())
assert e['com.apple.security.application-groups']==['$(FIGGY_APP_GROUP)']
assert not targets['FiggyLocal']['dependencies']
cat=json.loads((R/'Resources/Catalog/catalog.json').read_text())
assert len(cat)==3 and sum(len(i['files']) for i in cat)==18
for item in cat:
    assert len(item['files'])==len(item['titles'])
    for file in item['files']:
        path=R/'Resources/Catalog'/file
        assert path.stat().st_size<500_000
        with Image.open(path) as im:assert im.size==(512,512) and im.mode=='RGBA'
with zipfile.ZipFile(R/'Resources/Example.figpack') as z:
    m=json.loads(z.read('manifest.json'))
    assert m['format']=='figgy-pack' and len(m['stickers'])==3
    for s in m['stickers']:assert s['file'] in z.namelist()
print(f'PASS: {len(files)} Swift files parsed, {len(objects)} project objects, source paths, five targets, extension contexts, App Group configuration, 18 PNG assets, example portable pack.')

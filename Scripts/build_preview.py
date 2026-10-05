#!/usr/bin/env python3
from pathlib import Path
import json,base64,os
R=Path(__file__).resolve().parents[1]
cat=json.loads((R/'Resources/Catalog/catalog.json').read_text())
for item in cat:
    item['images']=['data:image/png;base64,'+base64.b64encode((R/'Resources/Catalog'/f).read_bytes()).decode() for f in item['files']]
icon='data:image/png;base64,'+base64.b64encode((R/'Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png').read_bytes()).decode()
jszip=Path(os.environ.get('CODEX_PRIMARY_RUNTIME_NODE_MODULES',''))/'jszip/dist/jszip.min.js'
if not jszip.is_file():raise SystemExit('Point CODEX_PRIMARY_RUNTIME_NODE_MODULES at a node_modules folder with jszip installed.')
html=(R/'Preview/template.html').read_text().replace('/*CATALOG*/',json.dumps(cat,ensure_ascii=False)).replace('/*ICON*/',json.dumps(icon)).replace('/*JSZIP*/',jszip.read_text().replace('</script','<\\/script'))
(R/'Preview/Figgy-Preview.html').write_text(html)
print('Built standalone preview: no external resources or server required.')

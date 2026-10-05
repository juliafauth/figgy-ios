#!/usr/bin/env python3
import argparse,re
from pathlib import Path
p=argparse.ArgumentParser(description='Configure all Figgy targets with one team and App Group.')
p.add_argument('--team',default='');p.add_argument('--bundle-prefix',default='com.julia')
a=p.parse_args()
if a.team and not re.fullmatch(r'[A-Z0-9]{10}',a.team):p.error('Team ID must have 10 uppercase letters/digits.')
if not re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z][A-Za-z0-9-]*)+',a.bundle_prefix):p.error('Use a reverse-domain prefix, such as com.juliafauth.')
file=Path(__file__).resolve().parents[1]/'Config'/'Signing.xcconfig'
file.write_text(f'FIGGY_TEAM = {a.team}\nFIGGY_BUNDLE_PREFIX = {a.bundle_prefix}\nFIGGY_APP_GROUP = group.{a.bundle_prefix}.figgy\n')
print('Signing configuration updated for all targets.')

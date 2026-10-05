#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null; then
    echo 'Execute este script no Mac com Xcode instalado.'
    exit 1
fi
mkdir -p build/logs
simulator_id=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
devices=json.load(sys.stdin)["devices"]
for runtime,items in sorted(devices.items(), reverse=True):
    if "iOS" in runtime:
        for device in items:
            if device.get("isAvailable") and device["name"].startswith("iPhone"):
                print(device["udid"]);sys.exit(0)
sys.exit("Nenhum simulador iPhone disponível.")
')
xcodebuild -project Figgy.xcodeproj -scheme Figgy -configuration Debug \
    -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath build/SimulatorDerivedData -clonedSourcePackagesDirPath build/SourcePackages \
    -resultBundlePath build/FiggyTests.xcresult \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= DEVELOPMENT_TEAM= \
    test 2>&1 | tee build/logs/tests.log

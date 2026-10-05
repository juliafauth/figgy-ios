#!/bin/bash
# Runs on the GitHub macOS runner. Apple credentials are supplied only to AltStore.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != "Darwin" ]] || ! command -v xcodebuild >/dev/null; then
    echo 'Este script precisa do Xcode no macOS. No Windows, execute-o pelo GitHub Actions.' >&2
    exit 1
fi
mkdir -p build/logs
xcodebuild -version | tee build/logs/xcode-version.txt
xcodebuild -project Figgy.xcodeproj -scheme Figgy -configuration Release \
    -sdk iphoneos -destination 'generic/platform=iOS' \
    -derivedDataPath build/DeviceDerivedData -clonedSourcePackagesDirPath build/SourcePackages \
    -archivePath build/Figgy.xcarchive \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= DEVELOPMENT_TEAM= \
    archive 2>&1 | tee build/logs/archive.log

# Preserve capabilities for AltStore to discover and provision. These ad-hoc
# signatures do not authorize installation on an iPhone; AltStore replaces them.
python3 Scripts/package_ipa.py build/Figgy.xcarchive build/Figgy.ipa 2>&1 | tee build/logs/package.log
python3 Scripts/verify_ipa.py build/Figgy.ipa 2>&1 | tee build/logs/verify-ipa.log
shasum -a 256 build/Figgy.ipa > build/Figgy.ipa.sha256

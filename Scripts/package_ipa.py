#!/usr/bin/env python3
"""Package an Xcode archive for AltStore, keeping the app and both extensions."""
import argparse
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile


def package(archive: Path, output: Path) -> None:
    if sys.platform != "darwin":
        raise RuntimeError("O empacotamento precisa das ferramentas codesign e ditto do macOS.")
    source = archive / "Products/Applications/Figgy.app"
    if not source.is_dir():
        raise RuntimeError("Figgy.app não foi encontrado no archive. Confira o log do Xcode.")
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="figgy-ipa-") as temp:
        stage = Path(temp)
        payload = stage / "Payload"
        app = payload / "Figgy.app"
        payload.mkdir()
        subprocess.run(["ditto", str(source), str(app)], check=True)
        with (app / "Info.plist").open("rb") as f:
            info = plistlib.load(f)
        group = info.get("FiggyAppGroup", "")
        if not re.fullmatch(r"group\.[A-Za-z0-9.-]+", group):
            raise RuntimeError("O archive não resolveu FIGGY_APP_GROUP em Info.plist.")
        entitlements = stage / "Figgy.entitlements"
        entitlements.write_bytes(plistlib.dumps({"com.apple.security.application-groups": [group]}))
        extensions = sorted((app / "PlugIns").glob("*.appex"))
        if {p.name for p in extensions} != {"FiggyMessages.appex", "FiggyShare.appex"}:
            raise RuntimeError("As duas extensões precisam estar no archive.")
        for extension in extensions:
            with (extension / "Info.plist").open("rb") as f:
                if plistlib.load(f).get("FiggyAppGroup") != group:
                    raise RuntimeError("Os três componentes precisam usar o mesmo App Group.")
        libraries = sorted(app.rglob("*.dylib")) + sorted(app.rglob("*.framework"), key=lambda p: len(p.parts), reverse=True)
        for library in libraries:
            subprocess.run(["codesign", "--force", "--sign", "-", str(library)], check=True)
        for bundle in extensions + [app]:
            subprocess.run(["codesign", "--force", "--sign", "-", "--entitlements", str(entitlements),
                            "--generate-entitlement-der", str(bundle)], check=True)
            subprocess.run(["codesign", "--verify", "--strict", str(bundle)], check=True)
            signed = subprocess.run(["codesign", "--display", "--entitlements", "-", "--xml", str(bundle)],
                                    check=True, capture_output=True).stdout
            if plistlib.loads(signed).get("com.apple.security.application-groups") != [group]:
                raise RuntimeError("A assinatura não preservou o App Group.")
        candidate = stage / "Figgy.ipa"
        subprocess.run(["ditto", "-c", "-k", "--norsrc", "--keepParent", str(payload), str(candidate)], check=True)
        shutil.copyfile(candidate, output)
        print(f"IPA pronto para ser assinado pelo AltStore: {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    package(args.archive, args.output)

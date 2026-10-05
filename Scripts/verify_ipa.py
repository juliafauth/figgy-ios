#!/usr/bin/env python3
"""Check the archive layout before publishing the IPA as a build artifact."""
import argparse
from pathlib import Path
import plistlib
import zipfile


def verify(path: Path) -> None:
    app = "Payload/Figgy.app/"
    components = [app, app + "PlugIns/FiggyMessages.appex/", app + "PlugIns/FiggyShare.appex/"]
    with zipfile.ZipFile(path) as archive:
        names = set(archive.namelist())
        if not all(n.startswith("Payload/") for n in names):
            raise ValueError("O IPA deve conter somente Payload na raiz.")
        groups = []
        identifiers = []
        for component in components:
            info = plistlib.loads(archive.read(component + "Info.plist"))
            identifier = info["CFBundleIdentifier"]
            executable = component + info["CFBundleExecutable"]
            if executable not in names or archive.getinfo(executable).file_size == 0:
                raise ValueError("Executável ausente: " + executable)
            if component + "_CodeSignature/CodeResources" not in names:
                raise ValueError("Assinatura ad-hoc ausente: " + component)
            if "$" in identifier:
                raise ValueError("Identificador do bundle não resolvido.")
            groups.append(info["FiggyAppGroup"])
            identifiers.append(identifier)
        if len(set(groups)) != 1 or not groups[0].startswith("group."):
            raise ValueError("O App Group precisa ser igual nos três bundles.")
        if not all(i.startswith(identifiers[0] + ".") for i in identifiers[1:]):
            raise ValueError("Identificadores de extensão inconsistentes.")
        messages = plistlib.loads(archive.read(components[1] + "Info.plist"))
        if "MSMessagesAppPresentationContextMedia" not in messages.get("MSSupportedPresentationContexts", []):
            raise ValueError("Contexto media da extensão Messages ausente.")
        if archive.testzip() is not None:
            raise ValueError("Arquivo corrompido no IPA.")
    print("PASS: Payload, executáveis, duas extensões, assinaturas ad-hoc, App Group e contexto media.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("ipa", type=Path)
    verify(parser.parse_args().ipa)

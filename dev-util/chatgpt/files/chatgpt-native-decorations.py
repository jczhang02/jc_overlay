#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

"""Enable Linux system decorations, including safe theme and zoom updates.

Upstream request: https://github.com/openai/codex/issues/38595
Exact matches deliberately reject upstream changes for review on version bumps.
"""

import argparse
import importlib.util
import json
from pathlib import Path
import shutil
import stat
import tempfile


spec = importlib.util.spec_from_file_location(
    "cmaps", Path(__file__).with_name("chatgpt-pdf-cmaps.py")
)
cmaps = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cmaps)

REPLACEMENTS = (
    (
        b'n===`win32`||n===`linux`?{titleBarStyle:`hidden`,titleBarOverlay:k9(r)',
        b'n===`win32`?{titleBarStyle:`hidden`,titleBarOverlay:k9(r)',
    ),
    (
        b'case`detached`:return{titleBarStyle:`hidden`,titleBarOverlay:n===`darwin`||k9(r)}',
        b'case`detached`:return n===`linux`?{titleBarStyle:`default`}:{titleBarStyle:`hidden`,titleBarOverlay:n===`darwin`||k9(r)}',
    ),
    (
        b'(process.platform===`win32`||process.platform===`linux`)&&(this.windowZooms.set(n.id,t),n.setTitleBarOverlay(k9(t)))',
        b'(process.platform===`win32`)&&(this.windowZooms.set(n.id,t),n.setTitleBarOverlay(k9(t)))',
    ),
    (
        b'installApplicationMenuTitleBarOverlaySync(e,t){if(process.platform!==`win32`&&process.platform!==`linux`||',
        b'installApplicationMenuTitleBarOverlaySync(e,t){if(process.platform!==`win32`||',
    ),
)


def patch_script(data):
    for original, replacement in REPLACEMENTS:
        cmaps.require(data.count(original) == 1, "Unexpected native decoration patch target")
        data = data.replace(original, replacement)
    return data


def patch_archive(archive, version):
    with archive.open("rb") as source:
        header, start = cmaps.read_header(source)
        files = header["files"]
        app = json.loads(cmaps.read_entry(source, start, files["package.json"]))
        cmaps.require(app["version"] == version, "Unexpected ChatGPT version")
        entries = files[".vite"]["files"]["build"]["files"]
        candidates = [(name, entry) for name, entry in entries.items()
                      if name.startswith("main-") and name.endswith(".js")]
        cmaps.require(len(candidates) == 1, "Expected exactly one main bundle")
        name, entry = candidates[0]
        patched = patch_script(cmaps.read_entry(source, start, entry))
        entry.update(size=len(patched), offset=str(source.seek(0, 2) - start),
                     integrity=cmaps.integrity(patched, entry["integrity"]["blockSize"]))
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(dir=archive.parent, prefix=".native-decorations-",
                                             delete=False) as output:
                temporary = Path(output.name)
                output.write(cmaps.encode_header(header))
                source.seek(start)
                shutil.copyfileobj(source, output)
                output.write(patched)
            temporary.chmod(stat.S_IMODE(archive.stat().st_mode))
            temporary.replace(archive)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
    print(f"Patched {name}: Linux native window decorations")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("version")
    args = parser.parse_args()
    patch_archive(args.archive, args.version)

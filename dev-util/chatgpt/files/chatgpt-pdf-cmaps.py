#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

"""Add local CMaps to ChatGPT's bundled PDF.js without repacking native modules."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import stat
import struct
import tempfile


DEFAULT_CMAP = b"m=ge(e.cMapUrl)"
LOCAL_CMAP = b'm=ge(e.cMapUrl??new URL("./cmaps/",import.meta.url).href)'
BLOCK_SIZE = 4 * 1024 * 1024


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_header(stream):
    prefix = stream.read(16)
    require(len(prefix) == 16, "Truncated ASAR header")
    size, header_size, payload_size, json_size = struct.unpack("<4I", prefix)
    require(
        size == 4
        and header_size == payload_size + 4
        and payload_size == 4 + ((json_size + 3) // 4) * 4,
        "Unsupported ASAR header layout",
    )
    require(8 + header_size <= stream.seek(0, 2), "ASAR header exceeds archive")
    stream.seek(16)
    return json.loads(stream.read(json_size)), 8 + header_size


def encode_header(header):
    data = json.dumps(header, separators=(",", ":"), ensure_ascii=False).encode()
    padding = b"\0" * (-len(data) % 4)
    payload_size = 4 + len(data) + len(padding)
    return struct.pack("<4I", 4, payload_size + 4, payload_size, len(data)) + data + padding


def integrity(data, block_size=BLOCK_SIZE):
    require(isinstance(block_size, int) and block_size > 0, "Invalid ASAR block size")
    return {
        "algorithm": "SHA256",
        "hash": hashlib.sha256(data).hexdigest(),
        "blockSize": block_size,
        "blocks": [
            hashlib.sha256(data[start:start + block_size]).hexdigest()
            for start in range(0, len(data), block_size)
        ],
    }


def read_entry(stream, payload_start, entry):
    require("offset" in entry and not entry.get("unpacked"), "Expected a packed ASAR file")
    offset, size = int(entry["offset"]), entry["size"]
    require(offset >= 0 and isinstance(size, int) and size >= 0, "Invalid ASAR file range")
    require(payload_start + offset + size <= stream.seek(0, 2), "ASAR file exceeds archive")
    stream.seek(payload_start + offset)
    data = stream.read(size)
    recorded = entry["integrity"]
    require(recorded == integrity(data, recorded["blockSize"]), "ASAR file integrity mismatch")
    return data


def patch_archive(archive, package, app_version, pdfjs_version):
    resource_version = json.loads((package / "package.json").read_text())["version"]
    require(resource_version == pdfjs_version, "Unexpected pdfjs-dist resource version")
    cmaps = package / "cmaps"
    resources = sorted(cmaps.glob("*.bcmap")) + [cmaps / "LICENSE"]
    require(
        {"Adobe-GB1-UCS2.bcmap", "UniGB-UTF16-H.bcmap"}.issubset(p.name for p in resources),
        "Missing required Chinese CMaps",
    )
    require(all(p.is_file() and not p.is_symlink() for p in resources), "Invalid CMap resource")

    with archive.open("rb") as source:
        header, payload_start = read_header(source)
        files = header["files"]
        app = json.loads(read_entry(source, payload_start, files["package.json"]))
        require(app["version"] == app_version, "Unexpected ChatGPT version")
        assets = files["webview"]["files"]["assets"]["files"]
        require("cmaps" not in assets, "Upstream already contains CMaps; review this patch")

        candidates = []
        for name, entry in assets.items():
            if name.startswith("pdf-") and name.endswith(".js"):
                data = read_entry(source, payload_start, entry)
                if DEFAULT_CMAP in data:
                    candidates.append((name, entry, data))
        require(len(candidates) == 1, "Expected exactly one PDF.js CMap default")
        name, entry, data = candidates[0]
        require(data.count(DEFAULT_CMAP) == 1, "Ambiguous PDF.js CMap default")
        require(f'Or=`{pdfjs_version}`'.encode() in data, "Unexpected bundled PDF.js version")
        patched = data.replace(DEFAULT_CMAP, LOCAL_CMAP)

        # Retain the original payload and offsets. Only the changed JS and new
        # resources are appended; unpacked entries and their files stay intact.
        additions = [(entry, patched)]
        assets["cmaps"] = {"files": {}}
        for resource in resources:
            target = {}
            assets["cmaps"]["files"][resource.name] = target
            contents = resource.read_bytes()
            require(contents, f"Empty CMap resource: {resource.name}")
            additions.append((target, contents))
        offset = source.seek(0, 2) - payload_start
        for target, contents in additions:
            block_size = target.get("integrity", {}).get("blockSize", BLOCK_SIZE)
            target.update(size=len(contents), offset=str(offset), integrity=integrity(contents, block_size))
            offset += len(contents)

        temporary = None
        try:
            with tempfile.NamedTemporaryFile(dir=archive.parent, prefix=".pdf-cmaps-", delete=False) as output:
                temporary = Path(output.name)
                output.write(encode_header(header))
                source.seek(payload_start)
                shutil.copyfileobj(source, output)
                for _, contents in additions:
                    output.write(contents)
            temporary.chmod(stat.S_IMODE(archive.stat().st_mode))
            temporary.replace(archive)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
    print(f"Patched {name}; bundled {len(resources) - 1} CMaps and their license")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("package", type=Path)
    parser.add_argument("app_version")
    parser.add_argument("pdfjs_version")
    args = parser.parse_args()
    patch_archive(args.archive, args.package, args.app_version, args.pdfjs_version)


if __name__ == "__main__":
    main()

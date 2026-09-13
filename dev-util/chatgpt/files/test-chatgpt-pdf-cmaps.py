#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

"""Exercise ASAR preservation and failure handling without running ChatGPT."""

import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "cmaps", Path(__file__).with_name("chatgpt-pdf-cmaps.py")
)
cmaps = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cmaps)


def unpack(data):
    size, header_size, payload_size, json_size = struct.unpack("<4I", data[:16])
    assert size == 4 and header_size == payload_size + 4
    assert header_size % 4 == 0 and json_size <= payload_size - 4
    return json.loads(data[16:16 + json_size]), data[8 + header_size:]


def file_data(entry, payload):
    offset = int(entry["offset"])
    return payload[offset:offset + entry["size"]]


class PatchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.archive = self.root / "app.asar"
        self.package = self.root / "package"
        resources = self.package / "cmaps"
        resources.mkdir(parents=True)
        (self.package / "package.json").write_text('{"version":"5.4.296"}')
        for name in ("Adobe-GB1-UCS2.bcmap", "UniGB-UTF16-H.bcmap", "LICENSE"):
            (resources / name).write_bytes(b"fixture resource " + name.encode())
        self.native = self.root / "app.asar.unpacked/node_modules/native.node"
        self.native.parent.mkdir(parents=True)
        self.native.write_bytes(b"native module must remain untouched")
        self.native.chmod(0o755)
        self.make_archive()

    def make_archive(self, script=b"var Or=`5.4.296`;m=ge(e.cMapUrl);", duplicate=False):
        payload = bytearray()
        files = {}
        source_files = {
            "package.json": b'{"version":"26.901.41123"}',
            "webview/assets/pdf-test.js": script,
            "webview/assets/unchanged.bin": bytes(range(256)),
        }
        if duplicate:
            source_files["webview/assets/pdf-other.js"] = script
        for name, data in source_files.items():
            directory = files
            parts = name.split("/")
            for part in parts[:-1]:
                directory = directory.setdefault(part, {"files": {}})["files"]
            directory[parts[-1]] = {
                "size": len(data), "offset": str(len(payload)), "executable": True,
                "integrity": {
                    "algorithm": "SHA256", "hash": hashlib.sha256(data).hexdigest(),
                    "blockSize": 16,
                    "blocks": [hashlib.sha256(data[i:i + 16]).hexdigest() for i in range(0, len(data), 16)],
                },
            }
            payload.extend(data)
        files["node_modules"] = {"files": {
            "native.node": {"unpacked": True, "size": self.native.stat().st_size},
            "alias": {"link": "node_modules/native.node"},
        }}
        encoded = json.dumps({"files": files}).encode()
        encoded += b"\0" * (-len(encoded) % 4)
        length = len(json.dumps({"files": files}).encode())
        prefix = struct.pack("<4I", 4, len(encoded) + 8, len(encoded) + 4, length)
        self.archive.write_bytes(prefix + encoded + payload)
        self.archive.chmod(0o644)

    def apply(self, app_version="26.901.41123", pdfjs_version="5.4.296"):
        cmaps.patch_archive(self.archive, self.package, app_version, pdfjs_version)

    def assert_failure_unchanged(self, **kwargs):
        before = self.archive.read_bytes()
        with self.assertRaises((ValueError, OSError)):
            self.apply(**kwargs)
        self.assertEqual(before, self.archive.read_bytes())
        self.assertEqual([], list(self.root.glob(".pdf-cmaps-*")))

    def test_preserves_existing_payload_metadata_and_native_modules(self):
        original, old_payload = unpack(self.archive.read_bytes())
        native = self.native.read_bytes()
        self.apply()
        updated, payload = unpack(self.archive.read_bytes())
        self.assertTrue(payload.startswith(old_payload))
        self.assertEqual(original["files"]["node_modules"], updated["files"]["node_modules"])
        self.assertEqual(original["files"]["package.json"], updated["files"]["package.json"])
        self.assertEqual(native, self.native.read_bytes())
        self.assertEqual(0o755, self.native.stat().st_mode & 0o777)
        self.assertEqual(0o644, self.archive.stat().st_mode & 0o777)
        old_assets = original["files"]["webview"]["files"]["assets"]["files"]
        assets = updated["files"]["webview"]["files"]["assets"]["files"]
        self.assertEqual(old_assets["unchanged.bin"], assets["unchanged.bin"])
        entry = assets["pdf-test.js"]
        script = file_data(entry, payload)
        self.assertIn(b'new URL("./cmaps/",import.meta.url).href', script)
        self.assertTrue(entry["executable"])
        self.assertEqual(16, entry["integrity"]["blockSize"])
        self.assertEqual(hashlib.sha256(script).hexdigest(), entry["integrity"]["hash"])
        self.assertEqual(
            [hashlib.sha256(script[i:i + 16]).hexdigest() for i in range(0, len(script), 16)],
            entry["integrity"]["blocks"],
        )
        for name, resource in assets["cmaps"]["files"].items():
            data = file_data(resource, payload)
            self.assertEqual((self.package / "cmaps" / name).read_bytes(), data)
            self.assertEqual(hashlib.sha256(data).hexdigest(), resource["integrity"]["hash"])

    def test_rejects_version_changes(self):
        self.assert_failure_unchanged(app_version="next")
        self.assert_failure_unchanged(pdfjs_version="next")
        self.make_archive(script=b"var Or=`next`;m=ge(e.cMapUrl);")
        self.assert_failure_unchanged()

    def test_rejects_changed_or_ambiguous_upstream_code(self):
        for script, duplicate in ((b"changed upstream", False), (b"var Or=`5.4.296`;m=ge(e.cMapUrl);", True)):
            with self.subTest(duplicate=duplicate):
                self.make_archive(script, duplicate)
                self.assert_failure_unchanged()

    def test_rejects_incomplete_cmaps(self):
        (self.package / "cmaps/UniGB-UTF16-H.bcmap").unlink()
        self.assert_failure_unchanged()

    def test_rejects_truncated_or_corrupt_archive(self):
        original = self.archive.read_bytes()
        self.archive.write_bytes(original[:12])
        self.assert_failure_unchanged()
        self.archive.write_bytes(original.replace(b"m=ge(e.cMapUrl)", b"n=ge(e.cMapUrl)"))
        self.assert_failure_unchanged()

    def test_does_not_replace_archive_after_write_failure(self):
        with patch.object(cmaps.shutil, "copyfileobj", side_effect=OSError("write failed")):
            self.assert_failure_unchanged()

    def test_rejects_second_application(self):
        self.apply()
        self.assert_failure_unchanged()


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

"""Check guarded patching and preservation of ASAR entries."""

import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "decorations", Path(__file__).with_name("chatgpt-native-decorations.py")
)
decorations = importlib.util.module_from_spec(spec)
spec.loader.exec_module(decorations)
cmaps = decorations.cmaps


class DecorationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.archive = Path(self.temp.name) / "app.asar"
        self.script = b";".join(old for old, _ in decorations.REPLACEMENTS)
        self.make_archive()

    def make_archive(self, script=None):
        payload = bytearray()

        def entry(data):
            result = dict(size=len(data), offset=str(len(payload)), integrity=cmaps.integrity(data, 16))
            payload.extend(data)
            return result

        self.header = {"files": {
            "package.json": entry(b'{"version":"26.908.40834"}'),
            ".vite": {"files": {"build": {"files": {
                "main-test.js": entry(self.script if script is None else script),
            }}}},
            "other": entry(b"unchanged"),
            "native.node": {"unpacked": True, "size": 123},
            "alias": {"link": "other"},
        }}
        self.payload = bytes(payload)
        self.archive.write_bytes(cmaps.encode_header(self.header) + payload)
        self.archive.chmod(0o644)

    def apply(self, version="26.908.40834"):
        decorations.patch_archive(self.archive, version)

    def assert_failure_unchanged(self, **kwargs):
        before = self.archive.read_bytes()
        with self.assertRaises((ValueError, OSError)):
            self.apply(**kwargs)
        self.assertEqual(before, self.archive.read_bytes())
        self.assertEqual([], list(self.archive.parent.glob(".native-decorations-*")))

    def test_preserves_archive_and_updates_integrity(self):
        self.apply()
        with self.archive.open("rb") as source:
            header, start = cmaps.read_header(source)
            files = header["files"]
            for name in ("package.json", "other", "native.node", "alias"):
                self.assertEqual(self.header["files"][name], files[name])
            entry = files[".vite"]["files"]["build"]["files"]["main-test.js"]
            data = cmaps.read_entry(source, start, entry)
            self.assertEqual(b";".join(new for _, new in decorations.REPLACEMENTS), data)
            self.assertEqual(16, entry["integrity"]["blockSize"])
            source.seek(start)
            self.assertEqual(self.payload, source.read(len(self.payload)))
        self.assertEqual(0o644, self.archive.stat().st_mode & 0o777)

    def test_rejects_missing_duplicate_and_changed_targets(self):
        for original, _ in decorations.REPLACEMENTS:
            for script in (self.script.replace(original, b"changed"), self.script + original):
                self.make_archive(script)
                self.assert_failure_unchanged()

    def test_rejects_wrong_version_and_reapplication(self):
        self.assert_failure_unchanged(version="next")
        self.apply()
        self.assert_failure_unchanged()

    def test_write_failure_preserves_archive(self):
        with patch.object(decorations.shutil, "copyfileobj", side_effect=OSError("write failed")):
            self.assert_failure_unchanged()

    def test_rejects_corrupt_bundle(self):
        data = self.archive.read_bytes()
        self.archive.write_bytes(data.replace(b"case`detached`", b"case`corrupt!`"))
        self.assert_failure_unchanged()


if __name__ == "__main__":
    unittest.main()

"""Regression tests for release rejection paths; no Android SDK required."""

import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

from verify_apk import verify


class VerifyApkTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.apk = Path(self.temp.name) / "release.apk"
        with zipfile.ZipFile(self.apk, "w") as archive:
            archive.writestr("AndroidManifest.xml", "fixture")
        self.fingerprint = "ab" * 32
        self.output = "\n".join([
            "Verified using v1 scheme (JAR signing): true",
            "Verified using v2 scheme (APK Signature Scheme v2): true",
            "Verified using v3 scheme (APK Signature Scheme v3): true",
            "Number of signers: 1",
            "Signer #1 certificate DN: CN=Wallehog Release",
            f"Signer #1 certificate SHA-256 digest: {self.fingerprint}",
        ])

    def check_output(self, output, fingerprint=None):
        with patch("verify_apk.subprocess.run", return_value=subprocess.CompletedProcess([], 0, output, "")):
            return verify(self.apk, "apksigner", fingerprint or self.fingerprint)

    def test_signed_release(self):
        self.assertEqual(len(self.check_output(self.output)), 64)

    def test_each_missing_scheme_is_rejected(self):
        for scheme in (1, 2, 3):
            with self.subTest(scheme=scheme), self.assertRaises(ValueError):
                lines = self.output.splitlines()
                lines[scheme - 1] = lines[scheme - 1].replace("true", "false")
                self.check_output("\n".join(lines))

    def test_wrong_certificate_is_rejected(self):
        with self.assertRaises(ValueError):
            self.check_output(self.output, "cd" * 32)

    def test_missing_pin_is_rejected(self):
        with self.assertRaises(ValueError):
            self.check_output(self.output, "invalid")

    def test_debug_certificate_is_rejected_even_when_pinned(self):
        with self.assertRaises(ValueError):
            self.check_output(self.output.replace("Wallehog Release", "Android Debug"))

    def test_multiple_signers_are_rejected(self):
        with self.assertRaises(ValueError):
            self.check_output(self.output.replace("Number of signers: 1", "Number of signers: 2"))

    def sdk_ranges(self):
        current = self.output.replace("Signer #1", "Signer (minSdkVersion=33, maxSdkVersion=2147483647)")
        previous = "\n".join(line.replace("Signer #1", "Signer (minSdkVersion=24, maxSdkVersion=32)") for line in self.output.splitlines() if line.startswith("Signer #1"))
        return current + "\n" + previous

    def test_sdk_range_labels_with_the_same_pinned_identity(self):
        self.assertEqual(len(self.check_output(self.sdk_ranges())), 64)

    def test_development_sdk_range_label(self):
        output = self.sdk_ranges().replace("minSdkVersion=33,", "minSdkVersion=33 (dev release=true),")
        self.assertEqual(len(self.check_output(output)), 64)

    def test_one_unpinned_sdk_range_is_rejected(self):
        output = self.sdk_ranges().replace(self.fingerprint, "cd" * 32, 1)
        with self.assertRaises(ValueError):
            self.check_output(output)

    def test_debug_certificate_with_sdk_ranges_is_rejected(self):
        with self.assertRaises(ValueError):
            self.check_output(self.sdk_ranges().replace("Wallehog Release", "Android Debug"))

    def test_source_stamp_is_not_an_application_signer(self):
        with self.assertRaises(ValueError):
            self.check_output(self.output.replace("Signer #1", "Source Stamp Signer"))

    def test_invalid_apk_is_rejected(self):
        self.apk.write_bytes(b"broken download")
        with self.assertRaises(zipfile.BadZipFile):
            self.check_output(self.output)

    def test_verification_failure_is_rejected(self):
        with patch("verify_apk.subprocess.run", side_effect=subprocess.CalledProcessError(1, "apksigner")):
            with self.assertRaises(subprocess.CalledProcessError):
                verify(self.apk, "apksigner", self.fingerprint)


if __name__ == "__main__":
    unittest.main()

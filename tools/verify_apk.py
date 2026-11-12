"""Fail closed on missing signatures, wrong identity, or damaged release APKs."""

import argparse
import hashlib
import re
import subprocess
import sys
import zipfile
from pathlib import Path


def verify(apk: Path, apksigner: str, expected: str) -> str:
    expected = expected.replace(":", "").lower()
    if not re.fullmatch(r"[0-9a-f]{64}", expected):
        raise ValueError("Expected signing certificate SHA-256 must contain 64 hex digits")
    with zipfile.ZipFile(apk) as archive:
        if archive.testzip() is not None:
            raise ValueError("APK ZIP integrity check failed")
    result = subprocess.run(
        # API 24+ may skip v1 verification even when a v1 signature exists.
        # Verify from API 23 to actually exercise all required schemes.
        [apksigner, "verify", "--verbose", "--print-certs", "--min-sdk-version", "23", str(apk)],
        capture_output=True, text=True, check=True,
    )
    output = result.stdout
    for scheme in (1, 2, 3):
        if not re.search(rf"^Verified using v{scheme} scheme .*: true$", output, re.M):
            raise ValueError(f"Required APK v{scheme} signature is missing")
    if not re.search(r"^Number of signers: 1$", output, re.M):
        raise ValueError("Exactly one release signer is required")
    match = re.search(r"^Signer #1 certificate SHA-256 digest: ([0-9a-fA-F]+)$", output, re.M)
    if match is None or match[1].lower() != expected:
        raise ValueError("APK signer does not match the pinned release certificate")
    if re.search(r"^Signer #1 certificate DN: .*CN=Android Debug", output, re.M):
        raise ValueError("Android debug certificates are forbidden for release")
    return hashlib.sha256(apk.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--apksigner", required=True)
    parser.add_argument("--certificate-sha256", required=True)
    args = parser.parse_args()
    try:
        digest = verify(args.apk, args.apksigner, args.certificate_sha256)
    except (OSError, ValueError, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        print(f"Release APK rejected: {error}", file=sys.stderr)
        return 1
    print(f"{digest}  {args.apk.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

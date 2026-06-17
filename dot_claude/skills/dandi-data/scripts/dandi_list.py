# /// script
# requires-python = ">=3.10"
# dependencies = ["dandi"]
# ///
"""List assets in a DANDI dandiset.

Usage:
    uv run dandi_list.py <dandiset_id> [version]

Examples:
    uv run dandi_list.py 001636
    uv run dandi_list.py 001636 draft
"""
from __future__ import annotations

import sys

from dandi.dandiapi import DandiAPIClient


def list_assets(dandiset_id: str, version: str = "draft") -> None:
    with DandiAPIClient() as client:
        dandiset = client.get_dandiset(dandiset_id, version)
        metadata = dandiset.get_metadata()
        print(f"Dandiset {dandiset_id}: {metadata.name}")
        print(f"Version: {version}")
        print()

        total_size = 0
        count = 0
        for asset in dandiset.get_assets():
            size_mb = asset.size / (1024 * 1024)
            total_size += asset.size
            count += 1
            print(f"  {asset.path}  ({size_mb:.1f} MB)")

        print()
        print(f"Total: {count} assets, {total_size / (1024**3):.2f} GB")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <dandiset_id> [version]")
        sys.exit(1)

    dandiset_id = sys.argv[1]
    version = sys.argv[2] if len(sys.argv) > 2 else "draft"
    list_assets(dandiset_id, version)

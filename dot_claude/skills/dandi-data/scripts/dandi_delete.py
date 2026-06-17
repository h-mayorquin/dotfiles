# /// script
# requires-python = ">=3.10"
# dependencies = ["dandi"]
# ///
"""Delete assets from a DANDI dandiset.

Usage:
    uv run dandi_delete.py <dandiset_id> [--all] [--glob PATTERN] [--yes]

Examples:
    uv run dandi_delete.py 001636 --all
    uv run dandi_delete.py 001636 --glob "sub-V/*"
    uv run dandi_delete.py 001636 --all --yes   # skip confirmation
"""
from __future__ import annotations

import argparse
import os
import sys

from dandi.dandiapi import DandiAPIClient


def delete_assets(dandiset_id: str, delete_all: bool, glob_pattern: str | None, skip_confirm: bool) -> None:
    token = os.environ.get("DANDI_API_KEY")
    with DandiAPIClient(token=token) as client:
        dandiset = client.get_dandiset(dandiset_id, "draft")

        if glob_pattern:
            assets = list(dandiset.get_assets_by_glob(glob_pattern))
        elif delete_all:
            assets = list(dandiset.get_assets())
        else:
            print("Error: specify --all or --glob PATTERN")
            sys.exit(1)

        if not assets:
            print("No matching assets found.")
            return

        print(f"Found {len(assets)} assets to delete from dandiset {dandiset_id}:")
        for asset in assets[:10]:
            print(f"  {asset.path}")
        if len(assets) > 10:
            print(f"  ... and {len(assets) - 10} more")

        if not skip_confirm:
            response = input(f"\nDelete {len(assets)} assets? [y/N] ")
            if response.lower() != "y":
                print("Aborted.")
                return

        for index, asset in enumerate(assets):
            asset.delete()
            if (index + 1) % 50 == 0:
                print(f"  Deleted {index + 1}/{len(assets)}...")

        print(f"Done. Deleted {len(assets)} assets.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Delete assets from a DANDI dandiset")
    parser.add_argument("dandiset_id", help="Dandiset identifier (e.g. 001636)")
    parser.add_argument("--all", action="store_true", dest="delete_all", help="Delete all assets")
    parser.add_argument("--glob", dest="glob_pattern", help="Glob pattern to match assets (e.g. 'sub-V/*')")
    parser.add_argument("--yes", "-y", action="store_true", dest="skip_confirm", help="Skip confirmation prompt")
    args = parser.parse_args()
    delete_assets(args.dandiset_id, args.delete_all, args.glob_pattern, args.skip_confirm)

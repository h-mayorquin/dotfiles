# /// script
# requires-python = ">=3.10"
# dependencies = ["dandi"]
# ///
"""Compare local NWB files against a DANDI dandiset.

Usage:
    uv run dandi_compare.py <dandiset_id> <local_dir>

Examples:
    uv run dandi_compare.py 001636 ./nwbfiles
    uv run dandi_compare.py 001636 /home/user/data/nwbfiles
"""
from __future__ import annotations

import os
import sys

from dandi.dandiapi import DandiAPIClient


def compare(dandiset_id: str, local_dir: str) -> None:
    if not os.path.isdir(local_dir):
        print(f"Error: {local_dir} is not a directory")
        sys.exit(1)

    # Collect local NWB filenames (without extension)
    local_files = {}
    for f in os.listdir(local_dir):
        if f.endswith(".nwb"):
            local_files[f] = os.path.join(local_dir, f)

    # Collect DANDI asset filenames
    with DandiAPIClient() as client:
        dandiset = client.get_dandiset(dandiset_id, "draft")
        metadata = dandiset.get_metadata()
        print(f"Dandiset {dandiset_id}: {metadata.name}")

        dandi_files = {}
        for asset in dandiset.get_assets():
            fname = asset.path.split("/")[-1]
            dandi_files[fname] = asset.path

    local_names = set(local_files.keys())
    dandi_names = set(dandi_files.keys())

    both = local_names & dandi_names
    only_local = local_names - dandi_names
    only_dandi = dandi_names - local_names

    print(f"\nLocal: {len(local_names)} files")
    print(f"DANDI: {len(dandi_names)} files")
    print(f"In both: {len(both)}")
    print(f"Only local: {len(only_local)}")
    print(f"Only on DANDI: {len(only_dandi)}")

    if only_local:
        print(f"\nFiles only local ({len(only_local)}):")
        for f in sorted(only_local)[:30]:
            print(f"  {f}")
        if len(only_local) > 30:
            print(f"  ... and {len(only_local) - 30} more")

    if only_dandi:
        print(f"\nFiles only on DANDI ({len(only_dandi)}):")
        for f in sorted(only_dandi)[:30]:
            print(f"  {f}")
        if len(only_dandi) > 30:
            print(f"  ... and {len(only_dandi) - 30} more")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <dandiset_id> <local_dir>")
        sys.exit(1)

    compare(sys.argv[1], sys.argv[2])

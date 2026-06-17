"""Open a remote NWB file from DANDI, using lindi if a current pre-generated
JSON is available, otherwise falling back to remfile.

Usage as a library:

    from open_nwb import open_nwb

    with open_nwb("000409", "sub-CSHL049/sub-CSHL049_ses-xxx_behavior+ecephys+image.nwb") as io:
        nwbfile = io.read()
        print(nwbfile)

Usage from the command line:

    python open_nwb.py 000409 "sub-CSHL049/sub-CSHL049_ses-xxx.nwb"

The script prints which method was used (lindi or remfile) and basic NWB info.
"""

from __future__ import annotations

import sys
from contextlib import contextmanager
from datetime import datetime, timezone
from typing import Iterator

from dandi.dandiapi import DandiAPIClient
from pynwb import NWBHDF5IO


LINDI_BASE_URL = "https://lindi.neurosift.org/dandi/dandisets"


def _check_lindi(dandiset_id: str, asset_id: str, asset_modified: datetime) -> str | None:
    """Return the lindi URL if a current pre-generated JSON exists, else None.

    "Current" means the LINDI file was generated after the asset was last modified.
    """
    import requests

    lindi_url = f"{LINDI_BASE_URL}/{dandiset_id}/assets/{asset_id}/nwb.lindi.json"

    try:
        resp = requests.get(lindi_url, timeout=10)
    except requests.RequestException:
        return None

    if resp.status_code != 200:
        return None

    gen_meta = resp.json().get("generationMetadata", {})
    gen_ts = gen_meta.get("generationTimestamp")
    if gen_ts is None:
        return None

    gen_time = datetime.fromisoformat(gen_ts.replace("Z", "+00:00"))
    modified = asset_modified if asset_modified.tzinfo else asset_modified.replace(tzinfo=timezone.utc)

    if gen_time >= modified:
        return lindi_url

    return None


def _open_with_lindi(lindi_url: str) -> tuple:
    """Open an NWB file via lindi. Returns (io, closables) tuple."""
    import lindi

    f = lindi.LindiH5pyFile.from_lindi_file(lindi_url)
    io = NWBHDF5IO(file=f, mode="r")
    return io, [f]


def _open_with_remfile(s3_url: str) -> tuple:
    """Open an NWB file via remfile. Returns (io, closables) tuple."""
    import h5py
    import remfile

    disk_cache = remfile.DiskCache("/tmp/remfile_cache")
    rem_file = remfile.File(s3_url, disk_cache=disk_cache)
    h5f = h5py.File(rem_file, "r")
    io = NWBHDF5IO(file=h5f, load_namespaces=True)
    return io, [h5f, rem_file]


@contextmanager
def open_nwb(
    dandiset_id: str,
    asset_path: str,
    version: str = "draft",
) -> Iterator[NWBHDF5IO]:
    """Context manager that opens a remote NWB file from DANDI.

    Tries lindi first (if a current pre-generated JSON exists), falls back to remfile.

    Parameters
    ----------
    dandiset_id : str
        The dandiset identifier (e.g. "000006").
    asset_path : str
        Path of the asset within the dandiset.
    version : str
        Dandiset version, defaults to "draft".

    Yields
    ------
    NWBHDF5IO
        A pynwb IO object in read mode. Call .read() to get the NWBFile.
    """
    with DandiAPIClient() as client:
        asset = client.get_dandiset(dandiset_id, version).get_asset_by_path(asset_path)
        s3_url = asset.get_content_url(follow_redirects=1, strip_query=True)

        lindi_url = _check_lindi(dandiset_id, asset.identifier, asset.modified)

        method = None
        io = None
        closables = []

        if lindi_url is not None:
            try:
                io, closables = _open_with_lindi(lindi_url)
                method = "lindi"
            except Exception:
                io = None
                closables = []

        if io is None:
            io, closables = _open_with_remfile(s3_url)
            method = "remfile"

        try:
            print(f"Opened via {method}")
            yield io
        finally:
            io.close()
            for c in closables:
                c.close()


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <dandiset_id> <asset_path> [version]")
        sys.exit(1)

    dandiset_id = sys.argv[1]
    asset_path = sys.argv[2]
    version = sys.argv[3] if len(sys.argv) > 3 else "draft"

    with open_nwb(dandiset_id, asset_path, version) as io:
        nwbfile = io.read()
        print(f"Session: {nwbfile.session_description}")
        print(f"Acquisition keys: {list(nwbfile.acquisition.keys())}")

---
name: dandi-data
description: >
  How to interact with DANDI Archive data using the dandi CLI, the Python API (DandiAPIClient),
  and how to stream/load NWB files remotely using remfile or lindi.
  Use this skill whenever the user mentions DANDI, dandisets, NWB files, neurodata,
  neurophysiology data archives, streaming neuroscience data, or wants to download,
  upload, browse, or analyze data from dandiarchive.org. Also use when the user
  mentions remfile, lindi, pynwb streaming, LindiH5pyFile, or loading HDF5 files
  from S3 URLs.
---

# Working with DANDI Archive Data

DANDI (Distributed Archives for Neurophysiology Data Integration) is a platform for sharing
neurophysiology data, primarily in NWB (Neurodata Without Borders) format. This skill covers
the CLI, the Python API, and two approaches for streaming NWB files remotely: remfile and lindi.

## Bundled Scripts

All scripts use PEP 723 inline metadata and should be run with `uv run`. They are located
at `~/.claude/skills/dandi-data/scripts/`. If a script errors, read its source to debug.
Scripts can be edited in place to fix issues or adapt behavior.

| Script | Purpose | Usage |
|--------|---------|-------|
| `dandi_list.py` | List assets in a dandiset | `uv run dandi_list.py <id> [version]` |
| `dandi_delete.py` | Delete assets (all or by glob) | `uv run dandi_delete.py <id> --all [--yes]` |
| `dandi_compare.py` | Compare local NWB files vs DANDI | `uv run dandi_compare.py <id> <local_dir>` |
| `open_nwb.py` | Stream NWB from DANDI (lindi/remfile) | `uv run open_nwb.py <id> <asset_path>` |

**When a task can be accomplished by running a bundled script, run it instead of writing inline Python.**

## Key Instances

| Instance | URL | Purpose |
|----------|-----|---------|
| `dandi` | https://dandiarchive.org | Production archive |
| `dandi-sandbox` | https://sandbox.dandiarchive.org | Testing/development |

## The dandi CLI

Install with `uv pip install dandi`.

```bash
# Download
dandi download DANDI:000006
dandi download DANDI:000006/0.220126.1903
dandi download --path-type glob "DANDI:000006/draft/sub-*/sub-*_ses-*.nwb"

# List
dandi ls DANDI:000006
dandi ls -f yaml DANDI:000006

# Upload (from a directory with dandiset.yaml)
dandi upload

# Organize NWB files by metadata
dandi organize ./raw-data/ -d ./my-dandiset/ --files-mode dry   # preview
dandi organize ./raw-data/ -d ./my-dandiset/ --files-mode move  # execute

# Validate
dandi validate ./my-dandiset/

# Other
dandi delete DANDI:000006/draft/sub-anm372795/file.nwb
dandi move old/path.nwb new/path.nwb -d DANDI:000006
```

## Python API (DandiAPIClient)

```python
from dandi.dandiapi import DandiAPIClient

# For repeated/iterative queries (audits, dashboards, notebooks that touch
# many dandisets), pass cache=True. Responses are persisted to a local
# SQLite DB, validated against modified timestamps so stale data is detected
# without an extra round trip. Landed Feb 2026 in dandi-cli.
with DandiAPIClient(cache=True) as client:
    dandiset = client.get_dandiset("000006", "draft")

    # List assets
    for asset in dandiset.get_assets():
        print(f"{asset.path}: {asset.size} bytes")

    # Glob matching
    for asset in dandiset.get_assets_by_glob("sub-*/*_ses-*.nwb"):
        print(asset.path)

    # Get S3 URL for streaming
    asset = dandiset.get_asset_by_path("sub-anm372795/sub-anm372795_ses-20170718.nwb")
    s3_url = asset.get_content_url(follow_redirects=1, strip_query=True)

    # Metadata
    metadata = dandiset.get_metadata()
    asset_meta = asset.get_metadata()
```

### Authentication

For uploading or accessing embargoed dandisets:

1. **Environment variable**: `DANDI_API_KEY=your-token-here`
2. **System keyring**: stored automatically after first interactive login
3. **Explicit token**: `DandiAPIClient(token="your-token")`

## Streaming NWB Files with remfile

Optimized for HDF5/NWB: adaptive chunk sizes, multithreading for large arrays.
Best for one-off reads and quick exploration.

```python
import h5py
import remfile
from pynwb import NWBHDF5IO

disk_cache = remfile.DiskCache("/tmp/remfile_cache")
rem_file = remfile.File(s3_url, disk_cache=disk_cache)

with h5py.File(rem_file, "r") as h5f:
    with NWBHDF5IO(file=h5f, load_namespaces=True) as io:
        nwbfile = io.read()
        print(list(nwbfile.acquisition.keys()))
```

For presigned URLs that expire:

```python
class DandiURL:
    def __init__(self, asset):
        self._asset = asset
    def get_url(self):
        return self._asset.get_content_url(follow_redirects=1, strip_query=True)

rem_file = remfile.File(DandiURL(asset), disk_cache=disk_cache)
```

## Streaming NWB Files with lindi

Converts file structure to compact JSON with references to remote data chunks.
Better for repeated access (metadata is local after first load).

```python
import lindi
import pynwb

# From a DANDI URL
url = "https://api.dandiarchive.org/api/assets/<asset_id>/download/"
f = lindi.LindiH5pyFile.from_hdf5_file(url)
with pynwb.NWBHDF5IO(file=f, mode="r") as io:
    nwbfile = io.read()
f.close()

# Save for instant future loading
f.write_lindi_file("my_file.nwb.lindi.json")

# Reload later (no network for metadata)
g = lindi.LindiH5pyFile.from_lindi_file("my_file.nwb.lindi.json")
```

### Smart opener (bundled)

`scripts/open_nwb.py` provides `open_nwb()` that tries lindi first, falls back to remfile:

```python
from open_nwb import open_nwb

with open_nwb("000409", "sub-CSHL049/sub-CSHL049_ses-xxx.nwb") as io:
    nwbfile = io.read()
```

### remfile vs lindi

| Feature | remfile | lindi |
|---------|---------|-------|
| First load | Fast | Slower (builds JSON) |
| Repeated access | Same speed | Much faster (metadata local) |
| Save for later | No (disk cache helps) | Yes (.lindi.json) |
| Best for | One-off reads | Repeated access |

## Common NWB access patterns

```python
print(list(nwbfile.acquisition.keys()))
print(list(nwbfile.processing.keys()))

if nwbfile.units is not None:
    print(nwbfile.units.to_dataframe().head())

if nwbfile.trials is not None:
    print(nwbfile.trials.to_dataframe().head())

if nwbfile.electrodes is not None:
    print(nwbfile.electrodes.to_dataframe().head())

if nwbfile.subject is not None:
    print(nwbfile.subject.species, nwbfile.subject.sex, nwbfile.subject.age)
```

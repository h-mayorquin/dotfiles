---
name: gin-drive-upload
description: >
  Conventions and procedures for getting neuroscience test data to its homes:
  the gin git-annex repos (`ephy_testing_data` at gin.g-node.org/NeuralEnsemble,
  `ophys_testing_data` at gin.g-node.org/CatalystNeuro), the CatalystNeuro
  Google Drive archive (uploaded via Globus so files are owned by Ben's account,
  never via rclone), and the CI S3 mirror. Use this skill whenever the user is
  publishing test data to gin, archiving a full recording to the Google Drive,
  stubbing a large recording down to a small CI test dataset, deciding where a
  recording should live (gin vs Drive vs erase), writing a README in those
  repos, or touching the git-annex / gin / Globus workflow.
---

# gin-drive-upload

Conventions and procedures for managing neuroscience test data across its homes:
stubbing large recordings into small CI test datasets, staging under
`~/data/<format>/`, publishing to the gin git-annex repos, archiving full
sources to the CatalystNeuro Google Drive via Globus, and mirroring to the CI
S3 bucket.

## Repos

`gin.g-node.org` hosts **git-annex** repos. Large binaries are stored in the
annex; git only tracks small pointers.

Repos the user contributes to include (different orgs, same gin host):

- `ephy_testing_data` at `gin.g-node.org/NeuralEnsemble/ephy_testing_data`
  — python-neo fixtures
- `ophys_testing_data` at `gin.g-node.org/CatalystNeuro/ophys_testing_data`
  — neuroconv imaging fixtures

Local paths on the user's machine:

- `~/ephy_testing_data/` — ephys working copy (read-only reference)
- `~/neuroconv_testing_data/ophys_testing_data/` — ophys working copy
- `~/uploads/gin/<repo_name>/` — **staging dir for uploads**, one subdir per
  data repo (e.g., `~/uploads/gin/ephy_testing_data/`,
  `~/uploads/gin/ophys_testing_data/`, `~/uploads/gin/behavior_testing_data/`).
  All publishing happens from here.

The user has older `~/upload_to_gin/` and `~/gin_upload/` dirs from earlier
inconsistent layouts; treat both as legacy and use `~/uploads/gin/` for new
work. If a non-standard path is in use for a given repo, confirm with the user
before running any gin commands.

## When data can't go on public gin: `NeuroConv_testing_data` (Google Drive via Globus)

The gin repos are **public** and meant for small fixtures. Data that is useful
for testing a library's behavior but does not fit there goes to
**`NeuroConv_testing_data`**, an access-controlled Google Drive folder owned by
Ben Dichter (`bdichter@lbl.gov`) and shared with collaborators. There is no
fixed rule for what belongs here; some recurring examples, not exhaustive:

- **Not public** — real experimental data a lab shared for debugging or
  regression testing but has not cleared for public release (e.g. Luiz
  Tauffer's Blackrock recording reproducing python-neo #1704). It reproduces a
  real bug and is worth keeping, but it cannot be published.
- **Too large for gin** — gin is for small stubs; a genuinely large recording
  that cannot be cut down small enough has no good public home there.
- **Full-size original behind a public stub** — when the gin fixture is a small
  anonymized stub, the un-stubbed original is archived here for re-stubbing and
  provenance.
- **Not yet gin-ready** — valuable data not yet processed, stubbed, or cleared
  for gin, parked here so it is not lost while the contribution is pending.

It is also the format-organized parent of the upstream copies of gin fixtures.

### Why Globus (the attribution requirement)

Uploads must go **through Globus**, never a direct Drive upload (`rclone`, `gws`,
the web uploader). The destination is Ben's Drive exposed as a Globus collection,
so anything transferred in is **owned by `bdichter@lbl.gov` automatically** ,
correct provenance, and it counts against **Ben's** Drive quota.

A direct upload (e.g. `rclone copy remote:...`) instead marks every file as owned
by **the uploader (h.mayorquin)**, which is wrong provenance **and consumes the
user's own Google Drive space assignment** , a real cost to them. So `rclone` is
**not** a "simpler" shortcut for these archives; it is the wrong tool. Always use
the Globus transfer path below.

### Convention (mirror the existing folders)

- **One folder per recording format** at the top: `CaImAn/`, `Bruker/`,
  `Thor/`, `SpikeGLX/`, `Plexon/`, `EDF/`, `OpenEphys/`, `Blackrock/`, ...
  Add a new format folder when needed.
- Inside a format folder: one folder (or file set) per **dataset**, named after
  the recording, plus one **`data_description.md`** for the whole format folder.
- `data_description.md` is prose, one section per dataset, recording: **what the
  data is** (technical shape), **what it exercises** (the bug/feature/edge
  case), **provenance** (who shared it), and **full links** (issues, fix PRs,
  the gin stub if one exists). Use full URLs, not bare `#numbers`.
- **Zip only when a dataset is many small files** (thousands of per-frame
  TIFFs, etc.) — Globus is slow with high file counts, so one archive transfers
  far better. A few large files (Blackrock `.ns6`, OpenEphys `continuous.dat`)
  go **unzipped**.

### One-time setup

- Globus CLI: `uv tool install globus-cli`, then `globus login` (interactive,
  in a real terminal — it needs a TTY for the hidden password prompt; never
  pass the password as a command argument).
- Globus Connect Personal makes this machine a source endpoint. It is installed
  at `~/globusconnectpersonal-<version>/` and configured (via its GUI) to expose
  `~/`. Start it before transferring.

### Endpoints

- **Source** (this machine): display name `local_collection`. Rediscover its
  UUID with `globus endpoint search --filter-scope my-endpoints` (was
  `c7a2146a-edb2-11ed-9bb3-c9bb788c490e`).
- **Destination** (Ben's Drive): `bdichter_LBNL_GDrive`, owner
  `bdichter@lbl.gov`, UUID `a0e2af7a-11c6-4118-b15a-f53c219e05e1`. It is shared
  with the user; rediscover with `globus endpoint search --filter-scope shared-with-me`.
- **Destination path:** `/My Drive/data/NeuroConv_testing_data/<Format>/`.

### Per-upload workflow

```bash
# 1. Stage by format, with a data_description.md per format folder:
#    ~/upload_to_neuroconv_testing_folder/<Format>/data_description.md
#    ~/upload_to_neuroconv_testing_folder/<Format>/<dataset>/...   (unzipped, or
#    <dataset>.zip only if it is many small files)

# 2. Start the source endpoint (it feeds the bytes; keep it + the machine
#    running until the transfer finishes)
~/globusconnectpersonal-3.2.0/globusconnectpersonal -start &

# 3. Confirm the endpoint can see the staging dir
globus ls "<SOURCE_UUID>:/home/heberto/upload_to_neuroconv_testing_folder/"

# 4. Transfer each format folder (the data_description.md rides along)
globus transfer --recursive \
  "<SOURCE_UUID>:/home/heberto/upload_to_neuroconv_testing_folder/<Format>" \
  "a0e2af7a-11c6-4118-b15a-f53c219e05e1:/My Drive/data/NeuroConv_testing_data/<Format>" \
  --label "<short description>"

# 5. Monitor (transfers run on Globus's servers, asynchronously)
globus task list
globus task show <task-id>
```

The first transfer into the Drive may print a one-time
`globus session consent` URL (open it, then re-run); after that there are no
prompts. Files land owned by Ben automatically. When tasks show `SUCCEEDED`,
verify with `globus ls "a0e2af7a-...:/My Drive/data/NeuroConv_testing_data/<Format>/"`,
then the local staging copy is safe to delete.

## Prerequisite: an SSH key registered with gin

Publishing pushes over SSH, so the gin account must trust an SSH key that this
session's ssh-agent holds. gin is its own service: a key that authenticates to
another git host is not automatically accepted by gin — each host registers keys
independently. Check this *before* attempting any push, since the failure
otherwise surfaces late, at upload time.

```bash
ssh -T git@gin.g-node.org
```

- Success looks like `Hi there, You've successfully authenticated, but GIN does
  not provide shell access.` The key is trusted — proceed.
- `Permission denied (publickey)` means no key the agent holds is registered with
  gin. Fixing it is additive and does not disturb any key already on the account:
  1. Print the public key the agent offers: `ssh-add -L` (pick the relevant line),
     or `cat` the appropriate `*.pub`.
  2. On `gin.g-node.org` → avatar → **Settings** → **SSH / GPG Keys** → **Add
     Key**, paste the whole single line, give it any name, save.
  3. Re-run the check; it should now greet you.

Registering the key is the user's action (it touches their account). If the agent
holds no key at all (`ssh-add -L` is empty), a key has to be loaded or created in
a real terminal first — that can't be done for them in-session.

## Upload workflow

Upload uses the **`gin` CLI** (not plain `git` / `git-annex`). The exact
steps live in the top-level README of each data repo, which is authoritative:

- `~/ephy_testing_data/README.md`
- `~/neuroconv_testing_data/ophys_testing_data/README.md`

**Critical: ephys and ophys use different git-annex workflows.** Both use the
`MD5E` backend, but they differ in whether files are tracked in locked or
unlocked mode. The required commands diverge accordingly. Read the repo's
README before doing anything; mixing the two flows can corrupt an upload by
committing binary payloads directly to git.

### ephys (`NeuralEnsemble/ephy_testing_data`) — locked workflow

```bash
# One-time setup
gin login                                       # authenticate

# Per-contribution workflow (run from the staging dir)
gin get NeuralEnsemble/ephy_testing_data        # clone (only first time)
gin git checkout -b <branch_name>               # branch via gin passthrough
# ...copy files into the appropriate subfolder...
gin commit <folder_name>                        # commit annexed files
gin lock *                                      # lock files in annex
gin upload                                      # publish to gin
```

### ophys (`CatalystNeuro/ophys_testing_data`) — unlocked workflow

```bash
gin get CatalystNeuro/ophys_testing_data        # clone (only first time)
gin git checkout -b <branch_name>
# ...copy files into the appropriate subfolder...
gin commit -m "..." <folder_name>               # commit (no separate add step needed)
gin upload                                      # publish to gin
```

**The differences that matter:**

- ophys does not need `gin lock` — it is a no-op on unlocked repos. Running
  it does no harm but is unnecessary.
- The ophys repo's README mentions `gin add <folder>` as a mandatory step.
  `gin add` is not an actual CLI subcommand (run `gin --help` and you will
  not see it), but the README's *intent* is correct and mandatory: the data
  must be **annexed**, not committed as raw git blobs. The in-tool equivalent
  is `gin git annex add <folder>` before `gin commit`. Do not skip it on the
  assumption that `gin commit` annexes for you — on an unlocked repo a plain
  add of certain files (see the OME-TIFF gotcha in **Everything must be
  annexed** below) silently lands them in git as raw blobs.
- ephys's locked workflow does not have this ambiguity: `gin commit` then
  `gin lock *` then `gin upload`.

Many existing ophys fixtures *are* raw git blobs, but that is repository
**drift**, not the convention to copy. Read **Everything must be annexed**
below before publishing.

When in doubt, do `cat ~/<staging-dir>/<repo>/README.md` and follow what is
written there.

Note: `gin commit`, `gin lock`, and `gin upload` are gin CLI commands. Do
not substitute `git commit` or `git annex add` unless the repo README
explicitly says to (and `gin git annex add` is the underlying mechanism if
you do).

**Ask the user before running `gin upload`** or anything else that writes to
the remote. These are hard to roll back. Local steps (`gin get`, `gin
checkout`, `gin commit`, `gin lock`) are safe to run without authorization.

**Scope the upload to your contribution's path, and confirm you are in the right repo.** Bare
`gin upload` / `gin upload .` copies **every** annexed file whose content is present in your local clone
up to origin , not just your new files. In a clone that happens to hold other datasets' content, that
uploads unrelated data: in one session a bare `gin upload .` started pushing an entire Bruker OME-TIFF
dataset that was merely present locally. Use `gin upload <your_subfolder>` to scope the **content**
transfer (the git branch push is branch-level either way). And check the directory first , `gin upload .`
run in the wrong clone, on `main`, will cheerfully sync that repo. It is not destructive (it only uploads
content for files already in history, and annex content is content-addressed so it can't corrupt), but it
is rarely what you intend. If you amend a commit **after** the branch was already pushed, the re-push is a
non-fast-forward: `git push --force-with-lease origin <branch>` (annex content is unchanged for a
README-only edit, so no re-`gin upload` is needed).

## Data-repo README conventions (format-first, reader-agnostic)

The README that **ships inside a gin data repo** documents the data and the file format, not the consumer
software. (Keep the consumer reasoning , neo bug catalogs, NWB/icephys mapping , in your own working
notes, e.g. the obsidian vault; it dates quickly and is not the data repo's concern.)

- **No consumer libraries.** Do not reference python-neo / neuroconv, or frame files as "behaviors reader
  X must handle" / "catches neo's Y bug". Describe what each file *is* in format terms (the ABF Tag
  section, `nTelegraphMode`, `nEpochType`, free-form "User Units"). Keep tool mentions to the
  provenance/attribution line only (e.g. "pyABF sample collection, MIT, attribute Scott Harden").
- **Avoid the word "fixture"** , say "files".
- **Bullet lists, not markdown tables** (tables render unevenly and "sometimes don't look good").
- **Each subfolder gets its own `###` heading**, like sibling datasets; let a section lead with its
  description content rather than a redundant wrapper header.
- **Provenance as a short paragraph.** "Most are shrunk from the pyABF suite; a few are synthetic
  (real recording, header anonymized, samples shuffled, so structure stays and content/identifiers go)"
  is enough; a per-file source-filename map is optional and usually belongs in working notes, not here.

## Everything must be annexed (never plain git blobs)

Both gin repos store data **in the annex**: git tracks only a small pointer
(`/annex/objects/MD5E-...`), and the bytes live in the annex, transferred
separately by `gin upload` / `git annex copy`. This is not cosmetic. A binary
committed as a raw git blob is baked into the repository history permanently:
every clone pays for it forever, and it cannot be dropped the way annexed
content can (`git annex drop`, partial fetches). Keeping data out of git
history is the whole point of annex. The `ophys_testing_data` README states
the rule outright, and `.gitattributes` encodes it:

    * annex.largefiles=((mimeencoding=binary)and(largerthan=0))

i.e. anything git detects as binary and non-empty must be annexed.

**The repo has drifted.** Many older ophys fixtures were committed as raw
blobs — confirm with `git cat-file -p HEAD:<path>`, which prints TIFF bytes
instead of a one-line `/annex/objects/...` pointer. That drift is a known
defect, not a model to follow. Do not add new data as plain blobs to "match"
the neighbors. New data is always annexed.

### The XML-leading OME-TIFF gotcha (force-annex)

git-annex decides binary-ness from the file's leading bytes. A Bruker /
PrairieView **master-OME first tif** begins with the embedded OME-XML, so
git-annex sniffs it as text (`mimeencoding` is not `binary`), the `largefiles`
rule fails to match, and the multi-MB tif lands in **git as a raw blob** even
though every other tif in the set annexed correctly. Force these into the
annex explicitly:

    git rm --cached -q <file.ome.tif>
    git -c annex.largefiles=anything annex add <file.ome.tif>

`-c annex.largefiles=anything` overrides the mimeencoding sniff for that one
add. Afterward, `git cat-file -p HEAD:<file>` shows a `/annex/objects/MD5E-...`
pointer.

### gin upload can re-expand a pointer — verify after, not just before

`gin upload` / `gin commit` can make its own auto-commit (labeled "gin commit
from h-laptop") that **re-adds an unlocked pointer as a blob**, silently
undoing a force-annex. So verify *after* uploading:

    git cat-file -p HEAD:<path>     # expect a one-line /annex/objects pointer, not bytes
    git annex whereis <path>        # expect "origin" among the listed copies

Sweep a folder for "zero raw blobs": for every data file under it, check the
committed object is a pointer, not bytes. Anything that isn't is drift you
just introduced — force-annex it and re-commit.

### When the blob already reached history

Force-annexing *after* a blob is in a pushed commit fixes the working tree but
leaves the full blob in that commit's history. While the offending commits are
still only on your branch, prefer a **squash merge** (or rebase to drop the
blobby commit) so the binary never becomes an ancestor of `main`. Once it is on
`main` it is permanent in every clone. The one exception: git addresses objects
by content hash, so re-introducing a blob whose exact bytes were *already* in
`main`'s history (e.g. pre-existing drift) adds nothing to a clone — it
de-duplicates against the object already there. Check with
`git rev-list --objects origin/main | grep <blob-sha>` before assuming a
round-trip cost anything.

## After upload: offer to sync the S3 mirror (neuroconv CI)

The neuroconv CI suite does not pull from gin directly. It downloads from an
S3 mirror at `s3://neuroconv-gin-datasets/`. The intended auto-sync workflow
(`.github/workflows/update-s3-testing-data.yml`) is disabled and broken (pins
an old `datalad` version incompatible with Python 3.13), so new data must be
copied to S3 manually. Without this step, neuroconv CI fails on the new
fixtures with `FileNotFoundError` or empty-directory errors.

The mirror covers all three neuroconv data repos, each under its own S3
prefix and each keyed by its own CI cache:

| gin repo | S3 prefix (note the double slash) | cache key prefix |
|---|---|---|
| `ephy_testing_data` | `s3://neuroconv-gin-datasets//ephy_testing_data/` | `ephys-datasets-` |
| `ophys_testing_data` | `s3://neuroconv-gin-datasets//ophys_testing_data/` | `ophys-datasets-` |
| `behavior_testing_data` | `s3://neuroconv-gin-datasets//behavior_testing_data/` | `behavior-datasets-` |

`roiextractors` shares the same mirror but only reads the `ophys_testing_data`
prefix.

### The cache key is the S3 listing hash — uploading auto-invalidates it

Do not look for a manual cache-bust step; there is none to run. The
`load-data` composite action in both neuroconv and roiextractors
(`.github/actions/load-data/action.yml`) computes each repo's cache key as:

    <repo>-datasets-<sha256( aws s3 ls --recursive <bucket>/<repo>/ )>

i.e. a hash of the **S3 listing itself**, not of gin HEAD. So the moment you
`aws s3 cp` a new fixture in, that repo's listing changes, its hash changes,
its key changes, and the next CI run misses the stale cache and re-downloads.
The `sha256sum` over the listing costs ~2 ms; the whole keying step is ~1.5 s
(dominated by the S3 LIST round-trip). Because each repo hashes only its own
prefix, syncing ophys data invalidates only the ophys cache, leaving ephys and
behavior untouched.

**After `gin upload` succeeds, ask the user**: "Do you also want me to sync
the new files to the neuroconv S3 mirror?" Do not run the upload without
explicit authorization — it writes to shared infrastructure.

If yes, work from the **gin staging dir** (`~/uploads/gin/<repo>/`), not from
a read-only reference clone (like `~/ephy_testing_data/` or
`~/neuroconv_testing_data/ophys_testing_data/`). The staging dir reflects
what was committed to gin. Reference clones may be behind by one or more
merges, which produces silent false positives where "S3 looks synced" but
is actually missing the latest additions. Run `git fetch` in the staging
dir first, then compute the diff against S3 using `git ls-tree -r HEAD` on
the relevant subtree so the comparison is anchored to what gin actually
tracks (not the local filesystem, which may include symlinks or untracked
working files).

Don't forget README files at each level. They often change alongside new
fixtures and are easy to miss because the folder listing still matches.

```bash
# Note the double slash, the S3 prefix has a leading slash, this is intentional
aws s3 cp --recursive ./<new-folder> \
  "s3://neuroconv-gin-datasets//ephy_testing_data/<new-folder>"
```

No cache purge step follows. The upload itself changes the S3 listing, which
is what the cache key hashes, so the next CI run re-downloads automatically
(see the cache-key note above). Just verify the bytes landed:

```bash
aws s3 ls --recursive "s3://neuroconv-gin-datasets//ephy_testing_data/<new-folder>/"
```

Full background and the failure mode that motivated this checklist:
`~/MEGAsync/obsidian/heberto_vault/neuroscience/neuroconv/ci_s3_test_data_management.md`.

## Pre-gin staging layout: `~/data/<format>/`

For test fixtures derived from a vendor format, the user keeps a working
directory at `~/data/<format>/` (e.g. `~/data/ome_tiff/`, `~/data/Bruker/`)
that is *separate from* the gin staging dir. Layout convention:

```
~/data/<format>/
├── README.md            -- describes source datasets and provenance
├── README_for_gin.md    -- describes what will be / has been uploaded
├── <source_dataset_1>/  -- pristine source, do NOT modify
├── <source_dataset_2>/
└── stubs/
    ├── README.md        -- the README that travels up to gin
    ├── stub_<name>.py   -- one PEP 723 script per stub
    └── <stub_dataset>/  -- stubbed output, this is what gets uploaded
```

The source folders are kept pure (never written into). Stub scripts read
from a source folder and write to a sibling folder under `stubs/`. The
`stubs/README.md` is the document that ends up next to the data on gin.

When publishing, the contents of `~/data/<format>/stubs/` are copied to the
gin staging dir (`~/uploads/gin/<repo_name>/imaging_datasets/<format>/` or
similar). `~/data/<format>/` itself is never uploaded; it is local working
state.

## Stubbing fixtures

Don't upload raw recordings; stub them to the minimum size that exercises the
code path under test.

Cut at a file-structure-aware boundary (packet, frame, chunk, record), never
mid-record. A mid-record cut produces a fixture that silently breaks tests in
ways that look like real bugs.

Aim for under a few MB. Existing fixtures range from ~19 KB to ~8.7 MB.

If the source data is already at fixture size (rare, but happens for OME
sample data and synthetic test cases), the "stub" script is still worth
writing for two reasons: it documents the source-to-stub provenance in
code, and it regenerates UUIDs / identifiers so the stub is a distinct
artifact from the upstream sample. In that case the script does little more
than re-emit the source with fresh IDs, but the pattern is consistent with
genuine size-reducing stubs in the same directory.

## Stub script convention: PEP 723 + `uv run`

Stub scripts are standalone, single-file Python scripts that declare their
dependencies inline via [PEP 723](https://peps.python.org/pep-0723/) script
metadata. They are run with `uv run <script>.py` (no project virtualenv, no
`requirements.txt`, no `pyproject.toml`). This keeps each stub
self-contained, immediately runnable from any check-out, and easy to
publish as a gist.

Template:

```python
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "tifffile",
#     "numpy",
# ]
# ///
"""One-line description of what the stub produces.

Source: <path to source data, with shape>
Output: <path to stub output, with shape>

Brief notes on what the script transforms (frame count, crop size, UUID
regeneration, metadata rewrites, etc).

Usage:
    uv run stub_<name>.py [optional args]
"""

import sys
from pathlib import Path
# ... etc.

SOURCE_DIR = Path(__file__).parent.parent / "<source_folder>"
OUTPUT_DIR = Path(__file__).parent / "<stub_folder>"

# ... script body, deterministic, idempotent ...

if __name__ == "__main__":
    main()
```

Conventions:

- Resolve source and output paths from `Path(__file__).parent`. The script
  must run correctly from any CWD.
- Read from `SOURCE_DIR` only. Never write into the source folder.
- Make the script idempotent: re-running it overwrites the stub cleanly.
- Accept optional CLI args for tunable parameters (frame count, crop size)
  with sensible defaults.
- Keep the dependency list minimal. Vendor-specific deps (e.g. tifffile)
  belong here; SciPy / pandas usually don't.

## Directory structure and category (ophys repo only)

This applies to the **ophys** repo (`CatalystNeuro/ophys_testing_data`), which
partitions at the **top level by data type / signal type** —
`imaging_datasets/`, `segmentation_datasets/`, `fiber_photometry_datasets/`,
`analog_datasets/`. Within a category, organize **by format** (`inscopix/`,
`bruker/`, ...), and put new data in a modality/type subfolder
(`analog_datasets/inscopix/{gpio,imu}/`). The movie of an imaging recording goes
in `imaging_datasets/<format>/`; its companion signal files go in the matching
signal-type category, not alongside the movie.

**Pick the category by what the data *is*, not by a presumed meaning.** For data
whose meaning is assigned by the experiment rather than the format — general
purpose input/output (GPIO) being the canonical case: a port can be wired to a
stimulus, a sync pulse, a sensor, anything — categorize by **signal type**, not by
a guessed modality. GPIO carries no inherent modality, so it belongs under
`analog_datasets` (the level neuroconv's `AnalogInterface` reads it at — generic
channels, meaning annotated by the user), never under `behavior`/`sync`. Labeling
it with a modality claims something the format does not carry.

**Scope — when this does NOT apply.** The above presupposes two things that hold
for the ophys repo but not everywhere: the repo separates by modality at the top
level, and the format emits the signals as *separate files* (Inscopix
`.gpio`/`.imu`). It does **not** apply to the **ecephys** repo
(`NeuralEnsemble/ephy_testing_data`), which is organized by format with no modality
separation, and where analog channels are typically embedded in the same file as
the ephys (e.g. Intan `.rhd`) and so cannot be split into their own folder. There,
keep the recording's files together as the format produces them.

**Never relocate or rename existing fixtures** (applies to every repo). Downstream
tests reference their
on-disk paths, so moving or renaming them breaks the test suite. Leave the legacy
layout exactly as it is and apply new conventions only to newly added data. (This
is stronger than a style preference: it is a compatibility constraint.)

## Naming: folders over timestamps

Prefer descriptive folder names, even for single-file fixtures:
`neuropixels2_4shank/` beats `20260122_134412_merged_cropped_1min.rec`. The
folder documents intent at a glance and groups related files later.

The name should say what the fixture is *for* — the distinctive characteristic it
exercises (`single_plane_single_color.isxd`, `multiplane_movie.isxd`), in plain
snake_case. Drop the opaque acquisition ID (`iwSAou`) and any `_stub` suffix, and
don't encode redundant or derivable properties (e.g. `full_metadata` when most
fixtures already have it, or `correct_efocus` when `single_plane` already implies
it — encode the *distinctive* axis instead). Provenance and the full characteristic
list belong in the README, not the filename.

Older dirs with timestamp-named flat files reflect an earlier style; leave
those alone unless the user asks for a migration.

## README format

**Match the existing format of the README you are editing.** Different dirs
use different conventions and consistency within a file matters more than
picking a single global style.

Two patterns currently in use:

1. **Subheader style** (older dirs, e.g.,
   `~/ephy_testing_data/spikegadgets/README.md`): one `### File: name` or
   `### Folder: name` subheader per entry, with `**Provided by:**` /
   `**Stubbed by:**` / `**Details:**` fields underneath. Use `File` or
   `Folder` to match what is actually on disk.

2. **Bullet style** (newer dirs, e.g.,
   `~/neuroconv_testing_data/ophys_testing_data/imaging_datasets/OME-TIFF/README.md`):
   short intro paragraph, `## Datasets` with a one-line bullet per fixture,
   `## Data provenance` section. Bullet template:
   ```markdown
   - `folder_or_filename` - <shape/params>. <one-line role>. Source:
     <origin> (<origin shape>). [Stub script](<gist URL>).
   ```

In both styles, the backticked name is the actual on-disk path and any
stub-script link points to a GitHub gist URL, not a repo path.

For a brand new dir with no existing README, bullet style is the preferred
default. Don't migrate legacy READMEs unless the user asks.

## Stub scripts as GitHub gists

Don't commit stub scripts alongside the data. Publish them as GitHub gists and
link from the README. Keeps the data repo lean, keeps script revisions
browsable, and makes reproducibility explicit.

The user is `h-mayorquin` on GitHub. Check their existing stub gists first
with `gh gist list` to confirm the current naming convention before creating
a new one; they may have refined it since this skill was written.

**Gist description convention** (matches the pattern used by the user's
existing stub gists — see `gh gist list`):

```
Stub <source dataset> <format> (<what the stub retains, or shape reduction>)
```

Describe **what the stub is**, not what it is for. The fact that it lives on
gin already implies the purpose (test fixture); repeating it in the
description is noise. Keep it short. Examples from the user's gists:

- `Stub MitoCheck OME-TIFF (93 to 5 frames, 1024x1344 to 64x64)`
- `Stub tubhiswt-3D OME-TIFF (20 to 5 timepoints, 512x512 to 64x64)`
- `Stub SpikeGadgets NP2 4-shank .rec (header + 300 packets)`
- `Stub Bruker TSeries 20240527 OME-TIFF`

Do not embed issue or PR numbers, language like "regression fixture", or
"for X testing" in the description; those belong in the README entry, not
the gist metadata.

Gist descriptions can be updated post-hoc without changing the URL:

```bash
gh api -X PATCH gists/<gist-id> -f description="<new description>"
```

Create with:

```bash
gh gist create <script> --public --desc "Stub <source> <format> (<reduction>)"
```

Confirm the description wording with the user before running the command.
Gists are public and appear on the user's GitHub profile.

## Pre-upload checks

Before authorizing a publish step:

1. Stub verifies its intended behavior (reproduces the bug, or parses cleanly).
2. Size is reasonable.
3. README entry is written, cross-links issue/PR if applicable.
4. Gist URL resolves.

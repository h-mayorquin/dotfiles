---
name: google-drive
description: >
  Browse, search, and download files from Google Drive using the gws CLI tool.
  Use this skill whenever the user mentions Google Drive, shared Drive folders,
  downloading files from Drive, browsing shared data, gws commands, or references
  a Google Drive file/folder ID. Also trigger when the user asks about test data
  stored in shared folders, or mentions downloading data that collaborators shared
  via Google Drive.
---

# Google Drive via gws CLI

`gws` is a CLI wrapper for Google Workspace APIs. Its parameters map directly to
the Google Drive REST API, so the official docs apply when you need to go beyond
what is covered here.

## Authentication

If a command fails with an auth error, re-authenticate first:

```bash
gws auth
```

## Browsing files

List files shared with the user:

```bash
gws drive files list \
  --params '{"q": "sharedWithMe", "pageSize": 20, "fields": "files(id,name,mimeType,owners)"}' \
  --format table
```

List contents of a folder by ID:

```bash
gws drive files list \
  --params '{"q": "'\''FOLDER_ID'\'' in parents", "pageSize": 50, "fields": "files(id,name,mimeType,size)"}' \
  --format table
```

List only subfolders:

```bash
gws drive files list \
  --params '{"q": "mimeType = '\''application/vnd.google-apps.folder'\'' and '\''FOLDER_ID'\'' in parents", "pageSize": 50, "fields": "files(id,name)"}' \
  --format table
```

## Searching

The `q` parameter uses Google Drive search syntax. Common filters:

- `name = 'exact'` or `name contains 'partial'`
- `mimeType = 'application/vnd.google-apps.folder'` (folders)
- `'FOLDER_ID' in parents` (children of a folder)
- `sharedWithMe`
- `trashed = false`

Combine with `and`:

```bash
gws drive files list \
  --params '{"q": "name contains '\''Bruker'\'' and '\''PARENT_ID'\'' in parents", "fields": "files(id,name,size)"}' \
  --format table
```

## File metadata

```bash
gws drive files get \
  --params '{"fileId": "FILE_ID", "fields": "id,name,mimeType,size,modifiedTime"}' \
  --format table
```

## Downloading

Do **not** use `gws drive files download`. In gws 0.16.0 that subcommand calls the wrong endpoint (`POST /drive/v3/files/{id}/download`, the Workspace-doc export-operation path) and returns `500 backendError "Internal error encountered."` for ordinary binary files, regardless of size. It is a hard bug, not Google flakiness.

Download file content with `files get` and `alt=media` instead, which hits the correct `GET /drive/v3/files/{id}?alt=media` content endpoint:

```bash
gws drive files get \
  --params '{"fileId": "FILE_ID", "alt": "media"}' \
  --output ./local_filename.ext
```

This works for any binary (TIFF, npy, etc.). For partial reads of a large file (e.g. just a TIFF header), download then slice locally; gws does not pass through HTTP Range headers.

## Pagination

For large folders, use `--page-all`:

```bash
gws drive files list \
  --params '{"q": "'\''FOLDER_ID'\'' in parents", "pageSize": 100, "fields": "files(id,name)"}' \
  --page-all --page-limit 5 \
  --format table
```

## Useful field sets

- `files(id,name)` -- IDs and names
- `files(id,name,mimeType,size)` -- with type and size
- `files(id,name,owners,modifiedTime)` -- with ownership and dates

## Known folders (CatalystNeuro)

| Folder | ID | Owner | Purpose |
|--------|----| ------|---------|
| data | `1K1Jr4pRF7adQvcVa9KglH7qJ0mpDAu2a` | bdichter@lbl.gov | Conversion data shares from labs (e.g. Olveczky-CN-data-share, Uchida-CN-data-share) |
| NeuroConv_testing_data | `1KaLzvadA9SXQMUY-BzPvNukAGsBMPOtv` | bdichter@lbl.gov | Test data organized by format (Bruker, CaImAn, Thor, SpikeGLX, Plexon, EDF) |

Start from **data** when looking for a specific lab's conversion data.
Start from **NeuroConv_testing_data** when looking for test data by recording format.

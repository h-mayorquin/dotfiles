---
name: mega
description: Download from and upload to MEGA (mega.nz) using the MEGAcmd command-line tool. Use this skill whenever the user mentions MEGA, MEGAcmd, mega.nz, a MEGA link or file-request folder, `mega-get`/`mega-put`/`mega-ls`, or needs to pull down files a collaborator shared on MEGA (or push files up). Also trigger when the user talks about downloading shared data or test data from MEGA, logging into MEGA from the terminal, or setting up the MEGA CLI. Prefer this over the older `megatools` package.
---

# MEGA (MEGAcmd)

Get files in and out of MEGA cloud storage from the terminal. The common job is: a collaborator uploaded files to a web "file request" folder on the user's account, and the user wants them downloaded locally. This skill is scoped to that workflow plus occasional uploads, not the full MEGAcmd feature set (it also does sync, backup, webdav, ftp, which are out of scope here).

Use **MEGAcmd** (`mega-*` commands), not the older `megatools` (`megals`/`megaget`). MEGAcmd has a persistent session, so after one login nothing else needs a password; `megatools` would put the password on every command line.

## The session model (the one thing to understand)

MEGAcmd runs a background daemon (`mega-cmd-server`) that holds a logged-in session in `~/.megaCmd`. You log in **once**, interactively, and from then on every `mega-ls`/`mega-get`/`mega-put` reuses that session with no password. This is why the skill can drive MEGA non-interactively after the user has logged in once.

**Always check the session first:**

```bash
mega-whoami
```

If it prints the account email, you are logged in and can run any command below directly. If it errors or shows nothing, the user must log in (next section) before you can do anything.

## Logging in (must be done by the user, interactively)

Login needs a real terminal so the password prompt is hidden. It will **fail** if run non-interactively (e.g. through a tool that has no TTY) with `Extra args required in non-interactive mode`. **Never** pass the password as a command argument (`mega-login email password`) — it lands in shell history, the process list, and any transcript.

Tell the user to run, in a normal terminal:

```bash
mega-cmd                       # opens the MEGA CMD> shell
# then at the prompt:
login their-email@example.com  # prompts for password (hidden); also asks for 2FA code if enabled
quit                           # leaves the shell; the daemon keeps the session alive
```

After that, `mega-whoami` works everywhere and the skill takes over.

## Core commands (the five you actually need)

```bash
mega-ls /                                  # list cloud root
mega-ls -lR -h /folder                     # recursive listing with sizes (note: -R, NOT --recursive)
mega-get "/remote/path/file.ext" /local/dir/   # download a file (give an explicit local destination)
mega-get "/remote/folder" /local/dir/          # download a whole folder
mega-put /local/file "/remote/folder"      # upload
mega-df -h                                 # storage quota (used / total)
mega-export -a "/remote/path"              # create a public download link for something you own
```

Downloads print a progress bar and finish with `Download finished: <path>`. Check available space with `df -h` before pulling anything large; MEGA does not warn you.

## The collaborator file-share workflow

This is the main use case, end to end:

1. The user creates a **file request** on the MEGA **web** interface (Cloud Drive, right-click a folder, "File request"). This produces a `mega.nz/filerequest/...` upload link that the collaborator uses with no MEGA account. The **CLI cannot create file requests** — that is web-only. Important: file requests are not offered on folders that are inside a synced MEGAsync folder; the folder must be a plain Cloud Drive folder.
2. The collaborator uploads; the files land in that cloud folder.
3. You (the skill) find and download them:

```bash
mega-ls -lR -h /the_folder                 # see what arrived and how big
df -h ~                                      # confirm local space for big files
mega-get "/the_folder/their_file.ext" ~/Downloads/
```

For a big file, download the small files first and confirm the large one is worth the disk/bandwidth before pulling it.

## Gotchas (the things that waste time)

- **Recursive flag is `-R`**, not `--recursive` (`mega-ls -lR /folder`). `--recursive` errors.
- **Login needs a TTY.** Non-interactive `mega-login` fails; use the interactive `mega-cmd` shell. Never inline the password.
- **`mega-get` needs an explicit local destination** directory or path.
- **File requests are web-only** and not available on synced-folder paths.
- **MEGAcmd is a separate session** from the MEGAsync desktop app; logging into one does not log into the other (harmless, just expect a second login).

## Installing MEGAcmd (only if `mega-whoami` says command not found)

Use the official package matched to the OS version. On Ubuntu, the MEGA repo entry installed with the desktop app may be pinned to an older release (e.g. `xUbuntu_22.04`), so prefer the direct `.deb` for the actual version:

```bash
# replace 24.04 with the output of: . /etc/os-release; echo $VERSION_ID
wget -O /tmp/megacmd.deb https://mega.nz/linux/repo/xUbuntu_24.04/amd64/megacmd-xUbuntu_24.04_amd64.deb
sudo apt install -y /tmp/megacmd.deb
```

The 22.04 build from `sudo apt install megacmd` also works on newer Ubuntu if the direct `.deb` URL 404s. After installing, the user does the interactive login once (above).

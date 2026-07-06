# Project Notes

## Goal

This repository preserves the VoHive release repository state needed for NAS deployment and rollback.

## Stack

- Shell installer scripts
- systemd service file
- Markdown documentation
- JSON version metadata

## Current State

- Backed up from upstream `iniwex5/vohive-release` release `v1.5.4`.
- Upstream tag commit: `44371d9074832556e2cf0434bfb3e33c995c0d01`.
- This repository is intended as a preservation mirror, so keep changes minimal.

## Core Rules

- Preserve installer behavior unless explicitly changing deployment logic.
- Do not remove historical release files without a clear replacement.
- For NAS deployment of private repositories, prefer SSH clone URLs over HTTPS.
- If Codex commits changes, use Chinese commit messages by default.

## Common Commands

```sh
sh tests/installer_compat_test.sh
sh install.sh
sh uninstall.sh
```

## Important Files

- `install.sh`: installer entrypoint
- `uninstall.sh`: uninstall entrypoint
- `versions.json`: release channel metadata
- `systemd/vohive.service`: service definition
- `docs/`: quickstart, upgrade, and rollback notes

## Collaboration

- Check `git status --short` before edits.
- Avoid broad refactors in this preservation repository.
- Keep release provenance notes current after important backup milestones.

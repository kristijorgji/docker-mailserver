# Scripts

Host-side helpers for docker-mailserver installs and local development.

| Script                                   | Audience      | Command                                 |
| ---------------------------------------- | ------------- | --------------------------------------- |
| [`dev-init.sh`](dev-init.sh)             | Developers    | `bash scripts/dev-init.sh`              |
| [`check-hooks.sh`](check-hooks.sh)       | Developers    | `make verify-hooks`                     |
| [`up.sh`](up.sh)                         | Install / ops | `./scripts/up.sh`                       |
| [`down.sh`](down.sh)                     | Install / ops | `./scripts/down.sh`                     |
| [`backup/backup.sh`](backup/backup.sh)   | Install / ops | `./scripts/backup/backup.sh`            |
| [`backup/restore.sh`](backup/restore.sh) | Install / ops | `./scripts/backup/restore.sh <archive>` |

Git hook setup is **not** part of [`install.sh`](../install.sh). Run `bash scripts/dev-init.sh` after cloning the repository.

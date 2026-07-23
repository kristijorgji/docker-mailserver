# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This is a single file for the **entire release history** (all versions together).
GitHub Release notes for a tag are extracted from the matching section via
[`ci/extract-changelog-section.sh`](ci/extract-changelog-section.sh).

## [0.1.0] - 2026-07-22

### Added

- Inbound MX rate limits (Postfix anvil on port 25, configurable, on by default)
- Outbound per-user/domain send rate limits (Postfix anvil + postfwd, on by default)
- Mailbox quotas with per-account and per-domain overrides (on by default, 5G default)
- Dovecot Sieve + Junk folder when Rspamd is enabled (`enable_rspamd_junk_sieve`)
- Postscreen + DNSBL spam protection (Tier 0) and OpenDKIM outbound signing
- Optional Rspamd, postgrey, and SnappyMail webmail (`enable_*` toggles in `vars.yml`)
- `scripts/up.sh` / `scripts/down.sh` — auto-wire SnappyMail when `enable_webmail: true`
- `scripts/backup/backup.sh` and `scripts/backup/restore.sh` for MySQL + maildir backups
- `scripts/dev-init.sh` / `make dev-init` — clone bootstrap (git hooks, vault template, data dirs)
- Markdown lint (`make lint-markdown` / `fix-markdown`), pre-commit hooks, CI `lint-markdown` job
- Certbot Ansible role; pinned Ubuntu 22.04 digest + weekly drift workflow
- Pre-release Hub tags: `:edge` / `:sha-*` on merge to main; local `:dev-*` via `ci/push-to-docker.sh`
- CI: smoke, open-relay, IMAP auth, rate limits, quotas, upsert, backup/restore, Rspamd render
- `CHANGELOG.md` and automated GitHub Release notes on `v*` tag publish
- `docs/repository-layout.md` (configs map, compose dev vs release vs webmail overlay)
- Multi-arch Docker Hub images (`linux/amd64` + `linux/arm64`) for `v*`,
  `:edge` / `:sha-*`, and local `:dev-*` pushes

### Changed

- Dev compose mounts `./docker-data` at `/dev-docker-data`; entrypoint resolves Ansible root
- Release compose requires `MAILSERVER_MAILS_PATH` from `.env` (no YAML default)
- Idempotent MySQL provisioning via `INSERT ... ON DUPLICATE KEY UPDATE` in `./update.sh`
- README overhaul: TOC, spam/Junk, TLS modes, backup, quotas, rate limits, pre-release images
- CI badge switched to GitHub Actions workflow status API
- Hub multi-arch via shared `.github/actions/docker-hub-build-push`
  (override locally with `PUSH_PLATFORMS=linux/amd64`)
- Entrypoint refuses `mysqld --initialize` when `/var/lib/mysql` is non-empty
  but missing the system schema (avoids wiping a broken/upgrading datadir)

### Fixed

- Self-signed certificate script exit code (`gen-certificate.sh`)
- Let's Encrypt issuance skips when certificates already exist

### Security

- Least-privilege MySQL user in `vault.example.yml` (not `root`)
- Dovecot system (PAM) auth disabled for virtual-user-only setups
- Boot fails when default `CHANGE_ME` / weak passwords remain in `vault.yml`
- Maildir permissions tightened to `750`

## [0.0.5] - 2026-07-09

### Added

- SendGrid sender-dependent outbound relay
- Discard transports for noreply-style addresses
- Vault-driven mail account / domain provisioning

## [0.0.4] - 2022-07-26

### Added

- Documentation for email aliases (redirects)

## [0.0.3] - 2022-07-26

### Added

- Runtime script to update users and domains without rebuilding the image (`update.sh`)

## [0.0.2] - 2022-07-26

### Added

- Mail client setup documentation

### Fixed

- Maildir permissions when the mail volume is mounted from the host

## [0.0.1] - 2022-07-25

### Changed

- Install script refinements for first-time setup

## [0.0.0] - 2022-07-25

### Added

- Initial docker-mailserver: Postfix, Dovecot, MySQL, Ansible provisioning
- `install.sh` one-shot install flow and Docker Hub publish on tag

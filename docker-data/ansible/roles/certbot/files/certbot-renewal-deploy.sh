#!/usr/bin/env bash
# Certbot renewal deploy hook: reload mail services after certificate renewal.
set -euo pipefail

service postfix reload
service dovecot reload

#!/usr/bin/env bash
set -euo pipefail

DOMAIN=$1
PATH_SSL=$2

PATH_KEY="${PATH_SSL}/privkey.pem"
PATH_FULLCHAIN_CRT="${PATH_SSL}/fullchain.pem"
PATH_CRT="${PATH_SSL}/cert.pem"

mkdir -p "$PATH_SSL"

if [ -f "$PATH_KEY" ] && [ -f "$PATH_FULLCHAIN_CRT" ]; then
  echo "Self-signed certificate already exists for ${DOMAIN}, skipping"
  exit 0
fi

openssl req \
  -newkey rsa:2048 \
  -x509 \
  -nodes \
  -keyout "${PATH_KEY}" \
  -new \
  -out "${PATH_FULLCHAIN_CRT}" \
  -subj "/CN=${DOMAIN}" \
  -reqexts SAN \
  -extensions SAN \
  -config <(cat /etc/ssl/openssl.cnf \
    <(printf '[SAN]\nsubjectAltName=%s' "DNS:*.${DOMAIN},DNS:${DOMAIN}")) \
  -sha256 \
  -days 3650

cp "${PATH_FULLCHAIN_CRT}" "${PATH_CRT}"
echo "Created self-signed certificate for ${DOMAIN}"
exit 0

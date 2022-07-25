#!/usr/bin/env bash

DOMAIN=$1
PATH_SSL=$2

PATH_KEY="${PATH_SSL}/privkey.pem"
PATH_FULLCHAIN_CRT="${PATH_SSL}/fullchain.pem"
PATH_CRT="${PATH_SSL}/cert.pem"

if [ ! -d $PATH_SSL ]
then
    mkdir -p $PATH_SSL
fi

if [ ! -f $PATH_KEY ] || [ ! -f $PATH_FULLCHAIN_CRT ]
then
  openssl req \
		-newkey rsa:2048 \
		-x509 \
		-nodes \
		-keyout ${PATH_KEY} \
		-new \
		-out ${PATH_FULLCHAIN_CRT} \
		-subj /CN="${DOMAIN}" \
		-reqexts SAN \
		-extensions SAN \
		-config <(cat /etc/ssl/openssl.cnf \
			<(printf '[SAN]\nsubjectAltName=%s' "DNS:*.${DOMAIN},DNS:${DOMAIN}")) \
		-sha256 \
		-days 3650
  cp "${PATH_FULLCHAIN_CRT}" "${PATH_CRT}"
fi

exit 1

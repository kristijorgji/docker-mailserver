#!/usr/bin/env bash

LETSENCRYPT_PATH="/etc/letsencrypt/live"

if [ -z "$CERTBOT_ADMIN_EMAIL" ]; then
  echo "Missing required environment variable CERTBOT_ADMIN_EMAIL";
  exit 1;
fi

if [ -n "$PRE_HOOK" ]; then
  echo -e "Executing pre hook [$PRE_HOOK]\n"
  eval "$PRE_HOOK"
fi

for domain in "${@:1}"
do
    echo -e "Creating certificate for $domain\n"

    if compgen -G "${LETSENCRYPT_PATH}/$domain*" > /dev/null; then
      echo -e "Already exists, skipping\n"
      continue;
    fi

    certbot certonly --standalone \
      --preferred-challenges http \
      -d $domain \
      --cert-name $domain \
      -m ${CERTBOT_ADMIN_EMAIL} \
      --agree-tos \
      --staple-ocsp
done

if [ -n "$POST_HOOK" ]; then
  echo -e "Executing post hook [$POST_HOOK]\n"
  eval "$POST_HOOK"
fi

# How to test and troubleshoot the setup

## Smoke tests

With the stack running (`docker compose up -d` and `./update.sh`):

```shell
bash tests/smoke.bash
```

CI runs the same suite plus backup/restore and idempotent `update.sh`.

## Sending test email

Use telnet on port 25 and speak SMTP, or use the helper script:

```shell
bash tests/smtp.bash
```

## Testing Dovecot

Run inside the container (`docker compose exec ms bash`) or from the host with `docker compose exec ms`:

```bash
# test authentication
doveadm auth test me@example.com

# show information about the user (user attributes)
doveadm user -u me@example.com

# show quota for a specific user (requires enable_mailbox_quotas)
doveadm quota get -u me@example.com

# see all received emails
doveadm fetch -u me@example.com "text" ALL
```

## Checking the Postfix-Dovecot MySQL data

```shell
docker compose exec ms mysql --defaults-file=/root/.my.cnf -e "SELECT * FROM mailserver.virtual_domains"
docker compose exec ms mysql --defaults-file=/root/.my.cnf -e "SELECT * FROM mailserver.virtual_users"
docker compose exec ms mysql --defaults-file=/root/.my.cnf -e "SELECT * FROM mailserver.virtual_aliases"
```

## Troubleshooting

To see only Postfix non-default config values:

```shell
docker compose exec ms postconf -n
```

To see only Dovecot non-default config values:

```shell
docker compose exec ms doveconf -n
```

## Logs

`/var/log/mail.log`

`/var/log/dovecot.log`

Dovecot writes logs here as well:

`/var/log/auth.log`

View from the host:

```shell
docker compose exec ms tail -f /var/log/mail.log
```

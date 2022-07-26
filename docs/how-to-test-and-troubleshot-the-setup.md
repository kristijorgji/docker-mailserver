# How to test the setup

## Sending test email

You can use telnet at port 25 and use via normal smtp protocal, or use helper script like
```shell
bash tests/smpt.bash
```

## Testing dovecot

```bash
# test authentication
doveadm auth test me@kristijorgji.com

# show informations about the user (user attributes)
doveadm user -u me@kristijorgji.com

# show quota for a specific user
doveadm quota get -u me@kristijorgji.com

# see all received emails
doveadm fetch -u me@kristijorgji.com "text" ALL
```

## Checking the postfix-dovecot mysql data

```shell
password=supersecret
mysql -u root -p$password -e "select * from mailserver.virtual_domains"
mysql -u root -p$password -e "select * from mailserver.virtual_users"
mysql -u root -p$password -e "select * from mailserver.virtual_aliases"
```

## Troubleshooting

To see only postfix non default config values
```
postconf -n
```

To see only dovecot non default config values

```
doveconf -n
```

# Logs

`/var/log/mail.log`

`/var/log/dovecot.log`

dovecot writes logs here as well

`/var/log/auth.log`

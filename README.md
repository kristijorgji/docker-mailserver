# docker-mailserver

================
!!! WORK IN PROGRESS !!!
================

Docker image that will provide out of the box mailserver using

* postfix
* dovecot
* IMAP and POP so you can use mail clients like Thunderbolt with ease
* roundcube UI to send and check the received emails

# How to use

TODO COMING SOON the docker image after published

The client of this project needs to change only the mounted `configs` folder where they have full control of postfix, dovecot templates they would like to change
as well as all the vars passed

Everything else is auto-generated during the start of the container including the self signed ssl certificates with the domain name provided
The provisioning is done via ansible and jinja2 templates, that is why the configuration templates end in `.j2` extension

# How to develop locally

Run `make ress` to create a docker image and log into one container created from the created image

Make sure that configs/vars/vars.yml `env` is set to `local`

Afterward you can execute the boot provisioning by going to 
`cd /dev-docker-data`

then `bash entrypoint.sh`

Or if you want only to execute the ansible provisioning, can do:
```shell
cd /dev-docker-data/ansible
ansible-playbook playbook.yml
```

# [How to test and troubleshoot the setup](docs/how-to-test-and-troubleshot-the-setup.md)

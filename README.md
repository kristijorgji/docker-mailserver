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

Then you can test with telnet and other tools if mailservice is working fine.


# docker-mailserver

A docker image that will provide an out of the box mailserver using

* postfix
* dovecot
* IMAP and POP with mysql driver so you can use mail clients like Thunderbird with ease
* Multiple domains supported, you can have send or receive emails coming for both me@example.com and me@whatever.com
* roundcube UI to send and check the received emails [WIP] 

# How to use

First execute the following command to download and install the tool.
You can change `docker-mailserver` in the third line with whatever path you want for the install

```shell
curl -LJO https://raw.githubusercontent.com/kristijorgji/docker-mailserver/main/install.sh \
 && chmod a+x install.sh \
 && ./install.sh docker-mailserver
```

After the installation you will see a message of what configurations you can make before starting the docker container of the mailserver

You can modify those variables to your wishes, those involve things like
* your mailserver domain name
* your mailserver supported domains (can have more than one)
* your mailserver users
* etc

If you want to make more changes to the configurations of postfix/dovecot or any tool, just modify the `jinja2` templates at configs folder after the tool installs the mailserver.


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

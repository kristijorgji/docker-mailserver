FROM ubuntu:22.04

USER root

RUN apt-get update -y

# troubleshooting tools
RUN apt-get install -y nano lsof telnet

# needed utils for template ninja2 parsing and other tasks
RUN apt install ansible -y

# install postfix
RUN apt-get install postfix postfix-mysql -y

# install mysql for storing postfix and dovecot user domains aliases configs
RUN apt-get install mysql-server -y

# install some tools needed by ansible
RUN apt install python3-pip -y && python3 -m pip install PyMySQL

# install dovecat and required tools
RUN apt-get install dovecot-core dovecot-pop3d dovecot-imapd dovecot-common dovecot-lmtpd -y

# copy ansible provision codes
#COPY ./docker-data /docker-data

ADD docker-data /docker-data
WORKDIR /docker-data
ENTRYPOINT ["/docker-data/entrypoint.sh"]

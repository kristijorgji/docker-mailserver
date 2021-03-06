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
RUN apt-get install dovecot-core dovecot-pop3d dovecot-imapd dovecot-mysql dovecot-common dovecot-lmtpd -y

# install letsencrypt and certbot for the ssl certs
RUN apt-get install certbot -y

# Use syslog-ng to get Postfix logs (rsyslog uses upstart which does not seem
# to run within Docker).
RUN apt-get install -q -y syslog-ng

# copy ansible provision codes
#COPY ./docker-data /docker-data

ADD docker-data /docker-data
WORKDIR /docker-data
ENTRYPOINT ["/docker-data/entrypoint.sh"]

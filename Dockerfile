FROM ubuntu:22.04

USER root

RUN apt-get update -y

# troubleshooting tools
RUN apt-get install -y nano lsof telnet

RUN apt-get install postfix postfix-mysql -y

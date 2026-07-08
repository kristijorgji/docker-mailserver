#!/usr/bin/env bash

docker-compose exec -T ms bash -c \
  "service mysql start && cd ansible && ansible-playbook playbook.yml --tags='db-provision,postfix-provision,reload'"

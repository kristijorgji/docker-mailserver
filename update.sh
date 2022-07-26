#!/usr/bin/env bash

docker-compose exec ms /bin/bash -c "cd ansible; ansible-playbook playbook.yml --tags='postfix-provision,reload'"

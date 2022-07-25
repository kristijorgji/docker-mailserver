#!/bin/bash

script_directory="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_directory}/common.sh"

declare -a requiredEnv=(
  "IMAGE_NAME"
  "DOCKER_HUB_USERNAME"
  "DOCKER_HUB_AUTH"
)
checkEnvVars "${requiredEnv[@]}"

tag=$1
rim="${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:$tag"

if [ -n "$1" ]; then
		echo "Building and pushing docker image to hub tagged as $rim"

		echo "${DOCKER_HUB_AUTH}" | docker login --username "${DOCKER_HUB_USERNAME}" --password-stdin
		docker build -t "$rim" .
		docker push "$rim"
else
    echo "Wrong number of arguments, provide image tag as first arg"
    exit 1
fi

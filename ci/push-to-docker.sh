#!/bin/bash

script_directory="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_directory}/common.sh"

declare -a requiredEnv=(
  "IMAGE_NAME"
  "DOCKER_HUB_EMAIL"
  "DOCKER_HUB_AUTH"
)
checkEnvVars "${requiredEnv[@]}"

tag=$1
imageAndTag=${IMAGE_NAME}:$tag

cat > ~/.dockercfg <<EOF
{
  "https://index.docker.io/v1/": {
    "email": "${DOCKER_HUB_EMAIL}"
    "auth": "${DOCKER_HUB_AUTH}",
  }
}
EOF

if [ -n "$2" ]; then
		echo "Building and pushing docker image to hub tagged as $imageAndTag"
		# shellcheck disable=SC2086
		docker build -t $imageAndTag .
		docker push "$imageAndTag"
fi

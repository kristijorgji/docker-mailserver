#!/usr/bin/env bash
#
# Build and push a pre-release docker-mailserver image to Docker Hub.
#
# Use this during development so a colleague can pull and test on a server
# BEFORE you cut an official release tag (vX.Y.Z). This script does NOT create
# a GitHub Release — that is reserved for .github/workflows/publish.yaml.
#
# Tag convention:
#   vX.Y.Z     Official release — refuse here; use git tag + publish.yaml
#   edge       Moving tip of main — pushed by .github/workflows/push-edge.yml
#   sha-<7hex> Immutable commit pin — also pushed by push-edge.yml
#   dev-<7hex> Local / manual colleague-test builds (this script's default)
#
# Platforms (multi-arch manifest by default):
#   PUSH_PLATFORMS  default linux/amd64,linux/arm64
#   Override e.g. PUSH_PLATFORMS=linux/amd64 for a faster single-arch push
# Keep this default in sync with .github/actions/docker-hub-build-push
# (used by publish.yaml and push-edge.yml).
#
# Required env:
#   IMAGE_NAME           e.g. docker-mailserver
#   DOCKER_HUB_USERNAME  Docker Hub user/org
#   DOCKER_HUB_AUTH      Docker Hub password or access token
#
# Usage:
#   IMAGE_NAME=docker-mailserver \
#   DOCKER_HUB_USERNAME=kristijorgji \
#   DOCKER_HUB_AUTH=... \
#     bash ci/push-to-docker.sh              # pushes :dev-<shortsha> (amd64+arm64)
#     bash ci/push-to-docker.sh sha-abc1234  # explicit non-release tag
#
set -euo pipefail

script_directory="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${script_directory}/common.sh"

declare -a requiredEnv=(
  "IMAGE_NAME"
  "DOCKER_HUB_USERNAME"
  "DOCKER_HUB_AUTH"
)
checkEnvVars "${requiredEnv[@]}"

REPO_ROOT="$(cd "${script_directory}/.." && pwd)"
cd "$REPO_ROOT"

if [ "${#}" -ge 1 ] && [ -n "${1}" ]; then
  tag="$1"
else
  tag="dev-$(git rev-parse --short=7 HEAD)"
fi

if [[ "$tag" =~ ^v[0-9] ]]; then
  echo "ERROR: Release tags matching vX.Y.Z are reserved for publish.yaml."
  echo "  Use a pre-release tag such as dev-<sha> or sha-<sha> instead."
  echo "  To publish an official release: git tag vX.Y.Z && git push origin vX.Y.Z"
  exit 1
fi

PUSH_PLATFORMS="${PUSH_PLATFORMS:-linux/amd64,linux/arm64}"
rim="${DOCKER_HUB_USERNAME}/${IMAGE_NAME}:${tag}"

echo "Building and pushing Docker image to Hub as ${rim}"
echo "Platforms: ${PUSH_PLATFORMS}"
echo "${DOCKER_HUB_AUTH}" | docker login --username "${DOCKER_HUB_USERNAME}" --password-stdin

if ! docker buildx inspect >/dev/null 2>&1; then
  docker buildx create --use --name docker-mailserver-builder >/dev/null
fi

docker buildx build \
  --platform "${PUSH_PLATFORMS}" \
  -t "$rim" \
  --push \
  .

echo "Pushed ${rim} (${PUSH_PLATFORMS})"

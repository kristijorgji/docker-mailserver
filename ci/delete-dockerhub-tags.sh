#!/usr/bin/env bash
#
# List or delete non-production Docker Hub tags for this image.
#
# Defaults:
#   - Match prefixes: dev- only
#   - Dry-run (print what would be deleted); pass --yes to delete
#   - Never delete release tags matching v[0-9]*
#
# Required env (same as ci/push-to-docker.sh):
#   IMAGE_NAME           e.g. docker-mailserver
#   DOCKER_HUB_USERNAME  Docker Hub user/org
#   DOCKER_HUB_AUTH      Docker Hub password or access token
#
# Options:
#   --yes                 Actually delete (otherwise dry-run)
#   --prefixes LIST       Comma-separated prefixes (default: dev-)
#                         Examples: --prefixes dev-,sha-   or   --prefixes dev-,sha-,edge
#   --older-than N        Only tags whose Hub last_updated is older than N days
#   --keep-tag TAG        Keep this tag even if it matches (repeatable)
#   --keep-head-dev       Keep dev-$(git rev-parse --short=7 HEAD) when in a git repo
#   -h, --help            Show help
#
# Usage:
#   IMAGE_NAME=docker-mailserver \
#   DOCKER_HUB_USERNAME=kristijorgji \
#   DOCKER_HUB_AUTH=... \
#     bash ci/delete-dockerhub-tags.sh
#     bash ci/delete-dockerhub-tags.sh --yes
#     bash ci/delete-dockerhub-tags.sh --prefixes dev-,sha- --older-than 14 --yes
#
set -euo pipefail

script_directory="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${script_directory}/common.sh"

REPO_ROOT="$(cd "${script_directory}/.." && pwd)"

DO_DELETE=0
PREFIXES="dev-"
OLDER_THAN_DAYS=""
KEEP_TAGS=()
KEEP_HEAD_DEV=0

usage() {
  sed -n '2,35p' "$0" | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      DO_DELETE=1
      shift
      ;;
    --prefixes)
      PREFIXES="${2:-}"
      shift 2
      ;;
    --older-than)
      OLDER_THAN_DAYS="${2:-}"
      shift 2
      ;;
    --keep-tag)
      KEEP_TAGS+=("${2:-}")
      shift 2
      ;;
    --keep-head-dev)
      KEEP_HEAD_DEV=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      print_error "Unknown argument: $1"
      usage >&2
      exit 1
      ;;
  esac
done

declare -a requiredEnv=(
  "IMAGE_NAME"
  "DOCKER_HUB_USERNAME"
  "DOCKER_HUB_AUTH"
)
checkEnvVars "${requiredEnv[@]}"

if [[ -n "${OLDER_THAN_DAYS}" ]] && ! [[ "${OLDER_THAN_DAYS}" =~ ^[0-9]+$ ]]; then
  print_error "--older-than must be a non-negative integer (days)"
  exit 1
fi

if [[ "${KEEP_HEAD_DEV}" -eq 1 ]]; then
  if git -C "${REPO_ROOT}" rev-parse --short=7 HEAD >/dev/null 2>&1; then
    KEEP_TAGS+=("dev-$(git -C "${REPO_ROOT}" rev-parse --short=7 HEAD)")
  else
    print_error "--keep-head-dev requires a git repository at ${REPO_ROOT}"
    exit 1
  fi
fi

# Split prefixes on commas; allow "edge" as exact name via prefix "edge" matching tag "edge"
IFS=',' read -r -a PREFIX_ARR <<< "${PREFIXES}"
for i in "${!PREFIX_ARR[@]}"; do
  PREFIX_ARR[$i]="$(echo "${PREFIX_ARR[$i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
done

is_release_tag() {
  [[ "$1" =~ ^v[0-9] ]]
}

matches_prefix() {
  local tag="$1"
  local p
  for p in "${PREFIX_ARR[@]}"; do
    [[ -z "$p" ]] && continue
    if [[ "$p" == "edge" ]]; then
      [[ "$tag" == "edge" ]] && return 0
    elif [[ "$tag" == "$p"* ]]; then
      return 0
    fi
  done
  return 1
}

should_keep() {
  local tag="$1"
  local k
  for k in "${KEEP_TAGS[@]+"${KEEP_TAGS[@]}"}"; do
    [[ "$tag" == "$k" ]] && return 0
  done
  return 1
}

echo "Authenticating to Docker Hub API..."
TOKEN="$(
  curl -fsS -X POST "https://hub.docker.com/v2/users/login/" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"${DOCKER_HUB_USERNAME}\",\"password\":\"${DOCKER_HUB_AUTH}\"}" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])'
)"

REPO_PATH="${DOCKER_HUB_USERNAME}/${IMAGE_NAME}"
echo "Listing tags for ${REPO_PATH} (prefixes: ${PREFIXES})"

# Collect matching tags as: name|last_updated_epoch
MATCHES=()
URL="https://hub.docker.com/v2/repositories/${REPO_PATH}/tags?page_size=100"

while [[ -n "${URL}" && "${URL}" != "null" ]]; do
  PAGE="$(curl -fsS -H "Authorization: JWT ${TOKEN}" "${URL}")"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    tag="${line%%|*}"
    updated="${line#*|}"
    if is_release_tag "$tag"; then
      continue
    fi
    if ! matches_prefix "$tag"; then
      continue
    fi
    if should_keep "$tag"; then
      echo "  keep (explicit): ${tag}"
      continue
    fi
    if [[ -n "${OLDER_THAN_DAYS}" ]]; then
      # Hub last_updated is ISO-8601 UTC; compare to now - N days
      cutoff_epoch="$(python3 -c "import time; print(int(time.time()) - int('${OLDER_THAN_DAYS}') * 86400)")"
      tag_epoch="$(python3 -c "import datetime,sys; s=sys.argv[1].replace('Z','+00:00'); print(int(datetime.datetime.fromisoformat(s).timestamp()))" "${updated}")"
      if [[ "${tag_epoch}" -ge "${cutoff_epoch}" ]]; then
        echo "  skip (too recent): ${tag} (${updated})"
        continue
      fi
    fi
    MATCHES+=("${tag}|${updated}")
  done < <(
    python3 -c '
import json,sys
data=json.load(sys.stdin)
for t in data.get("results") or []:
    name=t.get("name") or ""
    updated=t.get("last_updated") or ""
    print(f"{name}|{updated}")
' <<< "${PAGE}"
  )
  URL="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("next") or "")' <<< "${PAGE}")"
done

if [[ "${#MATCHES[@]}" -eq 0 ]]; then
  echo "No matching tags to delete."
  exit 0
fi

echo
echo "Matched ${#MATCHES[@]} tag(s):"
for entry in "${MATCHES[@]}"; do
  echo "  - ${entry%%|*}  (last_updated=${entry#*|})"
done

if [[ "${DO_DELETE}" -ne 1 ]]; then
  echo
  echo "Dry-run only. Re-run with --yes to delete these tags."
  exit 0
fi

echo
echo "Deleting..."
fail=0
for entry in "${MATCHES[@]}"; do
  tag="${entry%%|*}"
  if is_release_tag "$tag"; then
    print_error "Refusing to delete release tag: ${tag}"
    fail=1
    continue
  fi
  code="$(
    curl -sS -o /tmp/dockerhub-delete-tag.out -w "%{http_code}" -X DELETE \
      -H "Authorization: JWT ${TOKEN}" \
      "https://hub.docker.com/v2/repositories/${REPO_PATH}/tags/${tag}/"
  )"
  if [[ "${code}" == "204" || "${code}" == "200" ]]; then
    echo "  deleted ${tag} (HTTP ${code})"
  else
    print_error "Failed to delete ${tag} (HTTP ${code}): $(cat /tmp/dockerhub-delete-tag.out 2>/dev/null || true)"
    fail=1
  fi
done

rm -f /tmp/dockerhub-delete-tag.out
exit "${fail}"

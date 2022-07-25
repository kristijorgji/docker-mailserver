#!/usr/bin/env bash

function print_usage() {
	echo "Usage: $(basename $0) <PATH>"
	echo
	echo '  <PATH>                       The path where to install the project, defaults to docker-mailserver'
}

# Resource: https://stackoverflow.com/a/5947802
color_green='\033[0;32m' # Green
color_red='\033[0;31m' # Red
color_blue='\033[0;34m' # Blue
color_yellow='\033[0;33m' # Yellow
color_cyan='\033[0;36m' # Cyan
color_reset='\033[0m' # No Color

function print_error {
  msg=${1:-'no message'}
  printf "${color_red}[ERROR] ${msg}${color_reset}\n" >&2
}

function print_success {
  msg=${1:-'no message'}
  printf "${color_green}[SUCCESS] ${msg}${color_reset}\n"
}

if [ "${#}" -ne '1' ]; then
	print_error 'Wrong number of arguments'
	print_usage
	exit 1
fi

destdir=${1:-docker-mailserver}

gh_username=kristijorgji
gh_repository=docker-mailserver
repository="https://github.com/$gh_username/$gh_repository"

# install required tools like jq
if ! command -v jq &> /dev/null
then
  echo "Will install required tool jq"
  which -s brew
  if [[ $? != 0 ]] ; then
      # brew is not installed
      apt-get install jq -y
  else
      brew install jq
  fi
fi

echo -e "Getting last tag of the repository $repository \n"
tag=$(curl -s "https://api.github.com/repos/$gh_username/$gh_repository/tags"  | jq -r '.[0].name')
echo "Last tag is $tag"

if [ ! -d $destdir ]
then
    mkdir -p $destdir
fi

echo -e "Downloading last tag $tag then extracting"
filename="$tag.tar.gz"
curl -LO "$repository/archive/refs/tags/$filename"
tar zxvf "$filename" -C "$destdir" --strip-components=1
rm "$filename"

echo -e "Setting up the project"

rm -rf "$destdir/.github"
rm -rf "$destdir/ci"
rm -rf "$destdir/docker-data"
rm -rf "$destdir/docs"
rm -rf "$destdir/tests"
rm "$destdir/.gitignore"
rm "$destdir/docker-compose.yml"
rm "$destdir/Dockerfile"
rm "$destdir/Makefile"
rm "$destdir/README.md"
rm "$destdir/install.sh"
rm "$destdir/configs/vars/local.yml"

mv "$destdir/configs/vars/vault.example.yml" "$destdir/configs/vars/vault.yml"
mv "$destdir/docker-compose.release.yml" "$destdir/docker-compose.yml"

cat <<EOT > "$destdir/.env"
# this env file is used by docker-compose

MAILSERVER_IMAGE=kristijorgji/docker-mailserver:$tag
MAILSERVER_MAILS_PATH=./mail
EOT

__msg="
Congratulations, installation was successful!
Before starting the container via docker-compose you need to edit the following files with your configuration variables:
  $destdir/configs/vars/vars.yml
  $destdir/configs/vars/vault.yml
  $destdir/.env

Afterward do the following:
cd $destdir
docker-compose up -d

That is all, in a couple of minutes the mailserver will be up and running!

You can follow the logs via docker-compose logs -f ms
"
print_success "$__msg"

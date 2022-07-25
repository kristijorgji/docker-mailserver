#!/usr/bin/env bash

function checkEnvVars() {
  requiredEnv=("$@")
  hasMissingEnv=false
  for v in "${requiredEnv[@]}"; do
    if [ -z "${!v-}" ]; then
      print_error "Missing required environment variable ${v}"
      hasMissingEnv=true
    fi
  done

  if [ ${hasMissingEnv} = true ]; then
    exit 1
  fi
}

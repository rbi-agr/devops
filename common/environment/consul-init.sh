#!/usr/bin/env bash

set -e
pushd /bhasai

export VAULT_ADDR="http://127.0.0.1:8200"

# Authenticate using username and password
vault login -method=userpass username=$VAULT_USERNAME password=$VAULT_PASSWORD

export VAULT_TOKEN=$(vault print token)

export IFS=$'\n'
if ! vault kv get kv/env >/dev/null 2>&1; then
  vault kv put kv/env \
    $(grep -v '^#' .env | grep -e '[^[:space:]]' | \
      sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | \
      awk -F '=' '{gsub(/^["'\'']|["'\'']$/, "", $2); data[$1]=$2} END {for (key in data) print key "=" data[key]}')
# create a backup of the original .env
cp .env .env.bak
else 
  # Backup the last file created by Consul 
  if [ -f env.tmp ]; then
      mv env.tmp .env.back
  fi
fi


consul-template \
    -vault-default-lease-duration=10s \
    -vault-renew-token=false  \
    -template "env.tpl:env.tmp:bash -c 'cat /bhasai/env.tmp > /bhasai/.env; echo .env updated '"

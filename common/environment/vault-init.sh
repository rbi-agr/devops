#!/usr/bin/env bash
set -me

if [[ -z $VAULT_USERNAME && -z $VAULT_PASSWORD ]] ; then 
    echo "VAULT_USERNAME and VAULT_PASSWORD are not set"
    exit 1
fi

vault server -config=/vault/config/vault.json &

sleep 2

export VAULT_ADDR="http://127.0.0.1:8200"
VAULT_HEALTH_URL="$VAULT_ADDR/v1/sys/seal-status"
while true; do
    response=$(wget -qO- "$VAULT_HEALTH_URL")

    # Check the exit status of wget to handle errors
    if [ $? -ne 0 ]; then
        echo "Waiting for Vault to be ready"
    else
        initialized=$(echo "$response" | jq -r '.initialized')
        sealed=$(echo "$response" | jq -r '.sealed')
        echo "Vault Status - Initialized: $initialized, Sealed: $sealed"
        break
    fi

    sleep 2
done

if [ "$initialized" = false ]; then 
vault operator init > /vault/file/generated_keys.txt
fi
if [ "$sealed" = true  ]; then 
# Parse unsealed keys
while IFS= read -r line; do
    key=$(echo "$line" | cut -c15-)
    if [ -n "$key" ]; then
        vault operator unseal "$key"
    fi
done <  <(grep "Unseal Key " /vault/file/generated_keys.txt)
fi


# Get root token
VAULT_TOKEN=$(grep "Initial Root Token: " < /vault/file/generated_keys.txt | cut -c21- )
export VAULT_TOKEN

if vault secrets list | grep -q "kv/"; then
    echo "KV version 2 secrets engine is already enabled."
else
    vault secrets enable -version=2 kv
fi

if ! vault auth list | grep -q "userpass/"; then
    vault auth enable userpass
else
    echo "userpass authentication method is already enabled."
fi

if ! vault policy list | grep -q "admin-policy"; then

    vault policy write admin-policy /vault/policies/admin-policy.hcl
else
    echo "admin-policy already exists."
fi


if ! vault read auth/userpass/users/"$VAULT_USERNAME" > /dev/null 2>&1; then
    vault write auth/userpass/users/"$VAULT_USERNAME" \
        password="$VAULT_PASSWORD" \
        policies=admin-policy
else
    echo "User $VAULT_USERNAME already exists."
fi

/bhasai/consul-init.sh &

fg %1

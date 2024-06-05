#!/bin/bash

set -eo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_ROOT=$(cd $SCRIPT_DIR/../../ && pwd && cd --)

echo "Setup webhook"
if ! command -v webhook &> /dev/null; then 
    echo "Installing webhook"; 
sudo -- sh -c  'curl -sSL  https://github.com/adnanh/webhook/releases/download/2.8.1/webhook-linux-amd64.tar.gz | \
tar -zxvf - --strip-components=1 --directory /usr/local/bin/  webhook-linux-amd64/webhook' 
else 
    echo "Webhook is already installed"; 
fi

echo "Starting  Webhook"
source <(grep "^WEBHOOK_PASSWORD=" .env)
if [ -z "$WEBHOOK_PASSWORD" ]; then
    echo "ERROR: WEBHOOK_PASSWORD is not defined in .env"
    exit 1
fi
tmux kill-session -t webhook-session 2> /dev/null && echo "Existing session 'webhook-session' killed" || true
sed "s|\$PROJECT_ROOT|${PROJECT_ROOT}|g" $PROJECT_ROOT/scripts/webhook/hooks.json.template > $PROJECT_ROOT/scripts/webhook/hooks.json

tmux new-session -c "$PROJECT_ROOT" -d -s webhook-session "export WEBHOOK_PASSWORD=$WEBHOOK_PASSWORD ; webhook -hooks $PROJECT_ROOT/scripts/webhook/hooks.json -verbose -template 2>&1 | tee -a \"$PROJECT_ROOT/deploy.log\"; bash"
echo "Webhook started"
#!/bin/bash

set -eo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_ROOT=$(cd $SCRIPT_DIR/../../ && pwd && cd --)
SERVICE_FILE="/etc/systemd/system/webhook.service"
TEMPLATE_FILE="$PROJECT_ROOT/scripts/webhook/webhook.service.template"


echo "Setup webhook"
if ! command -v webhook &> /dev/null; then 
    echo "Installing webhook"; 
sudo -- sh -c  'curl -sSL  https://github.com/adnanh/webhook/releases/download/2.8.1/webhook-linux-amd64.tar.gz | \
tar -zxvf - --strip-components=1 --directory /usr/local/bin/  webhook-linux-amd64/webhook' 
else 
    echo "Webhook is already installed"; 
fi


echo "Creating systemd service file"
cp "$TEMPLATE_FILE" "$SERVICE_FILE"
echo "Systemd service file created"

source <(grep "^WEBHOOK_PASSWORD=" .env)
if [ -z "$WEBHOOK_PASSWORD" ]; then
    echo "ERROR: WEBHOOK_PASSWORD is not defined in .env"
    exit 1
fi
source <(grep "^WEBHOOK_USER=" .env)
source <(grep "^WEBHOOK_GROUP=" .env)

sed "s|\$PROJECT_ROOT|${PROJECT_ROOT}|g" $PROJECT_ROOT/scripts/webhook/hooks.json.template > $PROJECT_ROOT/scripts/webhook/hooks.json

sed -i "s|\${SCRIPT_DIR}|$SCRIPT_DIR|g" "$SERVICE_FILE"
sed -i "s|\${PROJECT_ROOT}|$PROJECT_ROOT|g" "$SERVICE_FILE"
sed -i "s|\${WEBHOOK_USER}|${WEBHOOK_USER:-ubuntu}|g" "$SERVICE_FILE"
sed -i "s|\${WEBHOOK_GROUP}|${WEBHOOK_GROUP:-ubuntu}|g" "$SERVICE_FILE"
sed -i "/\[Service\]/a Environment=\"WEBHOOK_PASSWORD=$WEBHOOK_PASSWORD\"" "$SERVICE_FILE"


# Reload systemd to recognize the new or changed service file
echo "Reloading daemon"
sudo systemctl daemon-reload

# Restart service if already running, otherwise start it
if sudo systemctl is-active --quiet webhook.service; then
    echo "Restarting webhook service"
    sudo systemctl restart webhook.service
else
    echo "Starting webhook service"
    sudo systemctl enable --now webhook.service
fi


if sudo systemctl is-active --quiet webhook.service; then
    echo "Webhook service started successfully"
else
    echo "Failed to start webhook service"
    exit 1
fi

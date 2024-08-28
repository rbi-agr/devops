#!/bin/bash

PROMPT_DOCKER_VOLUME="Enter the name of docker volume which you want to copy: " 
PROMPT_ERROR_BLANK="Error: docker volume name cannot be blank."
PROMPT_NEW_VOLUME_NAME="Enter the name which should be used for migrated volume: "
PROMPT_ERROR_VOLUME="Error: new docker volume name cannot be blank."
PROMPT_TARGET_HOST_ADDRESS="Enter the target host address (use localhost to copy in same machine): "
PROMPT_TAGET_HOST_USER="Enter the target host user (e.g., ubuntu): "
PROMPT_ERROR_TARGET_HOST="Error: target host user cannot be blank."
PROMPT_SSH_KEY_PATH="Enter the path of your ssh private key file: "
PROMPT_ERROR_SSH_KEY_PATH="Error: path to sSH private key file cannot be blank."
PROMPT_CLEANING_UNCESSARY_FILES="Cleaning up unnecessary files"
PROMPT_ERROR_VOLUME_NOT_FOUND="Volume with name provided does not exist"
SOURCE_HOST_ADDRESS="localhost"
SOURCE_HOST_USER="$USER"
PROMPT_ERROR_VOLUME_EXISTS="Error: A volume with the name provided already exists on the target host."


# Environment check
read -p "$PROMPT_DOCKER_VOLUME" current_volume_name
if [[ -z $current_volume_name ]]; then
  echo "$PROMPT_ERROR_BLANK"
  exit 1
fi

# Check if the Docker volume exists
if ! docker volume ls --format '{{.Name}}' | grep -q "^${current_volume_name}$"; then
  echo "$PROMPT_ERROR_VOLUME_NOT_FOUND"
  exit 1
fi

read -p "$PROMPT_NEW_VOLUME_NAME" new_volume_name
if [[ -z $new_volume_name ]]; then
  echo "$PROMPT_ERROR_VOLUME"
  exit 1
fi

read -p "$PROMPT_TARGET_HOST_ADDRESS" TARGET_HOST_ADDRESS
if [[ -z $TARGET_HOST_ADDRESS ]]; then
  echo "$PROMPT_ERROR_TARGET_HOST"
  exit 1
fi

read -p "$PROMPT_TAGET_HOST_USER" TARGET_HOST_USER
if [[ -z $TARGET_HOST_USER ]]; then
  echo "$PROMPT_ERROR_TARGET_HOST"
  exit 1
fi

if [[ $SOURCE_HOST_ADDRESS != $TARGET_HOST_ADDRESS ]]; then
  read -p "$PROMPT_SSH_KEY_PATH" SSH_PRIVATE_KEY_FILE
  if [[ -z $SSH_PRIVATE_KEY_FILE ]]; then
    echo "$PROMPT_ERROR_SSH_KEY_PATH"
    exit 1
  fi
fi


if ssh -i "$SSH_PRIVATE_KEY_FILE" "$TARGET_HOST_USER@$TARGET_HOST_ADDRESS" "docker volume ls --format '{{.Name}}' | grep -q '^${new_volume_name}$'"; then
  echo "$PROMPT_ERROR_VOLUME_EXISTS"
  exit 1
fi
echo "------------------------------------------------------------------------------"


# Export the volume from the host machine
echo "Exporting volume $current_volume_name from local machine"
mkdir -p $HOME/docker-volume-backup
docker run \
  --rm \
  -v $current_volume_name:/volume-backup-source \
  -v $HOME/docker-volume-backup:/volume-backup-target \
  busybox \
  sh -c 'cd /volume-backup-source && tar cf /volume-backup-target/backup.tar .'

if [[ $? -eq 0 ]]; then
  echo "Volume export of $current_volume_name successful"
else
  echo "Volume export of $current_volume_name failed"
  exit 1
fi

# Verify if Source and target are same
if [[ $SOURCE_HOST_ADDRESS == $TARGET_HOST_ADDRESS ]]; then
  echo "Source and target addresses are the same. Migrating within the same machine."
  echo "Creating volume $new_volume_name"
  
  docker volume create $new_volume_name
  if [[ $? -eq 0 ]]; then
    echo "Volume $new_volume_name created successfully"
  else
    echo "Failed to create volume $new_volume_name"
    exit 1
  fi

  echo "Restoring backup to volume $new_volume_name"
  docker run \
    --rm \
    -v $new_volume_name:/volume-backup-target \
    -v $HOME/docker-volume-backup:/volume-backup-source \
    busybox \
    sh -c 'cd /volume-backup-target && tar xf /volume-backup-source/backup.tar .'

  if [[ $? -eq 0 ]]; then
    echo "Backup restored to volume $new_volume_name successfully"
  else
    echo "Failed to restore backup to volume $new_volume_name"
    exit 1
  fi
  
  echo "$PROMPT_CLEANING_UNCESSARY_FILES"
  sudo rm -rf $HOME/docker-volume-backup

else
  # Transfer the exported volume to the new address
  echo "Transferring exported volume $current_volume_name from local machine to $TARGET_HOST_ADDRESS"
  ssh -i "$SSH_PRIVATE_KEY_FILE" "$TARGET_HOST_USER@$TARGET_HOST_ADDRESS" 'mkdir -p $HOME/docker-volume-backup' > /dev/null 2>&1
  scp -i "$SSH_PRIVATE_KEY_FILE" "$HOME/docker-volume-backup/backup.tar" \
    "$TARGET_HOST_USER@$TARGET_HOST_ADDRESS:/home/$TARGET_HOST_USER/docker-volume-backup/backup.tar" > /dev/null 2>&1

  if [[ $? -eq 0 ]]; then
    echo "Transfer of volume $current_volume_name to $TARGET_HOST_ADDRESS successful"
  else
    echo "Transfer of volume $current_volume_name to $TARGET_HOST_ADDRESS failed"
    exit 1
  fi

  # Restore the backup
  echo "Creating volume $new_volume_name on $TARGET_HOST_ADDRESS"
  echo "Restoring backup"
  ssh -i "$SSH_PRIVATE_KEY_FILE" "$TARGET_HOST_USER@$TARGET_HOST_ADDRESS" "\
  docker volume create $new_volume_name \
  && docker run \
    --rm \
    -v $new_volume_name:/volume-backup-target \
    -v \$HOME/docker-volume-backup/:/volume-backup-source \
    busybox \
    sh -c 'cd /volume-backup-target && tar xf /volume-backup-source/backup.tar .'" > /dev/null 2>&1

  if [[ $? -eq 0 ]]; then
    echo "Volume $new_volume_name created and backup restored successfully on $TARGET_HOST_ADDRESS"
  else
    echo "Volume creation or backup restoration on $TARGET_HOST_ADDRESS failed"
    exit 1
  fi

  # Clean up residual files
  echo "Cleaning up unnecessary files"
  sudo rm -rf $HOME/docker-volume-backup
  ssh -i "$SSH_PRIVATE_KEY_FILE" "$TARGET_HOST_USER@$TARGET_HOST_ADDRESS" 'rm -rf $HOME/docker-volume-backup' > /dev/null 2>&1
fi

echo "Successfully migrated docker volume $current_volume_name from $SOURCE_HOST_ADDRESS to $TARGET_HOST_ADDRESS"

#!/bin/bash

# Prompt messages
PROMPT_SERVICE_NAME="Enter Service Name: "
PROMPT_IMAGE_NAME="Enter Image NAME: "
PROMPT_SERVICE_PORT="Enter Service Port: "
PROMPT_FOLDER_NAME="Enter the project and service name in the format project/service_name (e.g. common/hello): "
PROMPT_ABORTING="Aborting."
EXPOSE_SERVICE="Enter folder/service_name to expose (e.g. common/hello): "
ENTER_YOUR_CHOICE="Enter your choice: "
OUTPUT_INVALID_INPUT="Invalid input. Returning to the main menu."
OUTPUT_RETURN_MAIN_MENU="Returning to the main menu."
OUTPUT_SERVICE_NOT_FOUND="Service not found in docker-compose.yaml."
OUTPUT_SERVICE_ONBOARDED="Onboarded service named: "
OUTPUT_INVALID_INPUT=$'\nInvalid input, try again.\n'

# Define an array for menu options
MENU_OPTIONS=(
  "Onboard a service"
  "Expose a service using Caddy"
  "Abort"
)

# Function to validate that the input is a number
validate_number() {
  if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Invalid input. It must be a number."
    return 1
  else
    return 0
  fi
}

# Function to prompt the user for input and validate it
prompt_input() {
  local prompt_message=$1
  local validation_function=$2
  local input_variable=$3
  local input_value

  while true; do
    read -p "$prompt_message" input_value
    if [ -z "$validation_function" ] || $validation_function "$input_value"; then
      eval "$input_variable='$input_value'"
      break
    else
      echo "$OUTPUT_INVALID_INPUT"
    fi
  done
}

# Function to create or update docker-compose.yaml
update_docker_compose() {
  local service_name=$1
  local image_name=$2
  local output_dir=$3
  local template_file="templates/application.yaml"
  local output_file="$output_dir/docker-compose.yaml"
  local sd_file="$output_dir/docker-compose.SDC.yaml"

  mkdir -p "$output_dir"

  # Read the template content
  local template_content
  template_content=$(cat "$template_file")

  # Convert SERVICE_NAME_ to uppercase for environment variables
  local service_name_upper
  service_name_upper=$(echo "$service_name" | tr '[:lower:]' '[:upper:]')

  # Replace SERVICE_NAME_ with the uppercase version
  template_content="${template_content//SERVICE_NAME_/${service_name_upper}_}"

  # Replace remaining SERVICE_NAME with the original service name (lowercase)
  template_content="${template_content//SERVICE_NAME/$service_name}"

  # Replace IMAGE_NAME placeholder
  template_content="${template_content//IMAGE_NAME/$image_name}"

  # Prepare service YAML content
  local service_yaml
  service_yaml=$(echo "$template_content" | yq eval -o=json | jq -c '.services')

  # Function to update or create the output file
  update_or_create_file() {
    local file=$1
    if [ -f "$file" ]; then
      yq eval -i ".services += $service_yaml" "$file"
    else
      echo "services:" > "$file"
      echo "$service_yaml" | yq eval -o=json | jq -c '.services' | yq eval -i ".services = $service_yaml" "$file"
    fi
  }

  # Update or create the docker-compose files
  update_or_create_file "$output_file"
  update_or_create_file "$sd_file"
}

# Function to create or update Caddyfile
update_caddyfile() {
  local service_name=$1
  local service_port=$2
  local output_dir=$3

  # Replace underscores with hyphens for URLs or paths
  local service_name_hyphenated=${service_name//_/-}

  # Define file paths
  local caddyfile="$output_dir/Caddyfile"
  local caddyfile_sdc="$output_dir/Caddyfile.SDC"

  # Caddyfile format
  local caddy_entry="\${DOMAIN_SCHEME}://${service_name_hyphenated}.\${DOMAIN_NAME} {
  reverse_proxy ${service_name}:${service_port}
}"

  # Caddyfile.SDC format
  local caddy_entry_sdc="handle_path /${service_name_hyphenated}* {
  reverse_proxy ${service_name}:${service_port}
}"

  # Update or create Caddyfile
  if [ -f "$caddyfile" ]; then
    if grep -q "$service_name" "$caddyfile"; then
      echo "Service $service_name is already exposed in Caddyfile."
    else
      echo -e "\n$caddy_entry" >> "$caddyfile"
      echo "Added $service_name to Caddyfile."
    fi
  else
    echo -e "$caddy_entry" > "$caddyfile"
    echo "Caddyfile created and $service_name added."
  fi

  # Update or create Caddyfile.SDC
  if [ -f "$caddyfile_sdc" ]; then
    if grep -q "handle_path /${service_name_hyphenated}*" "$caddyfile_sdc"; then
      echo "Service $service_name is already exposed in Caddyfile.SDC."
    else
      echo -e "\n$caddy_entry_sdc" >> "$caddyfile_sdc"
      echo "Added $service_name to Caddyfile.SDC."
    fi
  else
    echo -e "$caddy_entry_sdc" > "$caddyfile_sdc"
    echo "Caddyfile.SDC created and $service_name added."
  fi
}

# Function to expose a service in Caddyfile
expose_service() {
  local service_name=$1
  local service_port=$2

  # Validate the input format
  if ! [[ "$service_name" =~ ^(common|bhasai)/[^/]+$ ]]; then
    echo "$OUTPUT_INVALID_INPUT"
    return
  fi

  local folder=$(dirname "$service_name")
  service_name=$(basename "$service_name")
  local output_dir="$folder/$service_name"

  local docker_compose_file
  local service_found=false

  if [ -d "$output_dir" ] && [ -f "$output_dir/docker-compose.yaml" ]; then
    local service_exists
    service_exists=$(yq eval ".services | has(\"$service_name\")" "$output_dir/docker-compose.yaml")

    if [ "$service_exists" = "true" ]; then
      echo "Service $service_name found in $output_dir."
      update_caddyfile "$service_name" "$service_port" "$output_dir"
      service_found=true
    fi
  fi

  if [ "$service_found" = false ]; then
    echo "$OUTPUT_SERVICE_NOT_FOUND"
  fi
}

# Function to handle onboarding a service
onboard_service() {
  prompt_input "$PROMPT_IMAGE_NAME" "" IMAGE_NAME

  while true; do
    read -p "$PROMPT_FOLDER_NAME" FOLDER_INPUT

    if [[ "$FOLDER_INPUT" =~ ^(common|bhasai)/[^/]+$ ]]; then
      local folder=$(dirname "$FOLDER_INPUT")
      local SERVICE_NAME=$(basename "$FOLDER_INPUT")
      local output_dir="$folder/$SERVICE_NAME"

      # Check if the service folder already exists
      if [ -d "$output_dir" ]; then
        while true; do
          read -p "Service already exists! Do you want to override it? (yes/no): " override_choice
          case "$override_choice" in
            yes|y|Y)
              update_docker_compose "$SERVICE_NAME" "$IMAGE_NAME" "$output_dir"
              echo "$OUTPUT_SERVICE_ONBOARDED$SERVICE_NAME"
              return
              ;;
            no|n|N)
              echo "$OUTPUT_RETURN_MAIN_MENU"
              return
              ;;
            *)
              echo "$OUTPUT_INVALID_INPUT"
              ;;
          esac
        done
      else
        mkdir -p "$output_dir"
        update_docker_compose "$SERVICE_NAME" "$IMAGE_NAME" "$output_dir"
        echo "$OUTPUT_SERVICE_ONBOARDED$SERVICE_NAME"
        break
      fi
    else
      echo "$OUTPUT_INVALID_INPUT"
    fi
  done
}

# Function to display the main menu
display_main_menu() {
  echo
  echo "Choose an option:"
  for i in "${!MENU_OPTIONS[@]}"; do
    echo "$((i + 1))) ${MENU_OPTIONS[$i]}"
  done
  echo
}

# Main menu
while true; do
  display_main_menu
  read -p "$ENTER_YOUR_CHOICE" choice

  case "$choice" in
    1) onboard_service;;
    2) 
      read -p "$EXPOSE_SERVICE" expose_service_name
      prompt_input "$PROMPT_SERVICE_PORT" validate_number expose_service_port
      expose_service "$expose_service_name" "$expose_service_port"
      ;;
    3) echo "$PROMPT_ABORTING"; exit 0;;
    *) echo "$OUTPUT_INVALID_INPUT";;
  esac
done

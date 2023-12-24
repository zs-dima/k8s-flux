#!/bin/bash

# Set behavior: 'skip' or 'override' secrets
behavior="override"

# Check if .env file exists
if [ ! -f .env ]; then
    echo ".env file not found!"
    exit 1
fi

# Check for gcloud command availability
if ! command -v gcloud &> /dev/null; then
    echo "gcloud is not installed or not in PATH."
    exit 1
fi

# Load variables from .env file
source .env

# Function to check if a Google Cloud secret exists
# Parameters:
#   $1: Secret name
secret_exists() {
  gcloud secrets describe "$1" --project "$GOOGLE_CLOUD_PROJECT" &> /dev/null
  return $?
}

# Function to create a Google Cloud secret and set its IAM policy
# Parameters:
#   $1: Secret name
#   $2: Secret data
#   $3: Behavior ('override' to update existing secrets, anything else to skip)
create_secret() {
  local secret_name="$1"
  local data="$2"
  local behavior="$3"

  if secret_exists "$secret_name"; then
    if [ "$behavior" = "override" ]; then
      echo "Updating existing secret: $secret_name"
      echo -ne "$data" | gcloud secrets versions add "$secret_name" --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
    else
      echo "Skipping existing secret: $secret_name"
      return
    fi
  else
    echo "Creating new secret: $secret_name"
    echo -ne "$data" | gcloud secrets create "$secret_name" --data-file=- --project "$GOOGLE_CLOUD_PROJECT"
  fi

  # Set IAM policy for the secret
  gcloud secrets \
      --project "$GOOGLE_CLOUD_PROJECT" \
      add-iam-policy-binding "$secret_name" \
      --member "serviceAccount:external-secrets@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
      --role "roles/secretmanager.secretAccessor" || return $?
}

# Function to substitute environment variables within a string
# Parameters:
#   $1: String containing environment variables
substitute_env_vars() {
  local str="$1"
  while [[ "$str" =~ (\$\{?[A-Za-z_][A-Za-z0-9_]*\}?) ]]; do
    local var=${BASH_REMATCH[1]}
    local expanded_var=$(eval echo "$var")
    str=${str//"$var"/"$expanded_var"}
  done
  echo "$str"
}

# Function to read and process a configuration file for secrets creation
# Parameters:
#   $1: Configuration file path
process_config() {
  local config_file="$1"
  local current_secret=""
  local json_payload=""

  while IFS= read -r line; do
    if [[ $line =~ ^[[:alnum:]_-]+:$ ]]; then
      # Create secret for the previous section
      if [[ -n "$current_secret" ]]; then
        create_secret "$current_secret" "${json_payload%,}}" $behavior || return $?
      fi
      current_secret=${line%:}
      json_payload="{"
    elif [[ $line =~ ^[[:space:]]+[[:alnum:]_-]+:[[:space:]]+.*$ ]]; then
      # Parse key-value pairs
      local key="${line%%:*}"
      key=${key//[[:space:]]/}
      local value="${line#*: }"
      value=$(substitute_env_vars "$value")
      json_payload+="\"$key\":\"$value\","
    fi
  done < "$config_file"

  # Create the last secret in the file
  if [[ -n "$current_secret" ]]; then
    create_secret "$current_secret" "${json_payload%,}}" $behavior || return $?
  fi
}


# Process the configuration file
process_config "secrets-map.yaml" || exit $?

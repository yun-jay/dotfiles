# Secrets management using Bitwarden CLI with Vaultwarden
#
# Setup:
# 1. Set your Vaultwarden server URL:
#    export BW_SERVER="https://your-vaultwarden.example.com"
# 2. Create a folder in Vaultwarden named "env" (or set BW_ENV_FOLDER)
# 3. Add secure notes to the folder: note name = env var name, note content = env var value
# 4. Run: load_secrets

# Configuration (override these in .zshrc.local or export before sourcing)
: "${BW_ENV_FOLDER:=env}"  # Name of the folder containing environment variable notes

# Unlock Bitwarden vault if needed
_bw_unlock() {
    if [[ -z "$BW_SESSION" ]]; then
        # Check if logged in
        if ! bw login --check &>/dev/null; then
            echo "Logging into Bitwarden..."
            if [[ -n "$BW_SERVER" ]]; then
                bw config server "$BW_SERVER" &>/dev/null
            fi
            export BW_SESSION="$(bw login --raw)"
        else
            echo "Unlocking Bitwarden vault..."
            export BW_SESSION="$(bw unlock --raw)"
        fi

        if [[ -z "$BW_SESSION" ]]; then
            echo "Failed to unlock Bitwarden vault"
            return 1
        fi
    fi
    return 0
}

# Lock Bitwarden vault
lock_secrets() {
    if [[ -n "$BW_SESSION" ]]; then
        bw lock &>/dev/null
        unset BW_SESSION
        echo "Bitwarden vault locked"
    fi
}

# Load environment variables from Vaultwarden folder
load_secrets() {
    local folder_name="${1:-$BW_ENV_FOLDER}"

    _bw_unlock || return 1

    echo "Syncing vault..."
    bw sync &>/dev/null

    # Get folder ID
    local folder_id
    folder_id=$(bw list folders | jq -r --arg name "$folder_name" '.[] | select(.name == $name) | .id')

    if [[ -z "$folder_id" ]]; then
        echo "Error: Could not find folder '$folder_name'"
        return 1
    fi

    echo "Loading secrets from '$folder_name' folder..."

    # Get all items in the folder
    local items
    items=$(bw list items --folderid "$folder_id")

    if [[ -z "$items" || "$items" == "[]" ]]; then
        echo "No items found in folder '$folder_name'"
        return 1
    fi

    # Parse each item: name becomes env var name, notes field becomes value
    local count=0
    while IFS=$'\t' read -r name value; do
        if [[ -n "$name" && -n "$value" ]]; then
            export "$name"="$value"
            ((count++))
        fi
    done < <(echo "$items" | jq -r '.[] | [.name, .notes // .login.password // ""] | @tsv')

    echo "Loaded $count environment variable(s)"
}

# Load a single secret by name
load_secret() {
    local secret_name="$1"

    if [[ -z "$secret_name" ]]; then
        echo "Usage: load_secret <secret_name>"
        return 1
    fi

    _bw_unlock || return 1

    local item
    item=$(bw get item "$secret_name" 2>/dev/null)

    if [[ -z "$item" ]]; then
        echo "Error: Could not find secret '$secret_name'"
        return 1
    fi

    local value
    value=$(echo "$item" | jq -r '.notes // .login.password // ""')

    if [[ -n "$value" ]]; then
        export "$secret_name"="$value"
        echo "Loaded $secret_name"
    else
        echo "Error: No value found for '$secret_name'"
        return 1
    fi
}

# List available secrets (names only, not values)
list_secrets() {
    local folder_name="${1:-$BW_ENV_FOLDER}"

    _bw_unlock || return 1

    # Get folder ID
    local folder_id
    folder_id=$(bw list folders | jq -r --arg name "$folder_name" '.[] | select(.name == $name) | .id')

    if [[ -z "$folder_id" ]]; then
        echo "Error: Could not find folder '$folder_name'"
        return 1
    fi

    echo "Secrets in '$folder_name' folder:"
    bw list items --folderid "$folder_id" | jq -r '.[] | "  - \(.name)"'
}

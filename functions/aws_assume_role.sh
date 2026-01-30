#!/bin/bash
# AWS Assume Role Helper
# Interactive assume role switching with session management
# Author: Enhanced version
# License: MIT

# =============================================================================
# Configuration
# =============================================================================

# Default session duration (in seconds)
readonly DEFAULT_SESSION_DURATION=3600
readonly ASSUME_ROLE_CONFIG="${HOME}/.aws-assume-roles.conf"

# Color codes for output (only if not already defined)
if [[ -z "$COLOR_SUCCESS" ]]; then
    readonly COLOR_SUCCESS="\033[0;32m"
    readonly COLOR_WARNING="\033[0;33m"
    readonly COLOR_ERROR="\033[0;31m"
    readonly COLOR_INFO="\033[0;36m"
    readonly COLOR_RESET="\033[0m"
fi

# =============================================================================
# Utility Functions
# =============================================================================

_log() {
    local level=$1
    shift
    local message="$*"

    case $level in
        success) echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} $message" ;;
        warning) echo -e "${COLOR_WARNING}⚠️${COLOR_RESET} $message" ;;
        error) echo -e "${COLOR_ERROR}❌${COLOR_RESET} $message" >&2 ;;
        info) echo -e "${COLOR_INFO}ℹ️${COLOR_RESET} $message" ;;
        *) echo "$message" ;;
    esac
}

# =============================================================================
# AWS Identity Management
# =============================================================================

# Show current AWS identity (whoami)
aws-whoami() {
    _log info "Current AWS Identity:"
    echo "===================="

    # Get caller identity
    local identity
    identity=$(aws sts get-caller-identity 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        _log error "Not authenticated or credentials expired"
        local sessions
        sessions=$(_list_sso_sessions 2>/dev/null || true)
        if [[ -n "$sessions" ]]; then
            local any_valid=false
            while IFS= read -r session; do
                [[ -z "$session" ]] && continue
                local sso_config
                sso_config=$(_get_sso_session_config "$session")
                if [[ $? -eq 0 ]] && [[ -n "$sso_config" ]]; then
                    IFS='|' read -r sso_start_url sso_region <<EOF
$sso_config
EOF
                    local token
                    token=$(_get_sso_access_token "$sso_start_url")
                    if [[ -n "$token" ]]; then
                        if [[ "$any_valid" == false ]]; then
                            _log info "SSO login detected (select a role/profile to use STS):"
                            any_valid=true
                        fi
                        echo "SSO Session: $session"
                        echo "Start URL:   $sso_start_url"
                        echo "Region:      $sso_region"
                        echo "Hint:        awss  (SSO role switch) or export AWS_PROFILE=<profile>"
                        echo
                    fi
                fi
            done <<EOF
$sessions
EOF
            if [[ "$any_valid" == true ]]; then
                return 1
            fi
        fi
        _log info "Run 'aws-switch-role' to assume a role"
        return 1
    fi

    local account_id=$(echo "$identity" | jq -r '.Account')
    local user_id=$(echo "$identity" | jq -r '.UserId')
    local arn=$(echo "$identity" | jq -r '.Arn')

    echo "Account ID: $account_id"
    echo "User ID:    $user_id"
    echo "ARN:        $arn"

    # Show current profile if set
    if [[ -n "$AWS_PROFILE" ]]; then
        echo "Profile:    $AWS_PROFILE"
    fi

    # Show current region
    local region=$(aws configure get region 2>/dev/null)
    if [[ -n "$region" ]]; then
        echo "Region:     $region"
    fi

    # Check if assumed role
    if [[ "$arn" =~ assumed-role ]]; then
        _log success "Currently using assumed role"
        local role_name=$(echo "$arn" | sed -E 's|.*assumed-role/([^/]+)/.*|\1|')
        echo "Role Name:  $role_name"

        # Show session expiration if available
        if [[ -n "$AWS_SESSION_EXPIRATION" ]]; then
            echo "Expires:    $AWS_SESSION_EXPIRATION"
        fi
    else
        _log info "Using IAM user credentials (not assumed role)"
    fi

    echo
}

# =============================================================================
# Assume Role Configuration Management
# =============================================================================

# Initialize assume role configuration
aws-assume-role-init() {
    if [[ -f "$ASSUME_ROLE_CONFIG" ]]; then
        if ! _confirm "Configuration file already exists. Overwrite?"; then
            _log info "Initialization cancelled."
            return 0
        fi
    fi

    cat > "$ASSUME_ROLE_CONFIG" << 'EOF'
# AWS Assume Role Configuration
# Format: ALIAS:ROLE_ARN:SOURCE_PROFILE:SESSION_NAME:DURATION
#
# ALIAS         - Friendly name for the role (e.g., staging, production)
# ROLE_ARN      - Full ARN of the role to assume
# SOURCE_PROFILE - AWS profile to use for assuming the role (optional, uses default if empty)
# SESSION_NAME  - Session name (optional, uses username if empty)
# DURATION      - Session duration in seconds (optional, uses 3600 if empty)
#
# Examples:
# staging:arn:aws:iam::123456789012:role/StagingAdmin:default:staging-session:3600
# production:arn:aws:iam::987654321098:role/ProductionReadOnly:default:prod-session:7200
# dev:arn:aws:iam::111111111111:role/DeveloperRole:::

# Add your role configurations below:
staging:arn:aws:iam::ACCOUNT_ID:role/StagingRole:default::3600
production:arn:aws:iam::ACCOUNT_ID:role/ProductionRole:default::3600
EOF

    chmod 600 "$ASSUME_ROLE_CONFIG"
    _log success "Configuration file created: $ASSUME_ROLE_CONFIG"
    _log info "Please edit the configuration file to add your role ARNs"

    if _confirm "Open configuration file for editing now?"; then
        ${EDITOR:-nano} "$ASSUME_ROLE_CONFIG"
    fi
}

# Load role configurations
_load_role_configs() {
    if [[ ! -f "$ASSUME_ROLE_CONFIG" ]]; then
        _log warning "Configuration file not found: $ASSUME_ROLE_CONFIG"
        _log info "Run 'aws-assume-role-init' to create it"
        return 1
    fi

    # Parse configuration file
    local roles=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        roles+=("$line")
    done < "$ASSUME_ROLE_CONFIG"

    if [[ ${#roles[@]} -eq 0 ]]; then
        _log error "No roles configured in $ASSUME_ROLE_CONFIG"
        return 1
    fi

    echo "${roles[@]}"
}

# =============================================================================
# SSO Quick Switch (No Config Required)
# =============================================================================

# Parse sso-session from AWS config
_get_sso_session_config() {
    local sso_session_name="${1:-sso}"
    local config_file="${HOME}/.aws/config"

    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    # Extract sso-session configuration
    local in_session=false
    local sso_start_url=""
    local sso_region=""

    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | xargs)

        # Check if we're entering the target sso-session block
        if [[ "$line" == "[sso-session $sso_session_name]" ]]; then
            in_session=true
            continue
        fi

        # Check if we're entering a different section
        if [[ "$line" == "["* ]] && [[ "$in_session" == true ]]; then
            break
        fi

        # Parse values within the sso-session block
        if [[ "$in_session" == true ]]; then
            if [[ "$line" == sso_start_url* ]]; then
                sso_start_url=$(echo "$line" | cut -d= -f2- | xargs)
            elif [[ "$line" == sso_region* ]]; then
                sso_region=$(echo "$line" | cut -d= -f2- | xargs)
            fi
        fi
    done < "$config_file"

    if [[ -n "$sso_start_url" ]] && [[ -n "$sso_region" ]]; then
        echo "$sso_start_url|$sso_region"
        return 0
    fi

    return 1
}

# List available sso-sessions from config
_list_sso_sessions() {
    local config_file="${HOME}/.aws/config"

    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    grep -E '^\[sso-session ' "$config_file" | sed 's/\[sso-session \(.*\)\]/\1/'
}

# Get SSO access token from cache
_get_sso_access_token() {
    local sso_start_url="$1"
    local sso_cache_dir="${HOME}/.aws/sso/cache"

    if [[ ! -d "$sso_cache_dir" ]]; then
        return 1
    fi

    # Find the most recent cache file for this SSO start URL
    local cache_file=""
    local latest_time=0

    for file in "$sso_cache_dir"/*.json; do
        [[ ! -f "$file" ]] && continue

        local url=$(jq -r '.startUrl // empty' "$file" 2>/dev/null)
        if [[ "$url" == "$sso_start_url" ]]; then
            local mod_time=$(stat -f %m "$file" 2>/dev/null || echo 0)
            if [[ $mod_time -gt $latest_time ]]; then
                latest_time=$mod_time
                cache_file="$file"
            fi
        fi
    done

    if [[ -z "$cache_file" ]]; then
        return 1
    fi

    # Extract access token and check expiration
    local access_token=$(jq -r '.accessToken // empty' "$cache_file" 2>/dev/null)
    local expires_at=$(jq -r '.expiresAt // empty' "$cache_file" 2>/dev/null)

    if [[ -z "$access_token" ]]; then
        return 1
    fi

    # Check if token is expired
    if [[ -n "$expires_at" ]]; then
        local expires_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SUTC" "$expires_at" "+%s" 2>/dev/null)
        local current_epoch=$(date -u +%s)

        if [[ -n "$expires_epoch" ]] && [[ $current_epoch -ge $expires_epoch ]]; then
            return 1  # Token expired
        fi
    fi

    echo "$access_token"
    return 0
}

# SSO login and switch profile in one command
aws-sso-switch() {
    local sso_session_name="${1}"

    _log info "AWS SSO Profile Switch"
    echo "======================="

    # If no session name provided, try to find available sessions
    if [[ -z "$sso_session_name" ]]; then
        local sessions
        sessions=$(_list_sso_sessions)

        if [[ -z "$sessions" ]]; then
            _log error "No sso-session found in ~/.aws/config"
            _log info "Please configure sso-session in ~/.aws/config"
            return 1
        fi

        # If only one session, use it
        local session_count=$(echo "$sessions" | wc -l | xargs)
        if [[ "$session_count" -eq 1 ]]; then
            sso_session_name="$sessions"
            _log info "Using sso-session: $sso_session_name"
        else
            # Multiple sessions, let user choose
            if command -v peco >/dev/null 2>&1; then
                sso_session_name=$(echo "$sessions" | peco --prompt "Select SSO Session:")
                if [[ -z "$sso_session_name" ]]; then
                    _log warning "No session selected"
                    return 1
                fi
            else
                _log info "Available sso-sessions:"
                echo "$sessions"
                _log info "Usage: aws-sso-switch <sso-session-name>"
                return 1
            fi
        fi
    fi

    # Get SSO configuration
    local sso_config
    sso_config=$(_get_sso_session_config "$sso_session_name")
    if [[ $? -ne 0 ]] || [[ -z "$sso_config" ]]; then
        _log error "sso-session '$sso_session_name' not found in ~/.aws/config"
        return 1
    fi

    IFS='|' read -r sso_start_url sso_region <<EOF
$sso_config
EOF

    # Check if we have a valid access token
    local access_token
    access_token=$(_get_sso_access_token "$sso_start_url")

    if [[ -z "$access_token" ]]; then
        # Need to login
        _log info "SSO login required. Opening browser..."
        aws sso login --sso-session "$sso_session_name"

        if [[ $? -ne 0 ]]; then
            _log error "SSO login failed"
            return 1
        fi

        # Try to get token again
        access_token=$(_get_sso_access_token "$sso_start_url")
        if [[ -z "$access_token" ]]; then
            _log error "Failed to get access token after login"
            return 1
        fi
    else
        _log success "Already logged in to SSO"
    fi

    # List available accounts and roles dynamically
    _log info "Fetching available accounts and roles..."

    # List accounts using the access token
    local accounts
    accounts=$(aws sso list-accounts --access-token "$access_token" 2>&1)

    if [[ $? -ne 0 ]]; then
        _log error "Failed to list SSO accounts"
        _log info "Error: $accounts"
        _log warning "Falling back to profiles in ~/.aws/config"

        # Fallback: use profiles from config
        local profile_list=""
        local config_file="${HOME}/.aws/config"

        while IFS= read -r line; do
            if [[ "$line" =~ ^\[profile\ (.+)\] ]]; then
                profile_list+="${BASH_REMATCH[1]}"$'\n'
            fi
        done < "$config_file"

        if [[ -z "$profile_list" ]]; then
            _log error "No profiles found"
            return 1
        fi

        local selected
        if command -v peco >/dev/null 2>&1; then
            selected=$(echo "$profile_list" | peco --prompt "Select Profile:")
        else
            echo "$profile_list"
            return 1
        fi

        if [[ -z "$selected" ]]; then
            _log warning "No profile selected"
            return 1
        fi

        export AWS_PROFILE="$selected"
        _log success "Profile switched to: $selected"
        echo
        aws-whoami
        return 0
    fi

    # Build role list with account info
    local role_list=""

    (
        echo "$accounts" | jq -c '.accountList[]' 2>/dev/null | while IFS= read -r account_json; do
            account_id=$(echo "$account_json" | jq -r '.accountId')
            account_name=$(echo "$account_json" | jq -r '.accountName')

            # Get roles for this account
            roles=$(aws sso list-account-roles --account-id "$account_id" --access-token "$access_token" 2>/dev/null)

            if [[ -n "$roles" ]]; then
                echo "$roles" | jq -c '.roleList[]' 2>/dev/null | while IFS= read -r role_json; do
                    role_name=$(echo "$role_json" | jq -r '.roleName')
                    # Format: "AccountName | RoleName | AccountID"
                    echo "$account_name | $role_name | $account_id"
                done
            fi
        done
    ) > /tmp/aws-sso-roles-$$.txt 2>/dev/null

    role_list=$(cat /tmp/aws-sso-roles-$$.txt)
    rm -f /tmp/aws-sso-roles-$$.txt

    if [[ -z "$role_list" ]]; then
        _log error "No roles found"
        return 1
    fi

    # Interactive selection
    _log success "Found available roles. Select one:"

    local selected
    if command -v peco >/dev/null 2>&1; then
        selected=$(echo "$role_list" | peco --prompt "Select Role:")
    else
        echo "$role_list"
        _log error "peco is required for interactive selection"
        _log info "Install with: brew install peco"
        return 1
    fi

    if [[ -z "$selected" ]]; then
        _log warning "No role selected"
        return 1
    fi

    # Parse selection
    IFS='|' read -r account_name role_name account_id <<EOF
$selected
EOF
    account_name=$(echo "$account_name" | xargs)
    role_name=$(echo "$role_name" | xargs)
    account_id=$(echo "$account_id" | xargs)

    _log info "Selected: $account_name / $role_name"

    # Create or update profile for this selection
    local profile_name="sso-${account_name}-${role_name}"
    profile_name=$(echo "$profile_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    _log info "Using profile: $profile_name"

    # Configure profile temporarily
    aws configure set sso_session "$sso_session_name" --profile "$profile_name"
    aws configure set sso_account_id "$account_id" --profile "$profile_name"
    aws configure set sso_role_name "$role_name" --profile "$profile_name"
    aws configure set region "ap-northeast-1" --profile "$profile_name"

    # Set AWS_PROFILE
    export AWS_PROFILE="$profile_name"

    # Clear any previously assumed role credentials
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_SESSION_EXPIRATION
    unset AWS_ASSUMED_ROLE_ALIAS

    _log success "Switched to: $account_name / $role_name"

    # Show current identity
    echo
    aws-whoami
}

# Quick SSO login (without role switching)
aws-sso-quick-login() {
    local sso_session_name="${1}"

    _log info "AWS SSO Login"

    # If no session name provided, try to find available sessions
    if [[ -z "$sso_session_name" ]]; then
        local sessions
        sessions=$(_list_sso_sessions)

        if [[ -z "$sessions" ]]; then
            _log error "No sso-session found in ~/.aws/config"
            _log info "Please configure sso-session in ~/.aws/config"
            return 1
        fi

        # If only one session, use it
        local session_count=$(echo "$sessions" | wc -l | xargs)
        if [[ "$session_count" -eq 1 ]]; then
            sso_session_name="$sessions"
            _log info "Using sso-session: $sso_session_name"
        else
            # Multiple sessions, let user choose
            if command -v peco >/dev/null 2>&1; then
                sso_session_name=$(echo "$sessions" | peco --prompt "Select SSO Session:")
                if [[ -z "$sso_session_name" ]]; then
                    _log warning "No session selected"
                    return 1
                fi
            else
                _log info "Available sso-sessions:"
                echo "$sessions"
                _log info "Usage: aws-sso-quick-login <sso-session-name>"
                return 1
            fi
        fi
    fi

    _log info "Logging in with sso-session: $sso_session_name"
    aws sso login --sso-session "$sso_session_name"

    if [[ $? -eq 0 ]]; then
        _log success "SSO login successful"
        if [[ "${AWS_SSO_QUICK_LOGIN_SWITCH:-0}" == "1" ]]; then
            echo
            aws-sso-switch "$sso_session_name"
            return $?
        fi

        if [[ -n "$AWS_PROFILE" ]]; then
            echo
            aws-whoami
            return 0
        fi

        if _confirm "Switch role/profile now?"; then
            echo
            aws-sso-switch "$sso_session_name"
        else
            _log info "SSO login complete. Use 'awss' to select a role or export AWS_PROFILE=<profile>"
        fi
    else
        _log error "SSO login failed"
        return 1
    fi
}

# =============================================================================
# Role Discovery Functions
# =============================================================================

# Discover assumable roles automatically
aws-discover-roles() {
    local profile="${1:-default}"

    _log info "Discovering assumable roles..."

    # Get current user identity
    local current_user_arn
    current_user_arn=$(aws sts get-caller-identity --profile "$profile" --query 'Arn' --output text 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        _log error "Failed to get current user identity"
        _log info "Make sure you're authenticated with: aws sso login --profile $profile"
        return 1
    fi

    _log info "Current user: $current_user_arn"

    # List all roles
    _log info "Fetching all IAM roles..."
    local all_roles
    all_roles=$(aws iam list-roles --profile "$profile" --output json 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        _log error "Failed to list roles. You may not have iam:ListRoles permission."
        return 1
    fi

    # Filter assumable roles
    local assumable_roles=()

    echo "$all_roles" | jq -r '.Roles[] | @json' | while IFS= read -r role; do
        local role_name=$(echo "$role" | jq -r '.RoleName')
        local role_arn=$(echo "$role" | jq -r '.Arn')
        local assume_policy=$(echo "$role" | jq -r '.AssumeRolePolicyDocument')

        # Check if current user/account can assume this role
        # This is a simplified check - you might need to adjust based on your policies
        local principal_arns=$(echo "$assume_policy" | jq -r '.Statement[].Principal.AWS // empty' 2>/dev/null)

        if [[ -n "$principal_arns" ]]; then
            # Check if our user or account is in the principals
            if echo "$principal_arns" | grep -q "$current_user_arn" || \
               echo "$principal_arns" | grep -q "$(echo "$current_user_arn" | cut -d: -f5)"; then
                echo "$role_name | $role_arn"
            fi
        fi
    done
}

# Discover roles via AWS SSO
aws-discover-sso-roles() {
    _log info "Discovering AWS SSO roles..."

    # List SSO accounts
    local accounts
    accounts=$(aws sso list-accounts 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        _log error "Failed to list SSO accounts"
        _log info "Make sure you're logged in with: aws sso login"
        return 1
    fi

    echo "$accounts" | jq -r '.accountList[] | @json' | while IFS= read -r account; do
        local account_id=$(echo "$account" | jq -r '.accountId')
        local account_name=$(echo "$account" | jq -r '.accountName')

        _log info "Account: $account_name ($account_id)"

        # List roles for this account
        local roles
        roles=$(aws sso list-account-roles --account-id "$account_id" 2>/dev/null)

        if [[ $? -eq 0 ]]; then
            echo "$roles" | jq -r '.roleList[] | @json' | while IFS= read -r role; do
                local role_name=$(echo "$role" | jq -r '.roleName')
                echo "  $account_name-$role_name | arn:aws:iam::$account_id:role/$role_name"
            done
        fi
    done
}

# Auto-generate config from discovered roles
aws-auto-config-roles() {
    local method="${1:-iam}"  # iam or sso

    _log info "Auto-generating role configuration..."

    local discovered_roles
    if [[ "$method" == "sso" ]]; then
        discovered_roles=$(aws-discover-sso-roles)
    else
        discovered_roles=$(aws-discover-roles)
    fi

    if [[ -z "$discovered_roles" ]]; then
        _log warning "No assumable roles found"
        return 1
    fi

    _log success "Found assumable roles:"
    echo "$discovered_roles"

    if _confirm "Add these roles to configuration file?"; then
        local config_file="$ASSUME_ROLE_CONFIG"

        # Backup existing config
        if [[ -f "$config_file" ]]; then
            cp "$config_file" "${config_file}.backup"
            _log info "Backed up existing config to ${config_file}.backup"
        fi

        # Append discovered roles
        echo "" >> "$config_file"
        echo "# Auto-discovered roles on $(date)" >> "$config_file"

        echo "$discovered_roles" | while IFS='|' read -r alias role_arn; do
            alias=$(echo "$alias" | xargs)  # trim whitespace
            role_arn=$(echo "$role_arn" | xargs)

            # Create a safe alias name
            safe_alias=$(echo "$alias" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

            echo "${safe_alias}:${role_arn}:default::3600" >> "$config_file"
        done

        _log success "Configuration updated: $config_file"
    fi
}

# =============================================================================
# Assume Role Functions
# =============================================================================

# Assume a role and export credentials
aws-switch-role() {
    local role_alias="$1"

    # Load role configurations
    local configs
    configs=$(_load_role_configs)
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Interactive selection if no alias provided
    if [[ -z "$role_alias" ]]; then
        if ! command -v peco >/dev/null 2>&1; then
            _log error "peco is required for interactive selection"
            _log info "Install with: brew install peco"
            _log info "Or provide role alias: aws-switch-role <alias>"
            return 1
        fi

        local role_list
        role_list=$(echo "$configs" | tr ' ' '\n' | awk -F':' '{print $1 " - " $2}')

        local selected
        selected=$(echo "$role_list" | peco --prompt "Select role:")

        if [[ -z "$selected" ]]; then
            _log warning "No role selected"
            return 1
        fi

        role_alias=$(echo "$selected" | awk '{print $1}')
    fi

    # Find role configuration
    local role_config=""
    for config in $configs; do
        local alias=$(echo "$config" | cut -d':' -f1)
        if [[ "$alias" == "$role_alias" ]]; then
            role_config="$config"
            break
        fi
    done

    if [[ -z "$role_config" ]]; then
        _log error "Role alias '$role_alias' not found in configuration"
        _log info "Available roles:"
        echo "$configs" | tr ' ' '\n' | awk -F':' '{print "  - " $1}'
        return 1
    fi

    # Parse role configuration
    IFS=':' read -r alias role_arn source_profile session_name duration <<EOF
$role_config
EOF

    # Set defaults
    source_profile="${source_profile:-default}"
    session_name="${session_name:-$(whoami)-$(date +%s)}"
    duration="${duration:-$DEFAULT_SESSION_DURATION}"

    _log info "Assuming role: $alias"
    _log info "Role ARN: $role_arn"
    _log info "Source Profile: $source_profile"

    # Assume role
    local credentials
    credentials=$(aws sts assume-role \
        --role-arn "$role_arn" \
        --role-session-name "$session_name" \
        --duration-seconds "$duration" \
        --profile "$source_profile" \
        --output json 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        _log error "Failed to assume role"
        _log info "Check that:"
        _log info "  1. The role ARN is correct"
        _log info "  2. The source profile has permission to assume the role"
        _log info "  3. You are authenticated (try 'aws sso login --profile $source_profile')"
        return 1
    fi

    # Extract credentials
    local access_key=$(echo "$credentials" | jq -r '.Credentials.AccessKeyId')
    local secret_key=$(echo "$credentials" | jq -r '.Credentials.SecretAccessKey')
    local session_token=$(echo "$credentials" | jq -r '.Credentials.SessionToken')
    local expiration=$(echo "$credentials" | jq -r '.Credentials.Expiration')

    # Export credentials to environment
    export AWS_ACCESS_KEY_ID="$access_key"
    export AWS_SECRET_ACCESS_KEY="$secret_key"
    export AWS_SESSION_TOKEN="$session_token"
    export AWS_SESSION_EXPIRATION="$expiration"
    export AWS_ASSUMED_ROLE_ALIAS="$alias"

    # Unset profile to use temporary credentials
    unset AWS_PROFILE

    _log success "Successfully assumed role: $alias"
    _log info "Session expires: $expiration"

    # Show current identity
    echo
    aws-whoami

    # Show export commands for manual use
    echo
    _log info "To use in another terminal, export these variables:"
    echo "export AWS_ACCESS_KEY_ID='$access_key'"
    echo "export AWS_SECRET_ACCESS_KEY='$secret_key'"
    echo "export AWS_SESSION_TOKEN='$session_token'"
}

# Clear assumed role credentials
aws-clear-role() {
    if [[ -z "$AWS_ACCESS_KEY_ID" ]] && [[ -z "$AWS_SESSION_TOKEN" ]]; then
        _log warning "No assumed role credentials found"
        return 0
    fi

    if [[ -n "$AWS_ASSUMED_ROLE_ALIAS" ]]; then
        _log info "Clearing assumed role: $AWS_ASSUMED_ROLE_ALIAS"
    else
        _log info "Clearing assumed role credentials"
    fi

    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_SESSION_EXPIRATION
    unset AWS_ASSUMED_ROLE_ALIAS

    _log success "Assumed role credentials cleared"
    _log info "Using default AWS configuration"
}

# List available roles
aws-list-roles() {
    _log info "Available Roles:"
    echo "================"

    local configs
    configs=$(_load_role_configs)
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    echo "$configs" | tr ' ' '\n' | while IFS=':' read -r alias role_arn source_profile session_name duration; do
        echo
        echo "Alias:     $alias"
        echo "Role ARN:  $role_arn"
        echo "Profile:   ${source_profile:-default}"
        echo "Duration:  ${duration:-3600}s"
    done

    echo

    # Show current role if any
    if [[ -n "$AWS_ASSUMED_ROLE_ALIAS" ]]; then
        _log success "Currently using role: $AWS_ASSUMED_ROLE_ALIAS"
    else
        _log info "No role currently assumed"
    fi
}

# Check if assumed role session is still valid
aws-check-session() {
    if [[ -z "$AWS_SESSION_TOKEN" ]]; then
        _log warning "No assumed role session active"
        return 1
    fi

    # Try to get caller identity
    if aws sts get-caller-identity &>/dev/null; then
        _log success "Session is valid"
        if [[ -n "$AWS_SESSION_EXPIRATION" ]]; then
            _log info "Expires: $AWS_SESSION_EXPIRATION"

            # Calculate time remaining
            local expiration_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${AWS_SESSION_EXPIRATION%Z}" "+%s" 2>/dev/null)
            local current_epoch=$(date +%s)

            if [[ -n "$expiration_epoch" ]]; then
                local remaining=$((expiration_epoch - current_epoch))
                if [[ $remaining -gt 0 ]]; then
                    local minutes=$((remaining / 60))
                    _log info "Time remaining: ${minutes} minutes"
                else
                    _log warning "Session has expired"
                    return 1
                fi
            fi
        fi
        return 0
    else
        _log error "Session is invalid or expired"
        _log info "Run 'aws-switch-role' to assume a role again"
        return 1
    fi
}

# =============================================================================
# Interactive Menu
# =============================================================================

_confirm() {
    local message="$1"
    read -r -p "$message (y/N): " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

aws-role-menu() {
    local menu_options=(
        "⚡ SSO Quick Switch (Recommended)"
        "🔐 SSO Login Only"
        "🔄 Switch Role (Config-based)"
        "👤 Show Current Identity (whoami)"
        "📋 List Available Roles"
        "🔍 Discover Assumable Roles (IAM)"
        "🔍 Discover Assumable Roles (SSO)"
        "⚙️  Auto-Generate Config from IAM"
        "⚙️  Auto-Generate Config from SSO"
        "✅ Check Session Status"
        "🧹 Clear Role Credentials"
        "📝 Initialize Configuration"
        "❓ Help"
        "🚪 Exit"
    )

    while true; do
        echo
        _log info "AWS Assume Role Helper"
        echo "======================"

        local selected
        if command -v peco >/dev/null 2>&1; then
            selected=$(printf '%s\n' "${menu_options[@]}" | peco --prompt "Select action:")
        else
            echo "Select an option:"
            select selected in "${menu_options[@]}"; do
                break
            done
        fi

        case "$selected" in
            "⚡ SSO Quick Switch (Recommended)")
                aws-sso-switch
                ;;
            "🔐 SSO Login Only")
                aws-sso-quick-login
                ;;
            "🔄 Switch Role (Config-based)")
                aws-switch-role
                ;;
            "👤 Show Current Identity (whoami)")
                aws-whoami
                ;;
            "📋 List Available Roles")
                aws-list-roles
                ;;
            "🔍 Discover Assumable Roles (IAM)")
                aws-discover-roles
                ;;
            "🔍 Discover Assumable Roles (SSO)")
                aws-discover-sso-roles
                ;;
            "⚙️  Auto-Generate Config from IAM")
                aws-auto-config-roles iam
                ;;
            "⚙️  Auto-Generate Config from SSO")
                aws-auto-config-roles sso
                ;;
            "✅ Check Session Status")
                aws-check-session
                ;;
            "🧹 Clear Role Credentials")
                aws-clear-role
                ;;
            "📝 Initialize Configuration")
                aws-assume-role-init
                ;;
            "❓ Help")
                _show_help
                ;;
            "🚪 Exit"|"")
                _log info "Goodbye!"
                break
                ;;
            *)
                _log warning "Invalid selection"
                ;;
        esac

        if [[ -n "$selected" ]] && [[ "$selected" != "🚪 Exit" ]]; then
            echo
            read -r -p "Press Enter to continue..."
        fi
    done
}

_show_help() {
    cat << 'EOF'

AWS Assume Role Helper - Help
==============================

🌟 RECOMMENDED: SSO Quick Switch
  aws-sso-switch (awss)    - Login + List Roles + Assume in one command!
                            No configuration file needed!

Available Commands:
  aws-sso-switch           - SSO login → list roles → select → assume
  aws-sso-quick-login      - SSO login only (no role switching)
  aws-switch-role [alias]  - Assume a role (config-based)
  aws-clear-role           - Clear assumed role credentials
  aws-whoami               - Show current AWS identity
  aws-list-roles           - List available roles from config
  aws-check-session        - Check if current session is valid
  aws-discover-roles       - Discover assumable roles via IAM
  aws-discover-sso-roles   - Discover assumable roles via SSO
  aws-auto-config-roles    - Auto-generate config from discovered roles
  aws-role-menu            - Launch interactive menu
  aws-assume-role-init     - Initialize configuration file

Aliases:
  awss    - aws-sso-switch (★ Most useful!)
  awssl   - aws-sso-quick-login
  awsr    - aws-switch-role
  awsc    - aws-clear-role
  awsw    - aws-whoami
  awsl    - aws-list-roles
  awsm    - aws-role-menu

Quick Start (SSO):
  # Step 1: SSO login and switch role (all in one!)
  awss

  # Step 2: Check current identity
  awsw

  # Step 3: Use AWS CLI
  aws s3 ls

  # Step 4: Clear when done
  awsc

Usage Examples (SSO):
  # Interactive SSO role selection
  aws-sso-switch

  # Check current identity
  aws-whoami

  # Clear credentials
  aws-clear-role

Usage Examples (Config-based):
  # Discover assumable roles
  aws-discover-roles

  # Auto-generate config from discovered roles
  aws-auto-config-roles

  # Interactive role selection
  aws-switch-role

  # Switch to specific role
  aws-switch-role staging

Configuration (Optional):
  Edit ~/.aws-assume-roles.conf for config-based switching

  Format: ALIAS:ROLE_ARN:SOURCE_PROFILE:SESSION_NAME:DURATION

  Example:
  staging:arn:aws:iam::123456789012:role/StagingAdmin:default:session:3600

Notes:
  - SSO Quick Switch (awss) is the easiest way!
  - Assumed role credentials are exported to your current shell
  - Session duration is typically 1 hour (configurable)
  - Use aws-check-session to verify credentials before operations
  - Credentials must be cleared or will expire automatically
  - aws-discover-roles requires iam:ListRoles permission

EOF
}

# =============================================================================
# Prompt Integration (Optional)
# =============================================================================

# Function to show current AWS role in prompt
aws-prompt-role() {
    if [[ -n "$AWS_ASSUMED_ROLE_ALIAS" ]]; then
        echo " [aws:$AWS_ASSUMED_ROLE_ALIAS]"
    elif [[ -n "$AWS_PROFILE" ]]; then
        echo " [aws:$AWS_PROFILE]"
    fi
}

# =============================================================================
# Aliases
# =============================================================================

alias awsr='aws-switch-role'
alias awsc='aws-clear-role'
alias awsw='aws-whoami'
alias awsl='aws-list-roles'
alias awsm='aws-role-menu'
alias awsd='aws-discover-roles'
alias awsds='aws-discover-sso-roles'
alias awsac='aws-auto-config-roles'
alias awss='aws-sso-switch'  # SSO Quick Switch - これが一番使うやつ！
alias awssl='aws-sso-quick-login'

# =============================================================================
# Initialization Message
# =============================================================================

# Show helpful message when sourced (only if explicitly requested)
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ "${AWS_ASSUME_ROLE_VERBOSE:-0}" == "1" ]]; then
    _log success "AWS Assume Role Helper loaded"
    _log info "Available commands: aws-switch-role, aws-whoami, aws-clear-role, aws-role-menu"
    _log info "Run 'aws-assume-role-init' to create configuration file"

    # Show current identity if credentials exist
    if aws sts get-caller-identity &>/dev/null; then
        echo
        aws-whoami
    fi
fi

# Auto-run menu if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    aws-role-menu
fi

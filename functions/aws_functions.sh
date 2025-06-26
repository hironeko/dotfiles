#!/bin/bash
# AWS Helper Tools - Enhanced and Generalized
# Interactive AWS resource management with peco integration
# Author: Enhanced version
# License: MIT

# =============================================================================
# Configuration and Constants
# =============================================================================

# Default configuration file path
readonly DEFAULT_CONFIG_FILE="${HOME}/dotfiles/functions/aws_config.sh"
readonly SCRIPT_NAME="AWS Helper Tools"
readonly VERSION="1.0.0"

# =============================================================================
# Utility Functions
# =============================================================================

# Logging function
_aws_log() {
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

# Check dependencies
_check_dependencies() {
    local missing_deps=()
    
    if ! command -v aws >/dev/null 2>&1; then
        missing_deps+=("aws-cli")
    fi
    
    if ! command -v peco >/dev/null 2>&1; then
        missing_deps+=("peco")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        _aws_log error "Missing required dependencies: ${missing_deps[*]}"
        _aws_log info "Installation commands:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                aws-cli)
                    echo "  - AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
                    ;;
                peco)
                    echo "  - Peco: brew install peco (macOS) or https://github.com/peco/peco"
                    ;;
                jq)
                    echo "  - jq: brew install jq (macOS) or sudo apt install jq (Linux)"
                    ;;
            esac
        done
        return 1
    fi
    
    return 0
}

# Validate AWS CLI configuration
_validate_aws_config() {
    if [[ ! -f ~/.aws/config ]] && [[ ! -f ~/.aws/credentials ]]; then
        _aws_log error "AWS CLI not configured. Run 'aws configure' first."
        return 1
    fi
    return 0
}

# =============================================================================
# Configuration Management
# =============================================================================

# Load configuration with fallback to defaults
load_config() {
    local config_file="${1:-$DEFAULT_CONFIG_FILE}"
    
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        _aws_log success "Configuration loaded from: $config_file"
    else
        _aws_log warning "Configuration file not found: $config_file"
        _aws_log info "Using default values. Run 'aws-helper-init' to create a config file."
        _set_default_config
    fi
}

# Set default configuration values
_set_default_config() {
    AWS_REGION="${AWS_REGION:-ap-northeast-1}"
    EC2_FILTERS="${EC2_FILTERS:-("すべて表示" "web-server" "bastion" "database")}"
    ECS_CLUSTER_NAME="${ECS_CLUSTER_NAME:-my-cluster}"
    ECS_SERVICE_NAME="${ECS_SERVICE_NAME:-my-service}"
    ECS_CONTAINER_NAME="${ECS_CONTAINER_NAME:-app}"
    ECS_COMMAND="${ECS_COMMAND:-/bin/bash}"
    RDS_ENVIRONMENTS="${RDS_ENVIRONMENTS:-("DEV:localhost:3306:13306" "STG:stage-db:3306:13307" "PRD:prod-db:3306:13308")}"
    BASTION_TAG_NAME="${BASTION_TAG_NAME:-bastion}"
}

# Initialize configuration file
aws-helper-init() {
    local config_file="${1:-$DEFAULT_CONFIG_FILE}"
    
    if [[ -f "$config_file" ]]; then
        if ! _confirm "Configuration file already exists. Overwrite?"; then
            _aws_log info "Initialization cancelled."
            return 0
        fi
    fi
    
    cat > "$config_file" << 'EOF'
#!/bin/bash
# AWS Helper Tools Configuration
# Customize these values according to your environment

# =============================================================================
# AWS General Settings
# =============================================================================

# Default AWS region
AWS_REGION="ap-northeast-1"

# =============================================================================
# EC2 Settings
# =============================================================================

# EC2 instance filters for quick selection
# Add your commonly used instance name patterns here
EC2_FILTERS=(
    "すべて表示"
    "web-server"
    "api-server"
    "bastion"
    "database"
    "worker"
    # Add more filters as needed
)

# =============================================================================
# ECS Settings
# =============================================================================

# ECS cluster configuration
ECS_CLUSTER_NAME="my-cluster"
ECS_SERVICE_NAME="my-service"
ECS_CONTAINER_NAME="app"
ECS_COMMAND="/bin/bash"  # or "/bin/sh" for alpine-based containers

# =============================================================================
# RDS Settings
# =============================================================================

# RDS environment configurations
# Format: "ENV_NAME:HOSTNAME:REMOTE_PORT:LOCAL_PORT"
RDS_ENVIRONMENTS=(
    "DEV:dev-db.region.rds.amazonaws.com:3306:13306"
    "STG:stg-db.region.rds.amazonaws.com:3306:13307"
    "PRD:prod-db.region.rds.amazonaws.com:3306:13308"
    # Add more environments as needed
)

# =============================================================================
# Bastion Server Settings
# =============================================================================

# Tag name used to identify bastion servers
BASTION_TAG_NAME="bastion"

# =============================================================================
# Custom Settings (Optional)
# =============================================================================

# Default SSH user for EC2 instances
DEFAULT_SSH_USER="ec2-user"

# Session Manager preferences
SSM_DOCUMENT_NAME="AWS-StartInteractiveCommand"
SSM_PARAMETERS='{"command":["bash"]}'

# Logging preferences
ENABLE_VERBOSE_LOGGING=false
EOF

    chmod +x "$config_file"
    _aws_log success "Configuration file created: $config_file"
    _aws_log info "Please edit the configuration file to match your environment."
    
    if _confirm "Open configuration file for editing now?"; then
        ${EDITOR:-nano} "$config_file"
    fi
}

# =============================================================================
# Clipboard Management
# =============================================================================

# Cross-platform clipboard copy
copy_to_clipboard() {
    local content="$1"
    
    if command -v pbcopy >/dev/null 2>&1; then
        echo "$content" | pbcopy
        _aws_log success "Command copied to clipboard (macOS)"
    elif command -v xclip >/dev/null 2>&1; then
        echo "$content" | xclip -selection clipboard
        _aws_log success "Command copied to clipboard (Linux - xclip)"
    elif command -v xsel >/dev/null 2>&1; then
        echo "$content" | xsel --clipboard --input
        _aws_log success "Command copied to clipboard (Linux - xsel)"
    elif command -v wl-copy >/dev/null 2>&1; then
        echo "$content" | wl-copy
        _aws_log success "Command copied to clipboard (Wayland)"
    else
        _aws_log warning "No clipboard utility found. Copy manually:"
        echo "$content"
    fi
}

# =============================================================================
# AWS Profile Management
# =============================================================================

# Interactive AWS profile selection
select_aws_profile() {
    local prompt_text="${1:-Select AWS profile:}"
    local profiles=""
    
    # Method 1: Get profiles from config file
    if [[ -f ~/.aws/config ]]; then
        profiles=$(grep -E "^\[profile " ~/.aws/config | sed -E 's/^\[profile (.*)\]$/\1/')
    fi
    
    # Method 2: Try AWS CLI command
    if [[ -z "$profiles" ]] && command -v aws >/dev/null 2>&1; then
        profiles=$(aws configure list-profiles 2>/dev/null)
    fi
    
    # Method 3: Check credentials file
    if [[ -z "$profiles" ]] && [[ -f ~/.aws/credentials ]]; then
        profiles=$(grep -E "^\[" ~/.aws/credentials | sed -E 's/^\[(.*)\]$/\1/' | grep -v "^default$")
        if [[ -f ~/.aws/credentials ]] && grep -q "^\[default\]" ~/.aws/credentials; then
            profiles="default"$'\n'"$profiles"
        fi
    fi
    
    if [[ -z "$profiles" ]]; then
        _aws_log error "No AWS profiles found. Configure AWS CLI first."
        return 1
    fi
    
    local selected_profile
    selected_profile=$(echo "$profiles" | peco --prompt "$prompt_text")
    
    if [[ -z "$selected_profile" ]]; then
        _aws_log warning "No profile selected"
        return 1
    fi
    
    echo "$selected_profile"
    return 0
}

# Check AWS authentication status
check_aws_auth() {
    local profile="$1"
    local profile_arg=""
    
    if [[ -n "$profile" ]]; then
        profile_arg="--profile $profile"
    fi
    
    if aws sts get-caller-identity $profile_arg &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# AWS SSO login
aws_sso_login() {
    local profile="$1"
    
    if [[ -z "$profile" ]]; then
        profile=$(select_aws_profile "Select profile for SSO login:")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    
    _aws_log info "Logging in with AWS SSO profile: $profile"
    aws sso login --profile "$profile"
    
    if [[ $? -eq 0 ]]; then
        _aws_log success "AWS SSO login successful for profile: $profile"
        return 0
    else
        _aws_log error "AWS SSO login failed for profile: $profile"
        return 1
    fi
}

# Ensure AWS login (check auth and login if needed)
ensure_aws_login() {
    local profile="$1"
    
    if ! check_aws_auth "$profile"; then
        _aws_log warning "AWS authentication is invalid or expired. Attempting login..."
        aws_sso_login "$profile"
        return $?
    else
        _aws_log info "AWS authentication is valid (profile: $profile)"
        return 0
    fi
}

# =============================================================================
# EC2 Management
# =============================================================================

# Interactive EC2 instance selection
select_ec2() {
    local profile="$1"
    local filter_preset="$2"
    
    if [[ -z "$profile" ]]; then
        profile=$(select_aws_profile "Select profile for EC2:")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    
    if ! ensure_aws_login "$profile"; then
        _aws_log error "Authentication failed"
        return 1
    fi
    
    # Filter selection
    local filter_choice="$filter_preset"
    if [[ -z "$filter_choice" ]]; then
        _aws_log info "Select instance filter:"
        filter_choice=$(printf '%s\n' "${EC2_FILTERS[@]}" | peco --prompt "Filter:")
    fi
    
    # Build filter options
    local filter_option=""
    if [[ "$filter_choice" != "すべて表示" ]] && [[ -n "$filter_choice" ]]; then
        filter_option="--filters Name=tag:Name,Values=*${filter_choice}* Name=instance-state-name,Values=running"
    else
        filter_option="--filters Name=instance-state-name,Values=running"
    fi
    
    # Execute AWS command
    local result
    result=$(aws ec2 describe-instances --profile "$profile" $filter_option --output json --region "$AWS_REGION" 2>/dev/null)
    
    if [[ $? -ne 0 ]] || [[ -z "$result" ]]; then
        _aws_log error "Failed to fetch EC2 instances"
        return 1
    fi
    
    # Parse and format instance list
    local instance_list
    instance_list=$(echo "$result" | jq -r '
        .Reservations[].Instances[] |
        select(.State.Name == "running") |
        .InstanceId + " | " + 
        ((.Tags[]? | select(.Key=="Name") | .Value) // "NoName") + " | " + 
        .InstanceType + " | " + 
        (.PublicIpAddress // "No Public IP") + " | " + 
        .State.Name
    ' | sort)
    
    if [[ -z "$instance_list" ]]; then
        _aws_log warning "No running instances found"
        return 1
    fi
    
    # Interactive selection
    local selected_line
    selected_line=$(echo "$instance_list" | peco --prompt "Select EC2 instance:")
    
    if [[ -z "$selected_line" ]]; then
        _aws_log warning "No instance selected"
        return 1
    fi
    
    # Extract instance ID
    local instance_id
    instance_id=$(echo "$selected_line" | grep -o 'i-[a-zA-Z0-9]\{8,17\}')
    
    if [[ -n "$instance_id" ]] && [[ "$instance_id" =~ ^i-[a-zA-Z0-9]{8,17}$ ]]; then
        echo "$instance_id"
        return 0
    else
        _aws_log error "Invalid instance ID selected"
        return 1
    fi
}

# Connect to EC2 via SSM
ec2_connect() {
    local profile="$1"
    local instance_id="$2"
    
    if [[ -z "$profile" ]]; then
        profile=$(select_aws_profile "Select profile for EC2 connection:")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    
    if ! ensure_aws_login "$profile"; then
        _aws_log error "Authentication failed"
        return 1
    fi
    
    if [[ -z "$instance_id" ]]; then
        instance_id=$(select_ec2 "$profile")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    
    _aws_log info "Connecting to instance: $instance_id"
    aws ssm start-session \
        --target "$instance_id" \
        --profile "$profile" \
        --region "$AWS_REGION"
}

# =============================================================================
# RDS Management
# =============================================================================

# RDS port forwarding
rds_forward() {
    local profile="$1"
    local instance_id="$2"
    local env_name="$3"
    
    if [[ -z "$profile" ]]; then
        profile=$(select_aws_profile "Select profile for RDS connection:")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    
    if ! ensure_aws_login "$profile"; then
        _aws_log error "Authentication failed"
        return 1
    fi
    
    if [[ -z "$instance_id" ]]; then
        instance_id=$(select_ec2 "$profile")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    
    # Environment selection
    if [[ -z "$env_name" ]]; then
        local env_options
        env_options=$(printf '%s\n' "${RDS_ENVIRONMENTS[@]}" | cut -d':' -f1)
        env_name=$(echo "$env_options" | peco --prompt "Select RDS environment:")
        
        if [[ -z "$env_name" ]]; then
            _aws_log warning "No environment selected"
            return 1
        fi
    fi
    
    # Find RDS configuration
    local rds_config=""
    for config in "${RDS_ENVIRONMENTS[@]}"; do
        if [[ "$config" =~ ^${env_name}: ]]; then
            rds_config="$config"
            break
        fi
    done
    
    if [[ -z "$rds_config" ]]; then
        _aws_log error "Environment '$env_name' not found in configuration"
        return 1
    fi
    
    # Parse RDS configuration
    IFS=':' read -r env_name host remote_port local_port <<< "$rds_config"
    
    _aws_log info "Connecting to $env_name environment: $host"
    _aws_log info "Port forwarding: localhost:$local_port -> $host:$remote_port"
    
    aws ssm start-session \
        --profile "$profile" \
        --target "$instance_id" \
        --document-name AWS-StartPortForwardingSessionToRemoteHost \
        --parameters "host=$host,portNumber=$remote_port,localPortNumber=$local_port" \
        --region "$AWS_REGION"
}

# =============================================================================
# ECS Management
# =============================================================================

# ECS exec preparation
ecs_exec() {
    local profile="$1"
    local cluster_name="$2"
    local service_name="$3"
    
    if [[ -z "$profile" ]]; then
        profile=$(select_aws_profile "Select profile for ECS:")
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    
    if ! ensure_aws_login "$profile"; then
        _aws_log error "Authentication failed"
        return 1
    fi
    
    # Use provided cluster/service or fall back to config
    cluster_name="${cluster_name:-$ECS_CLUSTER_NAME}"
    service_name="${service_name:-$ECS_SERVICE_NAME}"
    
    # Get running tasks
    _aws_log info "Fetching ECS tasks..."
    local tasks
    tasks=$(aws ecs list-tasks \
        --profile "$profile" \
        --cluster "$cluster_name" \
        --service-name "$service_name" \
        --desired-status RUNNING \
        --query "taskArns[*]" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null)
    
    if [[ -z "$tasks" ]]; then
        _aws_log error "No running ECS tasks found"
        return 1
    fi
    
    # Format and select task
    local task_list
    task_list=$(echo "$tasks" | tr ' ' '\n' | awk -F'/' '{print $NF " | " $0}')
    
    local selected_task
    selected_task=$(echo "$task_list" | peco --prompt "Select ECS task:" | awk '{print $1}')
    
    if [[ -z "$selected_task" ]]; then
        _aws_log warning "No task selected"
        return 1
    fi
    
    # Generate ECS exec command
    local ecs_cmd="aws ecs execute-command --cluster $cluster_name --task $selected_task --container $ECS_CONTAINER_NAME --interactive --command \"$ECS_COMMAND\" --region $AWS_REGION --profile $profile"
    
    copy_to_clipboard "$ecs_cmd"
    
    # Find bastion server
    _aws_log info "Finding bastion server..."
    local bastion_id
    bastion_id=$(select_ec2 "$profile" "$BASTION_TAG_NAME")
    
    if [[ $? -ne 0 ]] || [[ -z "$bastion_id" ]]; then
        _aws_log error "No bastion server found"
        return 1
    fi
    
    _aws_log info "Connecting to bastion server: $bastion_id"
    _aws_log info "ECS exec command copied to clipboard. Paste it after connecting."
    
    aws ssm start-session \
        --profile "$profile" \
        --target "$bastion_id" \
        --region "$AWS_REGION"
}

# =============================================================================
# Interactive Menu System
# =============================================================================

# Confirmation prompt
_confirm() {
    local message="$1"
    read -r -p "$message (y/N): " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Main interactive menu
aws_helper_menu() {
    if ! _check_dependencies; then
        return 1
    fi
    
    local menu_options=(
        "🖥️  Connect to EC2 instance"
        "🗄️  RDS port forwarding"
        "🐳 ECS exec (via bastion)"
        "🔑 AWS SSO login"
        "👤 Select AWS profile"
        "⚙️  Initialize configuration"
        "📋 Show current configuration"
        "❓ Show help"
        "🚪 Exit"
    )
    
    while true; do
        echo
        _aws_log info "$SCRIPT_NAME v$VERSION"
        echo "==============================="
        
        local selected
        selected=$(printf '%s\n' "${menu_options[@]}" | peco --prompt "Select action:")
        
        case "$selected" in
            "🖥️  Connect to EC2 instance")
                ec2_connect
                ;;
            "🗄️  RDS port forwarding")
                rds_forward
                ;;
            "🐳 ECS exec (via bastion)")
                ecs_exec
                ;;
            "🔑 AWS SSO login")
                aws_sso_login
                ;;
            "👤 Select AWS profile")
                local profile
                profile=$(select_aws_profile)
                if [[ $? -eq 0 ]]; then
                    _aws_log info "Selected profile: $profile"
                    export AWS_PROFILE="$profile"
                fi
                ;;
            "⚙️  Initialize configuration")
                aws-helper-init
                load_config
                ;;
            "📋 Show current configuration")
                show_config
                ;;
            "❓ Show help")
                show_help
                ;;
            "🚪 Exit"|"")
                _aws_log info "Goodbye!"
                break
                ;;
            *)
                _aws_log warning "Invalid selection"
                ;;
        esac
        
        if [[ -n "$selected" ]] && [[ "$selected" != "🚪 Exit" ]]; then
            echo
            read -r -p "Press Enter to continue..."
        fi
    done
}

# Show current configuration
show_config() {
    echo
    _aws_log info "Current Configuration"
    echo "===================="
    echo "AWS Region: ${AWS_REGION:-Not set}"
    echo "ECS Cluster: ${ECS_CLUSTER_NAME:-Not set}"
    echo "ECS Service: ${ECS_SERVICE_NAME:-Not set}"
    echo "ECS Container: ${ECS_CONTAINER_NAME:-Not set}"
    echo "Bastion Tag: ${BASTION_TAG_NAME:-Not set}"
    echo
    echo "EC2 Filters:"
    printf '%s\n' "${EC2_FILTERS[@]}" | sed 's/^/  - /'
    echo
    echo "RDS Environments:"
    printf '%s\n' "${RDS_ENVIRONMENTS[@]}" | sed 's/^/  - /'
}

# Show help information
show_help() {
    cat << 'EOF'

AWS Helper Tools - Help
=======================

Available Commands:
  aws_helper_menu     - Launch interactive menu
  ec2_connect         - Connect to EC2 instance via SSM
  rds_forward         - Set up RDS port forwarding
  ecs_exec           - Execute command in ECS container
  aws_sso_login      - Login via AWS SSO
  aws-helper-init    - Initialize configuration file

Configuration:
  Edit ~/.aws-helper-config.sh to customize settings
  
Dependencies:
  - AWS CLI v2
  - peco (interactive filtering)
  - jq (JSON processing)
  
Examples:
  aws_helper_menu                    # Interactive menu
  ec2_connect my-profile            # Connect with specific profile
  rds_forward my-profile i-123 STG  # RDS forwarding with parameters
  aws-helper-init ~/my-config.sh    # Custom config location

EOF
}

# =============================================================================
# Aliases and Shortcuts
# =============================================================================

# Define convenient aliases
alias awsh='aws_helper_menu'
alias awsm='aws_helper_menu'
alias ec2='ec2_connect'
alias rds='rds_forward'
alias ecs='ecs_exec'
alias awsl='aws_sso_login'

# =============================================================================
# Initialization
# =============================================================================

# Load configuration on script source
load_config

# Auto-run menu if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _check_dependencies || exit 1
    _validate_aws_config || exit 1
    aws_helper_menu
fi
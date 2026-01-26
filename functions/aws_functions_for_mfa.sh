#!/bin/bash
# AWS Helper Tools (MFA Edition)
# Operates strictly with environment credentials (MFA-backed tokens).

# =============================================================================
# Configuration and Defaults
# =============================================================================
readonly MFA_SCRIPT_NAME="AWS Helper Tools (MFA)"
readonly MFA_VERSION="1.0.0"

# =============================================================================
# Utilities
# =============================================================================

# Colors (optional, safe fallback)
COLOR_SUCCESS="\033[32m"; COLOR_WARNING="\033[33m"; COLOR_ERROR="\033[31m"; COLOR_INFO="\033[36m"; COLOR_RESET="\033[0m"

# =============================================================================
# External Configuration (MFA-specific)
# =============================================================================
# Load optional MFA config. Prefer $HOME/.aws-mfa-config.sh, fall back to repo-local file.
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  MFA_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  # zsh: use ${(%):-%N} to get the current sourced file path
  MFA_SCRIPT_DIR="$(cd "$(dirname "${(%):-%N}")" && pwd)"
else
  MFA_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
MFA_CONFIG_FILE="${MFA_CONFIG_FILE:-$HOME/.aws-mfa-config.sh}"
if [[ ! -f "$MFA_CONFIG_FILE" && -f "${MFA_SCRIPT_DIR}/aws_mfa_config.sh" ]]; then
  MFA_CONFIG_FILE="${MFA_SCRIPT_DIR}/aws_mfa_config.sh"
fi
if [[ -f "$MFA_CONFIG_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$MFA_CONFIG_FILE"
fi

# Helper: resolve RDS settings from MFA_RDS_ENVIRONMENTS using
# MFA_RDS_ENV or MFA_RDS_DEFAULT_ENV. Usage:
#   _mfa_resolve_rds_env print  -> prints: ENV HOST REMOTE_PORT LOCAL_PORT
#   _mfa_resolve_rds_env set    -> sets MFA_RDS_HOST/REMOTE/LOCAL if unset
_mfa_resolve_rds_env() {
  local mode="${1:-set}"
  local target_env="${MFA_RDS_ENV:-${MFA_RDS_DEFAULT_ENV:-STG}}"
  local entry env host rport lport
  [[ ${#MFA_RDS_ENVIRONMENTS[@]} -gt 0 ]] 2>/dev/null || return 1
  for entry in "${MFA_RDS_ENVIRONMENTS[@]}"; do
    IFS=':' read -r env host rport lport <<< "$entry"
    if [[ "$env" == "$target_env" ]]; then
      if [[ "$mode" == "print" ]]; then
        printf '%s %s %s %s\n' "$env" "$host" "$rport" "$lport"
      else
        [[ -z "${MFA_RDS_HOST-}" ]] && MFA_RDS_HOST="$host"
        [[ -z "${MFA_RDS_REMOTE_PORT-}" ]] && MFA_RDS_REMOTE_PORT="$rport"
        [[ -z "${MFA_RDS_LOCAL_PORT-}" ]] && MFA_RDS_LOCAL_PORT="$lport"
        export MFA_RDS_SELECTED_ENV="$env"
      fi
      return 0
    fi
  done
  return 1
}

# List SSO profiles from ~/.aws/config (includes [default] if SSO)
_mfa_list_sso_profiles() {
  local config_file="${HOME}/.aws/config"
  [[ -f "$config_file" ]] || return 1
  awk '
    function flush() { if (profile && sso) print profile }
    /^\[default\]/ { flush(); profile="default"; sso=0; next }
    /^\[profile / { flush(); profile=$0; sub(/^\[profile /,"",profile); sub(/\]$/,"",profile); sso=0; next }
    /^[[:space:]]*sso_(start_url|session|account_id|role_name)[[:space:]]*=/ { sso=1 }
    END { flush() }
  ' "$config_file"
}

# List credential profiles from ~/.aws/credentials (includes [default])
_mfa_list_credential_profiles() {
  local cred_file="${HOME}/.aws/credentials"
  [[ -f "$cred_file" ]] || return 1
  awk '
    function flush() { if (profile && has_key) print profile }
    /^\[/ {
      flush()
      profile=$0
      sub(/^\[/,"",profile); sub(/\]$/,"",profile)
      has_key=0
      next
    }
    /^[[:space:]]*aws_access_key_id[[:space:]]*=/ { has_key=1 }
    END { flush() }
  ' "$cred_file"
}

# =============================================================================
# User Configuration (Hardcoded defaults)
# Edit the following values to your environment.
# You can still override via environment variables before sourcing if needed.
# =============================================================================

# Example RDS endpoint and ports (set in ~/.aws-mfa-config.sh)
MFA_RDS_HOST="${MFA_RDS_HOST-}"
MFA_RDS_REMOTE_PORT="${MFA_RDS_REMOTE_PORT:-3306}"
MFA_RDS_LOCAL_PORT="${MFA_RDS_LOCAL_PORT:-13306}"

# Bastion auto-selection (optional)
# If set, this instance ID is used directly. Otherwise, tag filter is tried, then interactive select.
MFA_BASTION_INSTANCE_ID="${MFA_BASTION_INSTANCE_ID-}"
MFA_BASTION_TAG_KEY="${MFA_BASTION_TAG_KEY:-Name}"
MFA_BASTION_TAG_VALUE="${MFA_BASTION_TAG_VALUE:-bastion}"

_mfa_log() {
  local level="$1"; shift
  local msg="$*"
  case "$level" in
    success) echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} $msg" ;;
    warning) echo -e "${COLOR_WARNING}⚠️${COLOR_RESET} $msg" ;;
    error)   echo -e "${COLOR_ERROR}❌${COLOR_RESET} $msg" >&2 ;;
    info)    echo -e "${COLOR_INFO}ℹ️${COLOR_RESET} $msg" ;;
    *) echo "$msg" ;;
  esac
}

# Cross-shell prompt reader (zsh/bash)
_mfa_prompt() {
  local silent=""
  if [[ "${1-}" == "-s" ]]; then silent="-s"; shift; fi
  local var="$1"; shift
  local prompt="$1"
  if [[ -n "${ZSH_VERSION-}" ]]; then
    if [[ -n "$silent" ]]; then
      read -r -s "?$prompt" "$var"; echo
    else
      read -r "?$prompt" "$var"
    fi
  else
    if [[ -n "$silent" ]]; then
      read -r -s -p "$prompt" "$var"; echo
    else
      read -r -p "$prompt" "$var"
    fi
  fi
}

_mfa_copy_to_clipboard() {
  local data="$1"
  if [[ -z "$data" ]]; then return 1; fi
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$data" | pbcopy
    return 0
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$data" | xclip -selection clipboard
    return 0
  elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$data" | xsel --clipboard --input
    return 0
  elif command -v clip.exe >/dev/null 2>&1; then
    printf '%s' "$data" | clip.exe
    return 0
  fi
  return 1
}

_mfa_check_dependencies() {
  local missing=()
  command -v aws >/dev/null 2>&1 || missing+=("aws-cli")
  command -v jq >/dev/null 2>&1 || missing+=("jq")
  command -v peco >/dev/null 2>&1 || true # optional
  if (( ${#missing[@]} > 0 )); then
    _mfa_log error "Missing dependencies: ${missing[*]}"
    return 1
  fi
  return 0
}

_mfa_set_defaults() {
  AWS_REGION="${AWS_REGION:-ap-northeast-1}"
  # When picking by Name, show only SSM-online instances by default
  MFA_EC2_SSM_ONLY="${MFA_EC2_SSM_ONLY:-true}"
}

_mfa_require_env_auth() {
  # Accept any valid session credentials present in the environment.
  # Prefer AWS_SESSION_TOKEN (temporary credentials), but do not require our internal marker.
  if [[ -z "${AWS_SESSION_TOKEN-}" ]]; then
    _mfa_log error "No temporary session credentials detected. Run 'mfa_session' first."
    return 1
  fi
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    _mfa_log error "Environment credentials invalid or expired. Re-run 'mfa_session'."
    return 1
  fi
  return 0
}

# Return 0 if current env has a live MFA session, else 1
mfa_session_alive() {
  [[ -n "${AWS_SESSION_TOKEN-}" ]] || return 1
  aws sts get-caller-identity >/dev/null 2>&1
}

# Convert ISO8601 to epoch seconds using available tools
_mfa_iso_to_epoch() {
  local iso="$1"
  [[ -n "$iso" ]] || return 1
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$iso" 2>/dev/null <<'PY'
import sys
from datetime import datetime, timezone
s = sys.argv[1]
try:
    if s.endswith('Z'):
        s = s.replace('Z', '+00:00')
    dt = datetime.fromisoformat(s)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    print(int(dt.timestamp()))
except Exception:
    sys.exit(1)
PY
    return $?
  fi
  if command -v gdate >/dev/null 2>&1; then
    gdate -u -d "$iso" +%s 2>/dev/null && return 0
  fi
  if [[ "$iso" =~ Z$ ]]; then
    date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso" +%s 2>/dev/null && return 0
  fi
  local no_colon
  no_colon="${iso/:/}"
  date -u -j -f "%Y-%m-%dT%H:%M:%S%z" "$no_colon" +%s 2>/dev/null && return 0
  return 1
}

# Show human-readable status for the current MFA session
mfa_session_status() {
  local status="invalid" account arn user exp now epoch_exp remain_s remain_h remain_m
  now=$(date -u +%s)
  if mfa_session_alive; then
    status="active"
  else
    status="expired/invalid"
  fi
  account=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)
  arn=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null || true)
  user=$(aws sts get-caller-identity --query UserId --output text 2>/dev/null || true)
  exp="${AWS_MFA_EXPIRATION-}"
  echo
  _mfa_log info "MFA Session Status"
  echo "===================="
  echo "Status: $status"
  [[ -n "$account" ]] && echo "Account: $account"
  [[ -n "$user" ]] && echo "UserId: $user"
  [[ -n "$arn" ]] && echo "Arn: $arn"
  echo "Region: ${AWS_REGION:-Not set}"
  if [[ -n "$exp" ]]; then
    echo "Expiration (UTC): $exp"
    if epoch_exp=$(_mfa_iso_to_epoch "$exp"); then
      remain_s=$(( epoch_exp - now ))
      if (( remain_s >= 0 )); then
        remain_h=$(( remain_s / 3600 ))
        remain_m=$(( (remain_s % 3600) / 60 ))
        echo "Time left: ${remain_h}h ${remain_m}m"
      else
        echo "Time left: expired"
      fi
    fi
  else
    echo "Expiration: unknown (AWS_MFA_EXPIRATION not set)"
  fi
}

# Ensure a valid MFA session exists; if not, start the MFA flow
_mfa_ensure_session() {
  if _mfa_require_env_auth; then
    return 0
  fi
  _mfa_log warning "No valid MFA session found. Starting MFA authentication..."
  if mfa_session; then
    return 0
  else
    _mfa_log error "MFA session could not be established."
    return 1
  fi
}

# =============================================================================
# Core Helpers
# =============================================================================

mfa_select_ec2() {
  local filter_preset="$1"
  if ! _mfa_ensure_session; then return 1; fi

  local filter_choice="$filter_preset"
  if [[ -z "$filter_choice" ]]; then
    _mfa_log info "Select instance filter:"
    if command -v peco >/dev/null 2>&1; then
      local opts=("すべて表示" "bastion" "jump" "web" "db")
      filter_choice=$(printf '%s\n' "${opts[@]}" | peco --prompt "Filter:")
    else
      _mfa_prompt filter_choice "Filter (blank for all): "
      filter_choice="${filter_choice:-すべて表示}"
    fi
  fi

  # フィルタ条件に応じて異なるコマンドを実行
  local out rc
  if [[ "$filter_choice" != "すべて表示" ]] && [[ -n "$filter_choice" ]]; then
    out=$(aws ec2 describe-instances \
      --filters "Name=tag:Name,Values=*${filter_choice}*" "Name=instance-state-name,Values=running" \
      --output json --region "$AWS_REGION" 2>&1)
    rc=$?
  else
    out=$(aws ec2 describe-instances \
      --filters "Name=instance-state-name,Values=running" \
      --output json --region "$AWS_REGION" 2>&1)
    rc=$?
  fi
  if (( rc != 0 )) || [[ -z "$out" ]]; then
    _mfa_log error "Failed to fetch EC2 instances"; [[ -n "$out" ]] && echo "$out" | sed 's/^/  /'
    # Fallback: allow manual instance-id entry when listing is not permitted
    local manual=""
    _mfa_prompt manual "Enter instance-id (i-xxxxxxxx) or blank to cancel: "
    if [[ "$manual" =~ ^i-[a-zA-Z0-9]{8,17}$ ]]; then
      echo "$manual"
      return 0
    fi
    return 1
  fi

  local list
  list=$(echo "$out" | jq -r '
    .Reservations[].Instances[] |
    select(.State.Name=="running") |
    .InstanceId + " | " + ((.Tags[]? | select(.Key=="Name") | .Value) // "NoName") + " | " +
    .InstanceType + " | " + (.PrivateIpAddress // .PublicIpAddress // "No IP")
  ' | sort)

  if [[ -z "$list" ]]; then
    _mfa_log warning "No instances matched."
    local manual=""
    _mfa_prompt manual "Enter instance-id or Name filter (blank to cancel): "
    if [[ -z "$manual" ]]; then return 1; fi
    if [[ "$manual" =~ ^i-[a-zA-Z0-9]{8,17}$ ]]; then
      echo "$manual"
      return 0
    fi
    out=$(aws ec2 describe-instances \
      --filters "Name=tag:Name,Values=*${manual}*" "Name=instance-state-name,Values=running" \
      --output json --region "$AWS_REGION" 2>/dev/null)
    list=$(echo "$out" | jq -r '
      .Reservations[].Instances[] |
      select(.State.Name=="running") |
      .InstanceId + " | " + ((.Tags[]? | select(.Key=="Name") | .Value) // "NoName")
    ' | sort)
    if [[ -z "$list" ]]; then _mfa_log warning "No instances for filter: $manual"; return 1; fi
  fi

  local selected
  if command -v peco >/dev/null 2>&1; then
    selected=$(echo "$list" | peco --prompt "Select EC2 instance:")
  else
    echo "$list" | nl -ba
    local idx; _mfa_prompt idx "Choose number: "
    selected=$(echo "$list" | sed -n "${idx}p")
  fi
  local instance_id
  instance_id=$(echo "$selected" | grep -o 'i-[a-zA-Z0-9]\{8,17\}')
  if [[ "$instance_id" =~ ^i-[a-zA-Z0-9]{8,17}$ ]]; then
    echo "$instance_id"
    return 0
  fi
  _mfa_log error "Invalid selection"; return 1
}

# List EC2 instances by Name tag and let user pick one; prints instance-id
mfa_ec2_pick() {
  if ! _mfa_ensure_session; then return 1; fi
  local out rc selected instance_id
  out=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running \
        --output json --region "$AWS_REGION" 2>&1); rc=$?
  if (( rc != 0 )) || [[ -z "$out" ]]; then
    _mfa_log error "Failed to fetch EC2 instances"; [[ -n "$out" ]] && echo "$out" | sed 's/^/  /'
    return 1
  fi
  # Build base table (array) and id list
  local table_json ids
  table_json=$(echo "$out" | jq -c '[.Reservations[].Instances[] | {Id:.InstanceId, Name:((.Tags[]? | select(.Key=="Name") | .Value) // "NoName"), Type:(.InstanceType // "-"), Ip:(.PrivateIpAddress // .PublicIpAddress // "No IP"), State:(.State.Name // "-")}]')
  ids=$(echo "$table_json" | jq -r '.[].Id' | paste -sd"," -)
  if [[ -z "$ids" ]]; then
    _mfa_log warning "No running instances found"; return 1
  fi
  # Query SSM registration for these ids
  local ssm_map
  ssm_map=$(aws ssm describe-instance-information --filters Key=InstanceIds,Values="$ids" \
             --query 'InstanceInformationList[].{Id:InstanceId,Ping:PingStatus}' --output json 2>/dev/null | jq -r '.[] | @tsv' 2>/dev/null || true)
  # Build selection list with SSM status
  # Join EC2 table with SSM map via jq and format lines
  local list
  list=$(jq -rn --argjson ec2 "$table_json" --arg ssm "$ssm_map" '
    def ssm_ping($m):
      ( $m | split("\n") | map(select(length>0) | split("\t")) ) as $rows |
      reduce $rows[] as $r ({}; . + { ($r[0]): ($r[1]) });
    ($ec2) as $rows |
    (ssm_ping($ssm)) as $map |
    $rows | map( . as $e |
         ($map[ $e.Id ] // "None") as $ping |
         {Name:$e.Name, Id:$e.Id, Type:$e.Type, Ip:$e.Ip, State:$e.State, Ping:$ping}) |
    (if env.MFA_EC2_SSM_ONLY == "true" then map(select(.Ping=="Online")) else . end) |
    sort_by(.Name) |
    map( "\(.Name) | \(.Id) | \(.Type) | \(.Ip) | \(.State) | SSM:\(.Ping)" ) |
    .[]
  ')
  if [[ -z "$list" ]]; then
    _mfa_log warning "No instances matched current filter (MFA_EC2_SSM_ONLY=$MFA_EC2_SSM_ONLY)"; return 1
  fi
  if command -v peco >/dev/null 2>&1; then
    selected=$(echo "$list" | peco --prompt "Pick EC2 (type to filter):")
  else
    echo "$list" | nl -ba
    local idx; _mfa_prompt idx "Choose number: "; selected=$(echo "$list" | sed -n "${idx}p")
  fi
  instance_id=$(echo "$selected" | awk -F ' \| ' '{gsub(/^ +| +$/,"",$2); print $2}')
  if [[ "$instance_id" =~ ^i-[A-Za-z0-9]{8,17}$ ]]; then
    if _mfa_copy_to_clipboard "$instance_id"; then
      _mfa_log info "Instance ID copied to clipboard." >&2
    else
      _mfa_log warning "Clipboard helper not available; skipped copy." >&2
    fi
    echo "$instance_id"
    return 0
  fi
  return 1
}

# Connect to EC2 by picking from Name list
mfa_ec2_connect_by_name() {
  local id
  if ! id=$(mfa_ec2_pick); then return 1; fi
  _mfa_log info "Connecting via SSM: $id"
  # Pre-check SSM PingStatus for clearer error message
  local ping
  ping=$(aws ssm describe-instance-information --filters Key=InstanceIds,Values=$id \
          --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null || true)
  if [[ "$ping" != "Online" ]]; then
    _mfa_log error "Instance is not SSM-Online (PingStatus=${ping:-None})."
    echo "Hint: run 'mfa_ssm_doctor $id' to diagnose IAM role, Agent, and VPC endpoints."
    return 1
  fi
  aws ssm start-session --target "$id" --region "$AWS_REGION"
  local rc=$?
  if (( rc != 0 )); then
    _mfa_log error "SSM start-session failed (exit code: $rc)."
    echo "Hint: run 'mfa_ssm_doctor $id' for detailed checks."
    return $rc
  fi
}

# Diagnose why SSM can't connect to an instance and suggest fixes
mfa_ssm_doctor() {
  local id="$1"
  if [[ -z "$id" ]]; then
    _mfa_log info "Pick instance for SSM diagnose"
    id=$(mfa_ec2_pick) || return 1
  fi
  _mfa_ensure_session || return 1
  echo; _mfa_log info "SSM Doctor for $id"; echo "===================="

  # 1) EC2 metadata
  local di json name state vpc subnet profileArn profileName publicIp privateIp
  json=$(aws ec2 describe-instances --instance-ids "$id" --region "$AWS_REGION" --output json 2>/dev/null) || true
  if [[ -z "$json" ]]; then _mfa_log error "describe-instances failed"; return 1; fi
  name=$(echo "$json" | jq -r '.Reservations[0].Instances[0].Tags[]? | select(.Key=="Name") | .Value' | head -n1)
  state=$(echo "$json" | jq -r '.Reservations[0].Instances[0].State.Name')
  vpc=$(echo "$json" | jq -r '.Reservations[0].Instances[0].VpcId')
  subnet=$(echo "$json" | jq -r '.Reservations[0].Instances[0].SubnetId')
  profileArn=$(echo "$json" | jq -r '.Reservations[0].Instances[0].IamInstanceProfile.Arn // empty')
  publicIp=$(echo "$json" | jq -r '.Reservations[0].Instances[0].PublicIpAddress // empty')
  privateIp=$(echo "$json" | jq -r '.Reservations[0].Instances[0].PrivateIpAddress // empty')
  if [[ -n "$profileArn" ]]; then profileName="${profileArn##*/}"; fi
  echo "Name: ${name:-(none)}"
  echo "State: $state  VPC: ${vpc:-?}  Subnet: ${subnet:-?}"
  echo "IP: public=${publicIp:--} private=${privateIp:--}"
  echo "InstanceProfile: ${profileName:-none}"

  # 2) SSM registration status
  local ssmj ping regId lastPing
  ssmj=$(aws ssm describe-instance-information \
          --filters Key=InstanceIds,Values=$id \
          --query 'InstanceInformationList[0]' --output json 2>/dev/null) || true
  if [[ -n "$ssmj" && "$ssmj" != null ]]; then
    ping=$(echo "$ssmj" | jq -r '.PingStatus')
    regId=$(echo "$ssmj" | jq -r '.InstanceId')
    lastPing=$(echo "$ssmj" | jq -r '.LastPingDateTime')
    echo "SSM Registration: found (PingStatus=$ping, LastPing=$lastPing)"
  else
    echo "SSM Registration: not found"
  fi

  # 3) IAM role policy check
  if [[ -n "$profileName" ]]; then
    local prof roles roleName hasCore=false
    prof=$(aws iam get-instance-profile --instance-profile-name "$profileName" --output json 2>/dev/null) || true
    roles=$(echo "$prof" | jq -r '.InstanceProfile.Roles[].RoleName')
    for roleName in $roles; do
      if aws iam list-attached-role-policies --role-name "$roleName" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null | grep -q 'AmazonSSMManagedInstanceCore'; then
        hasCore=true; break
      fi
    done
    echo "IAM Role: ${roleName:-none}  CorePolicy: $([[ "$hasCore" == true ]] && echo present || echo missing)"
  else
    echo "IAM Role: none (instance profile not attached)"
  fi

  # 4) VPC endpoints for SSM
  if [[ -n "$vpc" ]]; then
    local rgn="$AWS_REGION" svc out
    for svc in ssm ssmmessages ec2messages; do
      out=$(aws ec2 describe-vpc-endpoints --filters \
            Name=vpc-id,Values="$vpc" \
            Name=service-name,Values="com.amazonaws.${rgn}.${svc}" \
            --query 'VpcEndpoints[?State==`available`].VpcEndpointId' --output text 2>/dev/null || true)
      printf 'VPC Endpoint (%s): %s\n' "$svc" "${out:-not found}"
    done
  fi

  echo
  _mfa_log info "Next steps"
  echo "- If 'IAM Role: ... CorePolicy: missing' → attach AmazonSSMManagedInstanceCore"
  echo "    aws iam attach-role-policy --role-name <ROLE> \\
      --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  echo "- If 'IAM Role: none' → create instance profile + role and associate"
  echo "    aws iam create-role --role-name EC2SSMCore \\
      --assume-role-policy-document '$(cat <<'JSON'
{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}
JSON
)'"
  echo "    aws iam attach-role-policy --role-name EC2SSMCore \\
      --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  echo "    aws iam create-instance-profile --instance-profile-name EC2SSMCore"
  echo "    aws iam add-role-to-instance-profile --instance-profile-name EC2SSMCore --role-name EC2SSMCore"
  echo "    aws ec2 associate-iam-instance-profile --instance-id $id --iam-instance-profile Name=EC2SSMCore"
  echo "- If endpoints 'not found' and no internet/NAT → create Interface endpoints (enable Private DNS)"
  echo "    aws ec2 create-vpc-endpoint --vpc-id $vpc --vpc-endpoint-type Interface \\
      --service-name com.amazonaws.$AWS_REGION.<ssm|ssmmessages|ec2messages> \\
      --subnet-ids <subnet-ids> --security-group-ids <sg-id> --private-dns-enabled"
  echo "- Ensure SSM Agent is installed and running on the instance (Amazon Linux 2は同梱)"
  echo "    sudo systemctl status amazon-ssm-agent"
}

mfa_find_bastion() {
  # 1) Explicit instance id
  if [[ -n "${MFA_BASTION_INSTANCE_ID-}" ]]; then
    local state
    state=$(aws ec2 describe-instances --instance-ids "$MFA_BASTION_INSTANCE_ID" --region "$AWS_REGION" \
      --query 'Reservations[].Instances[].State.Name' --output text 2>/dev/null | head -n1 || true)
    if [[ "$state" == "running" ]]; then
      echo "$MFA_BASTION_INSTANCE_ID"; return 0
    fi
  fi
  # 2) Tag filter
  if [[ -n "${MFA_BASTION_TAG_KEY-}" && -n "${MFA_BASTION_TAG_VALUE-}" ]]; then
    local out ids
    out=$(aws ec2 describe-instances \
      --filters "Name=tag:${MFA_BASTION_TAG_KEY},Values=${MFA_BASTION_TAG_VALUE}" "Name=instance-state-name,Values=running" \
      --query 'Reservations[].Instances[].InstanceId' --output text --region "$AWS_REGION" 2>/dev/null || true)
    if [[ -n "$out" ]]; then
      # If exactly one, pick it; else defer to interactive
      ids=($out)
      if [[ ${#ids[@]} -eq 1 ]]; then
        echo "${ids[0]}"; return 0
      fi
    fi
    # Defer to interactive full filter menu (includes '設定済み一覧')
    local sel
    sel=$(mfa_select_ec2) || return 1
    if [[ -n "$sel" ]]; then
      echo "$sel"; return 0
    fi
    return 1
  fi
  # 3) Fallback interactive with full filter menu (includes '設定済み一覧')
  mfa_select_ec2
}

## (removed) Config-driven EC2 list/connect helpers

mfa_select_rds() {
  local tag_key="${MFA_RDS_TAG_KEY-}"
  local tag_value="${MFA_RDS_TAG_VALUE-}"
  if ! _mfa_ensure_session; then return 1; fi

  local instances_json
  instances_json=$(aws rds describe-db-instances --region "$AWS_REGION" \
    --query 'DBInstances[].{Id:DBInstanceIdentifier,Endpoint:Endpoint.Address,Port:Endpoint.Port,Engine:Engine,Status:DBInstanceStatus,Arn:DBInstanceArn}' \
    --output json 2>/dev/null) || true
  if [[ -z "$instances_json" || "$instances_json" == "null" ]]; then
    _mfa_log error "Failed to fetch RDS DB instances"
    return 1
  fi

  local filtered_json="$instances_json"
  if [[ -n "$tag_key" && -n "$tag_value" ]]; then
    _mfa_log info "Filtering RDS by tag: ${tag_key}=${tag_value}"
    # Build a newline-separated list of matching instances by checking tags per ARN
    local ids engines statuses hosts ports arns
    ids=($(echo "$instances_json" | jq -r '.[].Id'))
    engines=($(echo "$instances_json" | jq -r '.[].Engine'))
    statuses=($(echo "$instances_json" | jq -r '.[].Status'))
    hosts=($(echo "$instances_json" | jq -r '.[].Endpoint'))
    ports=($(echo "$instances_json" | jq -r '.[].Port'))
    arns=($(echo "$instances_json" | jq -r '.[].Arn'))
    local keep_idx=()
    local i
    for ((i=0; i<${#arns[@]}; i++)); do
      local arn="${arns[$i]}"
      if [[ -z "$arn" ]]; then continue; fi
      if aws rds list-tags-for-resource --resource-name "$arn" --region "$AWS_REGION" \
           --query 'TagList[?Key==`'"$tag_key"'` && Value==`'"$tag_value"'`]' --output text 2>/dev/null | grep -q .; then
        keep_idx+=("$i")
      fi
    done
    if (( ${#keep_idx[@]} == 0 )); then
      _mfa_log warning "No RDS instances matched the tag filter"
      return 1
    fi
    # Reconstruct filtered list as lines for selection
    local list=""
    for idx in "${keep_idx[@]}"; do
      list+="${ids[$idx]} | ${engines[$idx]} | ${statuses[$idx]} | ${hosts[$idx]} | ${ports[$idx]}\n"
    done
    list=$(printf "%b" "$list" | sort)
    local selected
    if command -v peco >/dev/null 2>&1; then
      selected=$(printf '%s\n' "$list" | peco --prompt "Select RDS instance:")
    else
      printf '%s\n' "$list" | nl -ba
      local idxsel; _mfa_prompt idxsel "Choose number: "; selected=$(printf '%s\n' "$list" | sed -n "${idxsel}p")
    fi
    local host port
    host=$(echo "$selected" | awk -F ' \| ' '{gsub(/^ +| +$/,"",$4); print $4}')
    port=$(echo "$selected" | awk -F ' \| ' '{gsub(/^ +| +$/,"",$5); print $5}')
    if [[ -n "$host" && -n "$port" ]]; then
      printf '%s %s\n' "$host" "$port"
      return 0
    else
      _mfa_log warning "No RDS instance selected"
      return 1
    fi
  else
    # No tag filter: build selection from all instances
    local list
    list=$(echo "$instances_json" | jq -r '.[] | "\(.Id) | \(.Engine) | \(.Status) | \(.Endpoint) | \(.Port)"' | sort)
    if [[ -z "$list" ]]; then
      _mfa_log warning "No RDS instances found"
      return 1
    fi
    local selected
    if command -v peco >/dev/null 2>&1; then
      selected=$(printf '%s\n' "$list" | peco --prompt "Select RDS instance:")
    else
      printf '%s\n' "$list" | nl -ba
      local idxsel; _mfa_prompt idxsel "Choose number: "; selected=$(printf '%s\n' "$list" | sed -n "${idxsel}p")
    fi
    local host port
    host=$(echo "$selected" | awk -F ' \| ' '{gsub(/^ +| +$/,"",$4); print $4}')
    port=$(echo "$selected" | awk -F ' \| ' '{gsub(/^ +| +$/,"",$5); print $5}')
    if [[ -n "$host" && -n "$port" ]]; then
      printf '%s %s\n' "$host" "$port"
      return 0
    else
      _mfa_log warning "No RDS instance selected"
      return 1
    fi
  fi
}

mfa_ec2_connect() {
  local instance_id="$1"
  if ! _mfa_ensure_session; then return 1; fi
  if [[ -z "$instance_id" ]]; then
    _mfa_prompt instance_id "Instance ID (i-xxxxxxxx, blank for auto-select): "
  fi
  if [[ -n "$instance_id" ]]; then
    if [[ "$instance_id" =~ (i-[A-Za-z0-9]{8,17}) ]]; then
      instance_id="${BASH_REMATCH[1]}"
    else
      _mfa_log warning "Provided value does not contain a valid instance ID; prompting instead."
      instance_id=""
    fi
  fi
  if [[ -z "$instance_id" ]]; then
    if ! instance_id=$(mfa_find_bastion); then
      _mfa_log warning "Bastion discovery failed. Enter instance-id manually."
      _mfa_prompt instance_id "Instance ID (i-xxxxxxxx): "
    fi
  fi
  if [[ -z "${instance_id//[[:space:]]/}" ]]; then
    _mfa_log error "Instance ID is required"
    return 1
  fi
  if [[ "$instance_id" =~ (i-[A-Za-z0-9]{8,17}) ]]; then
    instance_id="${BASH_REMATCH[1]}"
  else
    _mfa_log error "Invalid instance ID"
    return 1
  fi
  _mfa_log info "Connecting via SSM: $instance_id"
  aws ssm start-session --target "$instance_id" --region "$AWS_REGION"
}

mfa_rds_forward() {
  local instance_id="$1"
  local rds_host="$2"
  local remote_port="$3"
  local local_port="$4"
  if ! _mfa_ensure_session; then return 1; fi

  if [[ -z "$instance_id" ]]; then
    _mfa_prompt instance_id "Instance ID (i-xxxxxxxx, blank for auto-select): "
  fi
  if [[ -n "$instance_id" ]]; then
    if [[ "$instance_id" =~ (i-[A-Za-z0-9]{8,17}) ]]; then
      instance_id="${BASH_REMATCH[1]}"
    else
      _mfa_log warning "Provided value does not contain a valid instance ID; prompting instead."
      instance_id=""
    fi
  fi

  if [[ -z "$instance_id" ]]; then
    if ! instance_id=$(mfa_find_bastion); then
      _mfa_log warning "Bastion discovery failed. Enter instance-id manually."
      _mfa_prompt instance_id "Instance ID (i-xxxxxxxx): "
      if [[ ! "$instance_id" =~ ^i-[a-zA-Z0-9]{8,17}$ ]]; then
        _mfa_log error "Invalid instance ID"
        return 1
      fi
    fi
  fi

  # Resolve RDS host/ports via config first (non-interactive), then fallback to interactive selection
  if [[ -z "$rds_host" || -z "$remote_port" || -z "$local_port" ]]; then
    local env_info env_name env_host env_rport env_lport
    if env_info=$(_mfa_resolve_rds_env print 2>/dev/null); then
      env_name=$(awk '{print $1}' <<<"$env_info")
      env_host=$(awk '{print $2}' <<<"$env_info")
      env_rport=$(awk '{print $3}' <<<"$env_info")
      env_lport=$(awk '{print $4}' <<<"$env_info")
      [[ -z "$rds_host" ]] && rds_host="$env_host"
      [[ -z "$remote_port" ]] && remote_port="$env_rport"
      [[ -z "$local_port" ]] && local_port="$env_lport"
    fi
  fi
  if [[ -z "$rds_host" || -z "$remote_port" ]]; then
    local hp
    if hp=$(mfa_select_rds); then
      rds_host="${hp%% *}"; remote_port="${hp##* }"
    fi
  fi
  # Fall back to configured defaults/prompts if still missing
  if [[ -z "$rds_host" ]]; then
    rds_host="${MFA_RDS_HOST:-$rds_host}"
  fi
  if [[ -z "$remote_port" ]]; then
    remote_port="${MFA_RDS_REMOTE_PORT:-3306}"
  fi
  if [[ -z "$local_port" ]]; then
    local default_local_port="${MFA_RDS_LOCAL_PORT:-13306}"
    _mfa_prompt local_port "Local port [${default_local_port}]: "
    local_port="${local_port:-$default_local_port}"
  fi
  _mfa_log info "Port forwarding: localhost:${local_port} -> ${rds_host}:${remote_port}"
  aws ssm start-session \
    --target "$instance_id" \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "host=${rds_host},portNumber=${remote_port},localPortNumber=${local_port}" \
    --region "$AWS_REGION"
}

mfa_show_config() {
  echo; _mfa_log info "Current Configuration (MFA)"; echo "===================="
  echo "AWS Region: ${AWS_REGION:-Not set}"
  echo "RDS Host: ${MFA_RDS_HOST:-Not set}"
  echo "RDS Remote Port: ${MFA_RDS_REMOTE_PORT}"
  echo "RDS Local Port: ${MFA_RDS_LOCAL_PORT}"
  echo "Bastion Instance ID: ${MFA_BASTION_INSTANCE_ID:-Not set}"
  echo "Bastion Tag: ${MFA_BASTION_TAG_KEY:-Name}=${MFA_BASTION_TAG_VALUE:-bastion}"
  if [[ ${#MFA_RDS_ENVIRONMENTS[@]} -gt 0 ]] 2>/dev/null; then
    local _env="${MFA_RDS_ENV:-${MFA_RDS_DEFAULT_ENV:-(none)}}"
    echo "MFA RDS Selected Env: ${_env}"
    echo "MFA RDS Environments:"
    printf '%s\n' "${MFA_RDS_ENVIRONMENTS[@]}" | sed 's/^/  - /'
  fi
}

mfa_show_help() {
  cat << 'EOF'

AWS Helper Tools (MFA) - Help
=============================

Commands (after sourcing this file):
  mfa_session                     - Get MFA session and export to env
  mfa_subshell                    - Get MFA session and open subshell
  mfa_ec2_connect [instance-id]   - Connect to EC2 via SSM
  mfa_ec2_connect_by_name         - List by Name and connect via SSM
  mfa_ssm_doctor [instance-id]    - Diagnose SSM readiness for an instance
  mfa_session_status              - Show current MFA session status
  mfa_session_alive               - Exit code 0 if session is active
  mfa_rds_forward [instance-id] [rds-host] [remote-port] [local-port]
                                  - Port forward to RDS via SSM
  mfa_menu                        - Interactive menu

Environment requirements:
  Use mfa_session to obtain MFA session credentials first.

Aliases:
  awsh-mfa (menu), ec2-mfa, ec2n-mfa, rds-mfa, mfa-status

EOF
}

mfa_choose_from_list() {
  local title="$1"; shift
  local items=("$@")
  if (( ${#items[@]} == 0 )); then return 1; fi
  if command -v peco >/dev/null 2>&1; then
    printf '%s\n' "${items[@]}" | peco --prompt "$title"
  else
    printf '%s\n' "${items[@]}" | nl -ba
    local idx; _mfa_prompt idx "$title [1-${#items[@]}]: "
    if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx>=1 && idx<=${#items[@]} )); then
      echo "${items[idx-1]}"
    fi
  fi
}

# Interactive MFA session (exports creds to current shell)
mfa_session() {
  local profile="${1-}"
  # Interactive profile selection if none passed
  if [[ -z "$profile" ]]; then
    local profiles_list
    profiles_list=$(aws configure list-profiles 2>/dev/null || true)
    if [[ -n "$profiles_list" ]]; then
      local original_profiles="$profiles_list"
      if [[ "${MFA_SESSION_INCLUDE_SSO_PROFILES:-0}" != "1" ]]; then
        local sso_profiles credential_profiles
        sso_profiles=$(_mfa_list_sso_profiles 2>/dev/null || true)
        credential_profiles=$(_mfa_list_credential_profiles 2>/dev/null || true)
        if [[ -n "$sso_profiles" ]]; then
          local sso_only filtered
          if [[ -n "$credential_profiles" ]]; then
            sso_only=$(printf '%s\n' "$sso_profiles" | grep -vxFf <(printf '%s\n' "$credential_profiles"))
          else
            sso_only="$sso_profiles"
          fi
          if [[ -n "$sso_only" ]]; then
            filtered=$(printf '%s\n' "$profiles_list" | grep -vxFf <(printf '%s\n' "$sso_only"))
          else
            filtered="$profiles_list"
          fi
          if [[ -n "$filtered" ]]; then
            profiles_list="$filtered"
          else
            profiles_list="$original_profiles"
            _mfa_log info "SSO-only profiles are hidden by default. Set MFA_SESSION_INCLUDE_SSO_PROFILES=1 to include them."
          fi
        fi
      fi
      if [[ -n "$profiles_list" ]]; then
        local chosen
        chosen=$(mfa_choose_from_list "Select source profile (Enter for env)" $(echo "$profiles_list"))
        if [[ -n "$chosen" ]]; then profile="$chosen"; fi
      fi
    fi
  fi
  local use_profile_args=()
  if [[ -n "$profile" ]]; then use_profile_args=(--profile "$profile"); fi

  _mfa_log info "Preparing to generate MFA session credentials"
  if [[ -n "$profile" ]]; then
    _mfa_log info "Source profile: $profile"
  else
    _mfa_log info "Source: current environment credentials"
  fi

  # Resolve IAM user for this profile/env
  local user_name="" account_id="" caller_arn=""
  caller_arn=$(aws sts get-caller-identity "${use_profile_args[@]}" --query Arn --output text 2>/dev/null || true)
  # If profile explicitly defines mfa_serial, trust and use it
  local serial=""
  if [[ -n "$profile" ]]; then
    serial=$(aws configure get mfa_serial --profile "$profile" 2>/dev/null || true)
    if [[ -n "$serial" ]]; then
      _mfa_log info "Using profile mfa_serial: $serial"
    fi
  fi

  if [[ -n "$serial" ]]; then
    # Skip user/device discovery when mfa_serial is provided
    :
  else
    # Prefer IAM get-user to obtain the actual username; this fails under assumed-role/SSO
    user_name=$(aws iam get-user "${use_profile_args[@]}" --query 'User.UserName' --output text 2>/dev/null || true)
    if [[ -z "$user_name" ]] && [[ "$caller_arn" =~ ^arn:aws:iam::([0-9]{12}):user\/(.+)$ ]]; then
      account_id="${BASH_REMATCH[1]}"
      user_name="${BASH_REMATCH[2]}"; user_name="${user_name##*/}"
    fi
    if [[ -z "$user_name" ]]; then
      _mfa_log error "The selected profile is not an IAM user (likely a role/SSO). Select a user profile with static keys."
      return 1
    fi

    # List MFA devices for that IAM user (must be registered)
    local serials=()
    local tmp_serials; tmp_serials=$(mktemp)
    aws iam list-mfa-devices "${use_profile_args[@]}" --user-name "$user_name" \
      --query 'MFADevices[].SerialNumber' --output text \
      > "$tmp_serials" 2>/dev/null || true
    while IFS=$'\n' read -r srl; do [[ -n "$srl" ]] && serials+=("$srl"); done < "$tmp_serials"
    rm -f "$tmp_serials" 2>/dev/null || true

    if (( ${#serials[@]} == 0 )); then
      _mfa_log error "Could not discover MFA device for IAM user '$user_name'."
      _mfa_log info  "Tip: Set 'mfa_serial' in ~/.aws/config under [profile $profile] to skip discovery."
      return 1
    elif (( ${#serials[@]} == 1 )); then
      serial="${serials[0]}"
      _mfa_log info "Using MFA device: $serial"
    else
      serial=$(mfa_choose_from_list "Select MFA device:" "${serials[@]}")
      serial=${serial:-${serials[0]}}; _mfa_log info "Using MFA device: $serial"
    fi
  fi

  local token duration tmp_creds tmp_err AK SK ST EXP
  # Default session duration: 8 hours (28800s)
  duration=${AWS_MFA_DURATION:-28800}
  tmp_creds=$(mktemp); tmp_err=$(mktemp)
  local last_token=""
  while :; do
    _mfa_prompt token "MFA token code (6 digits, Enter to cancel): "
    if [[ -z "$token" ]]; then
      _mfa_log warning "MFA input cancelled by user."
      rm -f "$tmp_creds" "$tmp_err" 2>/dev/null || true
      return 1
    fi
    if [[ "$token" == "$last_token" ]]; then
      _mfa_log warning "Same code re-entered; wait for next code and try again."
    fi
    if aws sts get-session-token "${use_profile_args[@]}" \
        --serial-number "$serial" --token-code "$token" --duration-seconds "$duration" \
        --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken,Expiration]' --output text \
        > "$tmp_creds" 2>"$tmp_err"; then
      break
    fi
    if grep -qi "invalid MFA one time pass code" "$tmp_err" 2>/dev/null; then
      _mfa_log warning "Invalid MFA code. Wait for the next code and re-enter."
      last_token="$token"
      continue
    else
      _mfa_log error "Failed to obtain temporary credentials"
      [[ -s "$tmp_err" ]] && sed 's/^/  /' "$tmp_err" >&2
      rm -f "$tmp_creds" "$tmp_err" 2>/dev/null || true
      return 1
    fi
  done
  read -r AK SK ST EXP < "$tmp_creds"; rm -f "$tmp_creds" "$tmp_err" 2>/dev/null || true
  if [[ -z "$AK" || -z "$SK" || -z "$ST" ]]; then
    _mfa_log error "Could not parse temporary credentials"; return 1
  fi
  export AWS_ACCESS_KEY_ID="$AK" AWS_SECRET_ACCESS_KEY="$SK" AWS_SESSION_TOKEN="$ST" AWS_MFA_EXPIRATION="$EXP"
  _mfa_log success "MFA session exported (expires: $EXP)"
}

# Open a subshell with MFA credentials (optional)
mfa_subshell() {
  local profile="${1-}"
  if mfa_session "$profile"; then
    _mfa_log info "Spawning subshell. Type 'exit' to leave."
    export PS1="[AWS-MFA] ${PS1}"
    exec "${SHELL:-/bin/bash}"
  fi
}

mfa_menu() {
  if ! _mfa_check_dependencies; then return 1; fi
  echo
  while true; do
    _mfa_log info "$MFA_SCRIPT_NAME v$MFA_VERSION"; echo "==============================="
    local options=(
      "🔒 Create MFA session (env)"
      "🗄️  RDS port forwarding (MFA env)"
      "🧭 Connect to EC2 by Name"
      "🔎 Check MFA session status"
      "📋 Show current configuration"
      "❓ Show help"
      "🚪 Exit"
    )
    local selected
    if command -v peco >/dev/null 2>&1; then
      selected=$(printf '%s\n' "${options[@]}" | peco --prompt "Select action:")
    else
      printf '%s\n' "${options[@]}" | nl -ba
      local idx; _mfa_prompt idx "Choose number: "; selected=$(printf '%s\n' "${options[@]}" | sed -n "${idx}p")
    fi
    case "$selected" in
      "🔒 Create MFA session (env)")       mfa_session ;;
      "🗄️  RDS port forwarding (MFA env)") _mfa_ensure_session && mfa_rds_forward ;;
      "🧭 Connect to EC2 by Name")        _mfa_ensure_session && mfa_ec2_connect_by_name ;;
      "🔎 Check MFA session status")      mfa_session_status ;;
      "📋 Show current configuration")    mfa_show_config ;;
      "❓ Show help")                      mfa_show_help ;;
      "🚪 Exit"|"")                        _mfa_log info "Goodbye!"; break ;;
      *) _mfa_log warning "Invalid selection" ;;
    esac
    echo; local _enter; _mfa_prompt _enter "Press Enter to continue..."
  done
}

# Aliases for convenience (when sourced)
alias awsh-mfa='mfa_menu'
alias ec2-mfa='mfa_ec2_connect'
alias ec2n-mfa='mfa_ec2_connect_by_name'
alias rds-mfa='mfa_rds_forward'
alias mfa-status='mfa_session_status'

# Init if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  _mfa_check_dependencies || exit 1
  _mfa_set_defaults
  mfa_menu
fi

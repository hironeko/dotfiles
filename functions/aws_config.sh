#!/bin/bash
# AWS Helper Tools Configuration Template
# Copy this file to ~/.aws-helper-config.sh and customize

# =============================================================================
# AWS General Settings
# =============================================================================

# Default AWS region - change to your preferred region
AWS_REGION="ap-northeast-1"

# =============================================================================
# EC2 Settings
# =============================================================================

# EC2 instance filters for quick selection
# Add your commonly used instance name patterns here
# The first item should always be "すべて表示" for showing all instances
EC2_FILTERS=(
    "すべて表示"
    "web"
    "api"
    "app"
    "bastion"
    "database"
    "worker"
    "staging"
    "production"
    # Add your custom filters here
    # Examples:
    # "my-app-prod"
    # "my-app-stg"
    # "jenkins"
    # "monitoring"
)

# =============================================================================
# ECS Settings
# =============================================================================

# ECS cluster configuration
ECS_CLUSTER_NAME="my-cluster"
ECS_SERVICE_NAME="my-service"
ECS_CONTAINER_NAME="app"

# Default command to execute in ECS containers
# Use "/bin/bash" for most containers, "/bin/sh" for alpine-based
ECS_COMMAND="/bin/bash"

# =============================================================================
# RDS Settings
# =============================================================================

# RDS environment configurations for port forwarding
# Format: "ENV_NAME:HOSTNAME:REMOTE_PORT:LOCAL_PORT"
# 
# ENV_NAME: Environment identifier (DEV, STG, PRD, etc.)
# HOSTNAME: RDS endpoint hostname
# REMOTE_PORT: Port on the RDS instance (usually 3306 for MySQL, 5432 for PostgreSQL)
# LOCAL_PORT: Local port to forward to (choose unused ports)
RDS_ENVIRONMENTS=(
    "DEV:dev-db.cluster-xxx.region.rds.amazonaws.com:3306:13306"
    "STG:stg-db.cluster-xxx.region.rds.amazonaws.com:3306:13307"
    "PRD:prod-db.cluster-xxx.region.rds.amazonaws.com:3306:13308"
    # PostgreSQL example:
    # "DEV-PG:dev-postgres.cluster-xxx.region.rds.amazonaws.com:5432:15432"
    # Add more environments as needed
)

# =============================================================================
# Bastion Server Settings
# =============================================================================

# Tag name used to identify bastion/jump servers
# This should match the "Name" tag of your bastion instances
BASTION_TAG_NAME="bastion"

# =============================================================================
# Advanced Settings (Optional)
# =============================================================================

# Default SSH user for EC2 instances (not used in SSM sessions)
DEFAULT_SSH_USER="ec2-user"

# Custom SSM document name (usually not needed)
SSM_DOCUMENT_NAME="AWS-StartInteractiveCommand"

# Custom SSM parameters (usually not needed)
SSM_PARAMETERS='{"command":["bash"]}'

# Enable verbose logging for debugging
ENABLE_VERBOSE_LOGGING=false

# Custom AWS CLI profile to use by default (optional)
# DEFAULT_AWS_PROFILE="my-default-profile"

# =============================================================================
# Environment-Specific Examples
# =============================================================================

# Example for multiple environments with different settings:
#
# Development Environment:
# EC2_FILTERS_DEV=("すべて表示" "dev-web" "dev-api" "dev-worker")
# RDS_ENVIRONMENTS_DEV=("DEV:dev-db:3306:13306")
#
# Production Environment:
# EC2_FILTERS_PROD=("すべて表示" "prod-web" "prod-api" "prod-worker")
# RDS_ENVIRONMENTS_PROD=("PRD:prod-db:3306:13308")

# =============================================================================
# Custom Functions (Optional)
# =============================================================================

# You can define custom functions here that will be available
# after the configuration is loaded

# Example: Custom function to connect to a specific environment
# connect_to_prod() {
#     ec2_connect "prod-profile" "$(select_ec2 "prod-profile" "prod-web")"
# }

# Example: Quick RDS connection to staging
# rds_staging() {
#     rds_forward "staging-profile" "" "STG"
# }

# =============================================================================
# Configuration Validation (Optional)
# =============================================================================

# Uncomment and customize this function to validate your configuration
# validate_custom_config() {
#     if [[ -z "$AWS_REGION" ]]; then
#         echo "Error: AWS_REGION is not set" >&2
#         return 1
#     fi
#     
#     if [[ ${#EC2_FILTERS[@]} -eq 0 ]]; then
#         echo "Error: EC2_FILTERS is empty" >&2
#         return 1
#     fi
#     
#     return 0
# }

# Call validation function if defined
# if declare -f validate_custom_config >/dev/null; then
#     validate_custom_config
# fi
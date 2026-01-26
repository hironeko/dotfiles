#!/bin/bash
# MFA-specific configuration for AWS Helper Tools (MFA Edition)
# Copy to ~/.aws-mfa-config.sh and customize for your environment.

# Format: "ENV:HOSTNAME:REMOTE_PORT:LOCAL_PORT"
# - ENV: Logical environment name (e.g., STG, PRD)
# - HOSTNAME: RDS endpoint (FQDN)
# - REMOTE_PORT: RDS port (e.g., 3306 for MySQL, 5432 for PostgreSQL)
# - LOCAL_PORT: Local forward port to use
MFA_RDS_ENVIRONMENTS=(
  "STG:stg-db.cluster-xxx.ap-northeast-1.rds.amazonaws.com:3306:3308"
  "PRD:prod-db.cluster-xxx.ap-northeast-1.rds.amazonaws.com:3306:3307"
)

# Default environment when running MFA RDS commands (can be overridden by MFA_RDS_ENV)
MFA_RDS_DEFAULT_ENV="STG"

# Optional: DB instance identifiers per environment (not required for port-forwarding)
# Format: "ENV:DB_INSTANCE_IDENTIFIER"
MFA_RDS_INSTANCE_IDS=(
  "STG:i-xxxxxxxxxxxxxxxxx"
  "PRD:i-xxxxxxxxxxxxxxxxx"
)

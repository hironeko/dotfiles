#!/bin/bash

set -e

source "$(dirname "$0")/common.sh"

echo_step "Installing Herdr..."

# Check if Herdr is already installed
if command -v herdr &> /dev/null; then
    echo_success "Herdr is already installed"
else
    echo_info "Downloading and installing Herdr..."
    curl -fsSL https://herdr.dev/install.sh | sh

    if command -v herdr &> /dev/null; then
        echo_success "Herdr installed successfully"
    else
        echo_error "Failed to install Herdr"
        exit 1
    fi
fi

echo_success "Herdr setup complete"

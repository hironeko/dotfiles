#!/bin/zsh
# Git Worktree Tools for Zsh
# Enhanced Git worktree management with peco integration
# Author: Enhanced version
# License: MIT

# =============================================================================
# Configuration
# =============================================================================

# Project directories for multi-project navigation
export PROJECT_DIRS=(
    ~/projects
    ~/work
    ~/personal
    ~/dev
)

# Default branch types for new worktrees
readonly BRANCH_TYPES=("feature" "hotfix" "bugfix" "release" "experiment" "task" "issue" "story" "epic")


# =============================================================================
# Utility Functions
# =============================================================================

_gwt_log() {
    local level=$1
    shift
    local message="$*"
    
    case $level in
        success) echo -e "${COLOR_SUCCESS}✓${COLOR_RESET} $message" ;;
        warning) echo -e "${COLOR_WARNING}⚠️${COLOR_RESET} $message" ;;
        error) echo -e "${COLOR_ERROR}❌${COLOR_RESET} $message" ;;
        info) echo -e "${COLOR_INFO}ℹ️${COLOR_RESET} $message" ;;
        *) echo "$message" ;;
    esac
}

_gwt_is_git_repo() {
    git rev-parse --git-dir > /dev/null 2>&1
}

_gwt_get_current_branch() {
    git branch --show-current 2>/dev/null
}

_gwt_validate_branch_name() {
    local branch_name=$1
    if [[ ! "$branch_name" =~ ^[a-zA-Z0-9/_-]+$ ]]; then
        _gwt_log error "Invalid branch name. Use alphanumeric characters, hyphens, underscores, and slashes only."
        return 1
    fi
    return 0
}

# =============================================================================
# Core Worktree Functions
# =============================================================================

# Navigate between worktrees
gwtg() {
    if ! _gwt_is_git_repo; then
        _gwt_log error "Not in a git repository"
        return 1
    fi

    local selected
    selected=$(git worktree list | peco --prompt "Select worktree> " | awk '{print $1}')
    
    if [[ -n "$selected" ]]; then
        _gwt_log info "Moving to: $selected"
        cd "$selected" || return 1
        _gwt_show_current_info
    fi
}

# Create worktree from remote branch
gwt-remote() {
    if ! _gwt_is_git_repo; then
        _gwt_log error "Not in a git repository"
        return 1
    fi

    _gwt_log info "Fetching remote branches..."
    git fetch --all --prune

    local selected
    selected=$(git branch -r | grep -v HEAD | sed 's/origin\///' | sed 's/^[[:space:]]*//' | peco --prompt "Select remote branch> ")
    
    if [[ -n "$selected" ]]; then
        local dir_name="../${selected//\//-}"
        _gwt_log info "Creating worktree: $dir_name from origin/$selected"
        
        if git worktree add -b "$selected" "$dir_name" "origin/$selected"; then
            _gwt_log success "Created worktree successfully"
            cd "$dir_name" || return 1
            _gwt_setup_worktree
        else
            _gwt_log error "Failed to create worktree"
            return 1
        fi
    fi
}

# Create worktree from local branch
gwt-local() {
    if ! _gwt_is_git_repo; then
        _gwt_log error "Not in a git repository"
        return 1
    fi

    local selected
    selected=$(git branch | grep -v '^\*' | sed 's/^[[:space:]]*//' | peco --prompt "Select local branch> ")
    
    if [[ -n "$selected" ]]; then
        local dir_name="../${selected//\//-}"
        _gwt_log info "Creating worktree: $dir_name"
        
        if git worktree add "$dir_name" "$selected"; then
            _gwt_log success "Created worktree successfully"
            cd "$dir_name" || return 1
            _gwt_setup_worktree
        else
            _gwt_log error "Failed to create worktree"
            return 1
        fi
    fi
}

# Remove worktree with safety checks
gwt-remove() {
    if ! _gwt_is_git_repo; then
        _gwt_log error "Not in a git repository"
        return 1
    fi

    local selected
    selected=$(git worktree list | peco --prompt "Select worktree to remove> " | awk '{print $1}')
    
    if [[ -n "$selected" ]]; then
        # Safety check: prevent removing current worktree
        if [[ "$selected" == "$(pwd)" ]]; then
            _gwt_log warning "Cannot remove current worktree. Please move to another directory first."
            return 1
        fi
        
        local branch_name
        branch_name=$(git worktree list | grep "$selected" | awk '{print $3}' | tr -d '[]')
        
        echo "Worktree: $selected"
        echo "Branch: $branch_name"
        
        if read -q "?Remove this worktree? (y/N): "; then
            echo
            if git worktree remove "$selected"; then
                _gwt_log success "Removed worktree: $selected"
                
                # Ask about branch deletion
                if read -q "?Also delete the branch '$branch_name'? (y/N): "; then
                    echo
                    if git branch -D "$branch_name" 2>/dev/null; then
                        _gwt_log success "Deleted branch: $branch_name"
                    else
                        _gwt_log warning "Could not delete branch (may not exist locally)"
                    fi
                else
                    echo
                fi
            else
                _gwt_log error "Failed to remove worktree"
            fi
        else
            echo
            _gwt_log info "Operation cancelled"
        fi
    fi
}

# Create new worktree with interactive wizard
gwt-new() {
    if ! _gwt_is_git_repo; then
        _gwt_log error "Not in a git repository"
        return 1
    fi

    # Select branch type
    local selected_type
    selected_type=$(printf '%s\n' "${BRANCH_TYPES[@]}" | peco --prompt "Select branch type> ")
    
    if [[ -z "$selected_type" ]]; then
        _gwt_log info "Operation cancelled"
        return 0
    fi
    
    # Get branch name
    local branch_name
    vared -p "Enter branch name (without $selected_type/ prefix): " branch_name
    
    if [[ -z "$branch_name" ]]; then
        _gwt_log info "Operation cancelled"
        return 0
    fi
    
    if ! _gwt_validate_branch_name "$branch_name"; then
        return 1
    fi
    
    # Fetch latest remote info
    _gwt_log info "Fetching remote branches..."
    git fetch --all --prune
    
    # Select base branch
    local base_branch
    local branch_list
    branch_list=$(
        {
            git branch | grep -v '^\*' | sed 's/^[[:space:]]*//'
            git branch -r | grep -v HEAD | sed 's/^[[:space:]]*//'
        } | sort -u
    )
    
    base_branch=$(echo "$branch_list" | peco --prompt "Select base branch> ")
    
    if [[ -z "$base_branch" ]]; then
        _gwt_log info "Operation cancelled"
        return 0
    fi
    
    local full_branch_name="$selected_type/$branch_name"
    local dir_name="../$selected_type-$branch_name"
    
    # Handle base branch reference
    local base_ref="$base_branch"
    if [[ ! "$base_branch" =~ ^origin/ ]] && git show-ref --verify --quiet "refs/remotes/origin/$base_branch"; then
        base_ref="origin/$base_branch"
    fi
    
    _gwt_log info "Creating: $full_branch_name from $base_ref"
    
    if git worktree add -b "$full_branch_name" "$dir_name" "$base_ref"; then
        _gwt_log success "Created worktree successfully"
        cd "$dir_name" || return 1
        _gwt_setup_worktree
    else
        _gwt_log error "Failed to create worktree"
        return 1
    fi
}

# =============================================================================
# Project Navigation
# =============================================================================

# Navigate between different projects
proj() {
    local selected
    selected=$(find "${PROJECT_DIRS[@]}" -maxdepth 2 -type d -name .git 2>/dev/null | \
               xargs -I {} dirname {} | \
               sort -u | \
               peco --prompt "Select project/repository> ")
    
    if [[ -n "$selected" ]]; then
        _gwt_log info "Moving to project: $selected"
        cd "$selected" || return 1
        _gwt_show_current_info
    fi
}

# =============================================================================
# Status and Information
# =============================================================================

# Show detailed worktree status
gwt-status() {
    if ! _gwt_is_git_repo; then
        _gwt_log error "Not in a git repository"
        return 1
    fi

    echo "=== Worktree Status ==="
    git worktree list | while IFS= read -r line; do
        local dir branch commit status_info
        dir=$(echo "$line" | awk '{print $1}')
        commit=$(echo "$line" | awk '{print $2}')
        branch=$(echo "$line" | awk '{print $3}' | tr -d '[]')
        
        echo "📁 $dir"
        echo "   ├─ Branch: $branch"
        echo "   ├─ Commit: $commit"
        
        # Check for uncommitted changes
        if [[ -d "$dir" ]]; then
            local changes
            pushd "$dir" > /dev/null || continue
            changes=$(git status --porcelain | wc -l | tr -d ' ')
            if [[ "$changes" -gt 0 ]]; then
                echo "   └─ ⚠️  Uncommitted changes: $changes files"
            else
                echo "   └─ ✓ Clean working directory"
            fi
            popd > /dev/null || continue
        fi
        echo
    done
}

# Simple worktree list
gwtl() {
    if ! _gwt_is_git_repo; then
        _gwt_log error "Not in a git repository"
        return 1
    fi

    echo "=== Git Worktrees ==="
    git worktree list | while IFS= read -r line; do
        local dir branch
        dir=$(echo "$line" | awk '{print $1}')
        branch=$(echo "$line" | awk '{print $3}' | tr -d '[]')
        echo "📁 $dir → $branch"
    done
}

# Show current worktree info
_gwt_show_current_info() {
    if _gwt_is_git_repo; then
        local current_branch
        current_branch=$(_gwt_get_current_branch)
        if [[ -f .git ]]; then
            _gwt_log info "Worktree: $current_branch"
        else
            _gwt_log info "Main repository: $current_branch"
        fi
    fi
}

# =============================================================================
# Husky Integration
# =============================================================================

# Fix Husky in current worktree
fix-husky() {
    _gwt_log info "Fixing Husky in current worktree..."
    
    if [[ ! -f "package.json" ]]; then
        _gwt_log warning "No package.json found"
        return 1
    fi
    
    if ! grep -q "husky" "package.json"; then
        _gwt_log warning "Husky not found in package.json"
        return 1
    fi
    
    if [[ ! -d "node_modules" ]]; then
        _gwt_log info "Installing dependencies..."
        npm install || return 1
    fi
    
    if npx husky install; then
        _gwt_log success "Husky fixed for this worktree"
    else
        _gwt_log error "Failed to install Husky"
        return 1
    fi
}

# Check Husky status
check-husky() {
    _gwt_log info "Checking Husky status..."
    
    if [[ -f .git ]]; then
        echo "📄 .git is a file (worktree)"
        local gitdir
        gitdir=$(cat .git | sed 's/gitdir: //')
        echo "   Points to: $gitdir"
        
        if [[ -d "$gitdir/hooks" ]]; then
            _gwt_log success "Hooks directory exists"
            ls -la "$gitdir/hooks" | grep -E "(pre-commit|commit-msg|pre-push)" || echo "   No Git hooks found"
        else
            _gwt_log warning "Hooks directory not found"
        fi
    fi
    
    if [[ -d .husky ]]; then
        _gwt_log success ".husky directory exists"
        ls -la .husky/ | head -10
    else
        _gwt_log info "No .husky directory found"
    fi
    
    local hooks_path
    hooks_path=$(git config core.hooksPath)
    if [[ -n "$hooks_path" ]]; then
        echo "ℹ️  core.hooksPath: $hooks_path"
    fi
}

# Setup worktree (called after creation)
_gwt_setup_worktree() {
    # Set case sensitivity for better cross-platform compatibility
    git config core.ignorecase false
    
    # Setup Husky if needed
    if [[ -f "package.json" ]] && grep -q "husky" "package.json"; then
        if read -q "?Setup Husky for this worktree? (Y/n): "; then
            echo
            fix-husky
        else
            echo
        fi
    fi
    
    _gwt_show_current_info
}

# =============================================================================
# Quick Creation Functions
# =============================================================================

# Quick worktree creation
gwt() {
    local branch_name=$1
    local base_branch=${2:-main}
    
    if [[ -z "$branch_name" ]]; then
        _gwt_log error "Usage: gwt <branch_name> [base_branch]"
        return 1
    fi
    
    if ! _gwt_validate_branch_name "$branch_name"; then
        return 1
    fi
    
    local dir_name="../${branch_name//\//-}"
    
    _gwt_log info "Creating worktree: $dir_name"
    
    if git worktree add -b "$branch_name" "$dir_name" "$base_branch"; then
        _gwt_log success "Created worktree successfully"
        cd "$dir_name" || return 1
        _gwt_setup_worktree
    else
        _gwt_log error "Failed to create worktree"
        return 1
    fi
}

# Shortcut functions for common branch types
gwt-feature() { gwt "feature/$1" "${2:-develop}" }
gwt-hotfix() { gwt "hotfix/$1" "${2:-main}" }
gwt-bugfix() { gwt "bugfix/$1" "${2:-develop}" }
gwt-task() { gwt "task/$1" "${2:-main}" }

# =============================================================================
# Interactive Menu
# =============================================================================

gwt-menu() {
    if ! _gwt_is_git_repo; then
        _gwt_log error "Not in a git repository"
        return 1
    fi

    local actions=(
        "🚀 Go to worktree"
        "📁 Create from local branch"
        "🌐 Create from remote branch"
        "✨ Create new worktree (wizard)"
        "🗑️  Remove worktree"
        "📋 List worktrees"
        "📊 Show detailed status"
        "🔧 Fix Husky"
        "🔍 Check Husky status"
        "📚 Show help"
    )
    
    local selected
    selected=$(printf '%s\n' "${actions[@]}" | peco --prompt "Worktree action> ")
    
    case "$selected" in
        "🚀 Go to worktree") gwtg ;;
        "📁 Create from local branch") gwt-local ;;
        "🌐 Create from remote branch") gwt-remote ;;
        "✨ Create new worktree (wizard)") gwt-new ;;
        "🗑️  Remove worktree") gwt-remove ;;
        "📋 List worktrees") gwtl ;;
        "📊 Show detailed status") gwt-status ;;
        "🔧 Fix Husky") fix-husky ;;
        "🔍 Check Husky status") check-husky ;;
        "📚 Show help") gwt-help ;;
    esac
}

# =============================================================================
# Zsh Integration
# =============================================================================

# Ctrl+G for quick worktree switching
peco-worktree() {
    if ! _gwt_is_git_repo; then
        zle clear-screen
        return
    fi

    local selected
    selected=$(git worktree list 2>/dev/null | peco | awk '{print $1}')
    if [[ -n "$selected" ]]; then
        cd "$selected" || return
        zle accept-line
    fi
    zle clear-screen
}
zle -N peco-worktree
bindkey '^G' peco-worktree

# Auto-display info when changing directories
chpwd() {
    if _gwt_is_git_repo; then
        _gwt_show_current_info
    fi
}

# =============================================================================
# Help and Documentation
# =============================================================================

gwt-help() {
    cat << 'EOF'
📚 Git Worktree Tools - Command Reference
==========================================

🔄 Worktree Navigation:
  w, gwtg          Move between worktrees (interactive)
  proj             Switch between different projects/repositories

✨ Create Worktree:
  wn, gwt-new      Create new worktree (interactive wizard)
  gwt-local        Create from existing local branch
  gwt-remote       Create from remote branch
  gwt <name> [base] Quick create (e.g., gwt feature/auth main)

🗑️  Remove Worktree:
  wr, gwt-remove   Remove worktree (interactive, with safety checks)

📊 Status & Info:
  ws, gwt-status   Show detailed worktree status
  wl, gwtl         List all worktrees (simple)
  ch, check-husky  Check Husky hooks status

🔧 Utilities:
  wm, gwt-menu     Open interactive menu (all features)
  fh, fix-husky    Fix Husky in current worktree
  wh, gwt-help     Show this help message

⚡ Quick Create Shortcuts:
  gwt-feature <name> [base]  Create feature/name branch
  gwt-hotfix <name> [base]   Create hotfix/name branch
  gwt-bugfix <name> [base]   Create bugfix/name branch
  gwt-task <name> [base]     Create task/name branch

⌨️  Keyboard Shortcuts:
  Ctrl+G           Quick worktree switch (in terminal)

💡 Examples:
  wn                        # Interactive create wizard
  gwt-feature auth          # Create feature/auth from develop
  gwt task/KR-123 main      # Create task/KR-123 from main
  proj                      # Switch to different project
  w                         # Quick worktree navigation

📋 Configuration:
  Edit PROJECT_DIRS array to add your project directories
  Default branch types: feature, hotfix, bugfix, release, experiment, task
EOF
}

# =============================================================================
# Aliases
# =============================================================================

alias w='gwtg'
alias wn='gwt-new'
alias wr='gwt-remove'
alias ws='gwt-status'
alias wl='gwtl'
alias wm='gwt-menu'
alias wh='gwt-help'
alias fh='fix-husky'
alias ch='check-husky'

# =============================================================================
# Initialization
# =============================================================================

init-git-worktree-tools() {
    _gwt_log info "Initializing Git Worktree Tools for Zsh..."
    
    # Create peco config directory
    mkdir -p ~/.config/peco
    
    if [[ ! -f ~/.config/peco/config.json ]]; then
        cat > ~/.config/peco/config.json << 'EOF'
{
  "Style": {
    "Basic": ["on_default", "default"],
    "SavedSelection": ["bold", "on_yellow", "white"],
    "Selected": ["underline", "on_cyan", "black"],
    "Query": ["yellow", "bold"],
    "Matched": ["red", "on_blue"]
  },
  "Prompt": "QUERY>",
  "InitialFilter": "Fuzzy"
}
EOF
        _gwt_log success "Created peco config"
    fi
    
    _gwt_log success "Initialization complete!"
    _gwt_log info "Type 'wh' for help, 'wm' for interactive menu"
}

# =============================================================================
# Load Complete
# =============================================================================

_gwt_log success "Git Worktree Tools loaded!"
_gwt_log info "Quick commands: w (move), wn (new), wr (remove), wm (menu)"
_gwt_log info "Type 'wh' for help or 'wm' for interactive menu"
#!/usr/bin/env bash
#
# Common functions shared across installation scripts
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Context tag appended to logs when set via `set_log_context`
LOG_CONTEXT=""

log_context_prefix() {
    if [[ -n "$LOG_CONTEXT" ]]; then
        echo -e " ${BLUE}[${LOG_CONTEXT}]${NC}"
    fi
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC}$(log_context_prefix) $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC}$(log_context_prefix) $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC}$(log_context_prefix) $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC}$(log_context_prefix) $1"
}

set_log_context() {
    LOG_CONTEXT="$1"
}

clear_log_context() {
    LOG_CONTEXT=""
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

die() {
    log_error "$1"
    exit 1
}

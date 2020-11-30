#!/usr/bin/env false

function log_info() {
    local message="$1"
    log "Info\t${message}" "${INFO_LOG_LEVEL}" 
}

function log_warning() {
    local message="$1"
    log "Warning\t${message}" "${WARN_LOG_LEVEL}"
}

function log_error() {
    local message="$1"
    log "Error\t${message}" "${CRITICAL_LOG_LEVEL}" 
}

function log() {
    local message="$1"
    local level="$2"
    if [[ "${level}" -le "${PICAXE_LOG_LEVEL}" ]]; then
        >&2 echo -e "${message}"
    fi
}
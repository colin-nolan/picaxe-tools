#!/usr/bin/env false

PICAXE_LOG_LEVEL="${PICAXE_LOG_LEVEL:-${INFO_LOG_LEVEL}}"

function log_info() {
    local message="$1"
    if [[ "${PICAXE_LOG_LEVEL}" -ge "${INFO_PLUS_LOG_LEVEL}" ]]; then
        >&2 echo "${message}"
    fi
}

function log_error() {
    local message="$1"
    if [[ "${PICAXE_LOG_LEVEL}" -ge "${CRITICAL_LOG_LEVEL}" ]]; then
        >&2 echo "${message}"
    fi
}

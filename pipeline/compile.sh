#!/usr/bin/env bash

set -euf -o pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

. "${script_directory}/logging.sh"
. "${script_directory}/constants.sh"

if [[ "${PICAXE_LOG_LEVEL}" -ge "${DEBUG_LOG_LEVEL}" ]]; then
    log_info "Turning on set -x (debug log level)"
    set -x
fi

picaxe_chip="$1"
code_location="$2"
syntax_only="$3"
picaxe_device="$4"
no_docker="$5"

if "${syntax_only}"; then
    syntax_flag="-s"
else
    syntax_flag=""
fi

if ! "${no_docker}"; then
    docker inspect --type=image "${COMPILER_DOCKER_IMAGE_NAME}" 2> /dev/null > /dev/null && {
        log_info "Compiler Docker image found: ${COMPILER_DOCKER_IMAGE_NAME}"
    } || {
        log_info "Image not built: ${COMPILER_DOCKER_IMAGE_NAME}"
        docker build -t "${COMPILER_DOCKER_IMAGE_NAME}" "${script_directory}/../compiler" > /dev/null
    }

    docker run --rm "${COMPILER_DOCKER_IMAGE_NAME}" which "${picaxe_chip}" > /dev/null || {
        log_error "Unknown chip (no compiler with same name): ${picaxe_chip}"
        exit "${UNKNOWN_CHIP_STATUS_CODE}"
    }

    extra_flags=""
    if ! "${syntax_only}"; then
        if [[ ! -e "${picaxe_device}" ]]; then
            log_error "Device not found: ${picaxe_device}"
            exit "${DEVICE_NOT_FOUND_STATUS_CODE}"
        fi
        extra_flags="--device "${picaxe_device}""
    fi
    prefix="docker run --rm -v "${code_location}:/code.bas:ro" ${extra_flags} "${COMPILER_DOCKER_IMAGE_NAME}""
else
    which "${picaxe_chip}" 2>&1 > /dev/null || {
        log_error "${picaxe_chip} compiler not on the path (hint: add compilers directory to your path with 'export PATH=\"\${PATH}:/directory/of/compilers\"')"
        exit "${MISSING_COMPILER_STATUS_CODE}"
    }
    prefix=""
fi

if ! "${syntax_only}"; then
    device_option="-c${picaxe_device}"
else
    device_option=""
fi
if [[ "${PICAXE_LOG_LEVEL}" -ge "${INFO_LOG_LEVEL}" ]]; then
    picaxe_tool_display=/dev/stderr
else
    picaxe_tool_display=/dev/null
fi

${prefix} "${picaxe_chip}" ${device_option} ${syntax_flag} /code.bas > "${picaxe_tool_display}" || {
    if "${syntax_only}"; then
        log_error "Syntax check failed"
        exit "${SYNTAX_CHECK_FAIL_STATUS_CODE}"
    else
        exit "${COMPILE_AND_UPLOAD_FAIL_STATUS_CODE}"
    fi
}

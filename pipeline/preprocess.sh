#!/usr/bin/env bash

set -euf -o pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

. "${script_directory}/logging.sh"
. "${script_directory}/constants.sh"

if [[ "${PICAXE_LOG_LEVEL}" -ge "${DEBUG_LOG_LEVEL}" ]]; then
    log_info "Turning on set -x (debug log level)"
    set -x
fi

code_location="$1"
no_docker="$2"

if ! "${no_docker}"; then
    docker inspect --type=image "${PREPROCESSOR_DOCKER_IMAGE_NAME}" 2> /dev/null > /dev/null && {   
        log_info "Preprocessor Docker image found: ${PREPROCESSOR_DOCKER_IMAGE_NAME}"
    } || {
        log_info "Image not built: ${PREPROCESSOR_DOCKER_IMAGE_NAME}"
        docker build -t "${PREPROCESSOR_DOCKER_IMAGE_NAME}" "${script_directory}/../preprocessor" > /dev/null
    }
    # FIXME: mount locations correctly!
    log_warning "Assuming that the code location (and all imports) are under the PWD (auto mounting not yet supported...)"
    docker run --rm -v "${PWD}:${PWD}:ro" "${PREPROCESSOR_DOCKER_IMAGE_NAME}" "${code_location}"
else
    python3 -c "import jinja2" 2> /dev/null || {
        log_error "jinja2 not installed (hint: jinja2 can be installed with 'pip install jinja2')"
        exit "${MISSING_JINJA2_STATUS_CODE}"
    }

    "${script_directory}/../preprocessor/preprocess.sh" "${code_location}"
fi

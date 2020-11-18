#!/usr/bin/env bash

set -euf -o pipefail

script_location="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

input_location="$1"
input_location="$(readlink -f "${input_location}")"

function parse_includes() {
    local input_location="$1"
    cat "${input_location}" | sed -E 's|^#INCLUDE "(.*)".*|{% include "\1" %}|g'
}

pushd "$(dirname "${input_location}")" > /dev/null
"${script_location}/jinja2_wrapper.py" <(parse_includes "${input_location}")
popd > /dev/null

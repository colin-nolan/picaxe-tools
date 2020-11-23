#!/usr/bin/env bash

set -euf -o pipefail
shopt -s expand_aliases

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

if [[ "$(uname)" == "Darwin" ]]; then
    which greadlink > /dev/null && {
		alias readlink=greadlink
	} || {
		>&2 echo "GNU utils is required on Mac"
		exit 1
	}
fi

input_location="$(readlink -f "$1")"

function parse_includes() {
    local input_location="$1"
    cat "${input_location}" | sed -E 's|^#INCLUDE "(.*)".*|{% include "\1" %}|g'
}

pushd "$(dirname "${input_location}")" > /dev/null
context="$(readlink -f "$(dirname "${input_location}")")"
"${script_directory}/jinja2-wrapper.py" <(parse_includes "${input_location}") "${context}"
popd > /dev/null

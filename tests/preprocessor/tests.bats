#!/usr/bin/env bats

set -euf -o pipefail

repository_location="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
context="${repository_location}/preprocessor"
resources_location="${BATS_TEST_DIRNAME}/resources"

function setup_file() {
    image_name="picaxe-preprocessor-test:${RANDOM}"
    export image_name
    docker build -t "${image_name}" "${context}"
}

function teardown_file() {
    docker rmi -f "${image_name}"
}

function setup() {
    temp_directory="$(mktemp -d)"
}

function teardown() {
    rm -rf "${temp_directory}"
}

function preprocess() {
    local source_location="$1"
    docker run -v "${resources_location}":/data:ro -w /data --rm "${image_name}" "${source_location}"
}

function preprocess_and_expect() {
    local source_location="$1"
    local expected_location="$2"
    run preprocess "${source_location}"
    >&2 echo "Preprocessor output: ${output}"
    [ "${status}" -eq 0 ]
    diff -B <(echo "${output}") "${resources_location}/${expected_location}"
}

# @test "processes when no directives" {
#     preprocess_and_expect no-directives.bas no-directives.bas
# }

# @test "processes Jinja2 imports" {
#     preprocess_and_expect import.bas.j2 merged-template.bas
# }

# @test "processes PICAXE imports" {
#     preprocess_and_expect import.basinc merged-template.bas
# }
@test "processes import with parent directory in path" {
    preprocess_and_expect nested/import-parent.bas.j2 merged-template.bas
}

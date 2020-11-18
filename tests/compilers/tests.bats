#!/usr/bin/env bats

set -euf -o pipefail

repository_location="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
context="${repository_location}/compilers"

function setup_file() {
    image_name="picaxe-compilers-test:${RANDOM}"
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

@test "runs help" {
    run docker run --rm "${image_name}" picaxe20m2 -h
    >&2 echo "${output}"
    [ "${status}" -eq 0 ]   
}

@test "runs syntax check (valid)" {
    echo "high C.2" > "${temp_directory}/example.bas"
    run docker run -v "${temp_directory}/example.bas":/data/example.bas --rm "${image_name}" picaxe20m2 -s /data/example.bas
    >&2 echo "${output}"
    [ "${status}" -eq 0 ]   
}

@test "runs syntax check (invalid)" {
    echo "high invalid" > "${temp_directory}/example.bas"
    run docker run -v "${temp_directory}/example.bas":/data/example.bas --rm "${image_name}" picaxe20m2 -s /data/example.bas
    >&2 echo "${output}"
    [ "${status}" -ne 0 ]   
}
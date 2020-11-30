#!/usr/bin/env bats

repository_location="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
entrypoint_script="${repository_location}/pipeline/entrypoint.sh"
resources_location="${BATS_TEST_DIRNAME}/resources"
pseudo_tools_location="${BATS_TEST_DIRNAME}/pseudo-tools"

valid_code_1_location="${resources_location}/valid-1.bas"
invalid_code_1_location="${resources_location}/invalid-1.bas"

. "$(dirname "${entrypoint_script}")/constants.sh"

function setup() {
    temp_directory="$(mktemp -d)"
    export PICAXE_CHIP=picaxe08m
    export PICAXE_LOG_LEVEL="${INFO_LOG_LEVEL}"
    export COMPILER_SPY_WRITE_LOCATION="${temp_directory}/compiler-spy"
    export entered_python_env=false
}

function teardown() {
    if "${entered_python_env}"; then
        deactivate
    fi
    rm -rf "${temp_directory}"
}

function run_entrypoint() {
    run "${entrypoint_script}" $@
    >&2 echo "Status code: ${status}"
    >&2 echo "Output (between |bars|): |${output}|"
}

function setup_env_with_jinja2() {
    python3 -m venv "${temp_directory}/venv"
    . "${temp_directory}/venv/bin/activate"
    pip install jinja2
    entered_python_env=true
}

function setup_env_with_picaxe_tools() {
    export PATH="${PATH}:${pseudo_tools_location}"
}


##################################################
# Happy path
##################################################
@test "help available with -h" {
    run_entrypoint -h
    [ "${status}" -eq 0 ]
}

@test "help available with --help" {
    run_entrypoint --help
    [ "${status}" -eq 0 ]
}

@test "syntax check with valid input" {
    run_entrypoint -s "${valid_code_1_location}"
    [ "${status}" -eq 0 ]
}

@test "syntax check with valid input without Docker" {
    setup_env_with_jinja2
    setup_env_with_picaxe_tools
    run_entrypoint --syntax-only -n "${valid_code_1_location}"
    [ "${status}" -eq 0 ]
}

@test "compile and upload to given device" {
    setup_env_with_jinja2
    setup_env_with_picaxe_tools
    PICAXE_LOG_LEVEL=0 run_entrypoint -n -c compiler-spy -d my-device "${valid_code_1_location}"
    [ "${status}" -eq 0 ]
    [[ "$(cat "${COMPILER_SPY_WRITE_LOCATION}")" == *"-cmy-device "* ]]
}

@test "no logs" {
    setup_env_with_jinja2
    setup_env_with_picaxe_tools
    PICAXE_LOG_LEVEL=0 run_entrypoint -s "${valid_code_1_location}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == "" ]]
}

@test "log env configuration overriden by CLI configuration" {
    setup_env_with_jinja2
    setup_env_with_picaxe_tools
    PICAXE_LOG_LEVEL=0 run_entrypoint -vvv -s "${valid_code_1_location}"
    [ "${status}" -eq 0 ]
    [[ "${output}" != "" ]]
}

@test "setting PICAXE chip with environment variable" {
    setup_env_with_jinja2
    setup_env_with_picaxe_tools
    PICAXE_CHIP=picaxe08m run_entrypoint -n "${valid_code_1_location}"
    [ "${status}" -eq 0 ]
}

@test "PICAXE chip environment configuration is overriden by CLI" {
    setup_env_with_jinja2
    setup_env_with_picaxe_tools
    PICAXE_CHIP=compiler-spy run_entrypoint -n "${valid_code_1_location}"
    [ "${status}" -eq 0 ]
    [[ "$(cat "${COMPILER_SPY_WRITE_LOCATION}")" != "" ]]
}

@test "setting PICAXE device with environment variable" {
    setup_env_with_jinja2
    setup_env_with_picaxe_tools
    PICAXE_DEVICE=/dev/1 PICAXE_CHIP=compiler-spy run_entrypoint -n "${valid_code_1_location}"
    [ "${status}" -eq 0 ]
    [[ "$(cat "${COMPILER_SPY_WRITE_LOCATION}")" == *"-c/dev/1 "* ]]
}

@test "setting PICAXE device environment configuration is overriden by CLI" {
    setup_env_with_jinja2
    setup_env_with_picaxe_tools
    PICAXE_DEVICE=/dev/1 PICAXE_CHIP=compiler-spy run_entrypoint -n -d /dev/2 "${valid_code_1_location}"
    [ "${status}" -eq 0 ]
    [[ "$(cat "${COMPILER_SPY_WRITE_LOCATION}")" == *"-c/dev/2 "* ]]
}


##################################################
# Unhappy path
##################################################
@test "syntax check with invalid input" {
    run_entrypoint -s "${invalid_code_1_location}"
    [ "${status}" -eq "${SYNTAX_CHECK_FAIL_STATUS_CODE}" ]
}

@test "PICAXE chip needs to be defined" {
    unset PICAXE_CHIP
    run_entrypoint -s "${valid_code_1_location}"
    [ "${status}" -eq "${NO_CHIP_SET_STATUS_CODE}" ]
}

@test "preprocessing with jinja2 not installed and no Docker" {
    python3 -c "import jinja2" 2> /dev/null && {
        skip "jinja2 already installed"
    }
    run_entrypoint -p -n "${valid_code_1_location}"
    [ "${status}" -eq "${MISSING_JINJA2_STATUS_CODE}" ]
}

@test "compiling with jinja2 not installed and no Docker" {
    python3 -c "import jinja2" 2> /dev/null && {
        skip "jinja2 already installed"
    }
    setup_env_with_picaxe_tools
    run_entrypoint -r -n "${valid_code_1_location}"
    [ "${status}" -eq 0 ]
}

@test "preprocessing with PICAXE tools not on path and no Docker" {
    which picaxe08m > /dev/null && {
        skip "picaxe08m already on the path"
    }
    setup_env_with_jinja2
    run_entrypoint -p -n "${valid_code_1_location}"
    [ "${status}" -eq 0 ]
}

@test "compiling with PICAXE tools not on path and no Docker" {
    which picaxe08m > /dev/null && {
        skip "picaxe08m already on the path"
    }
    setup_env_with_jinja2
    run_entrypoint --compiler-only --no-docker "${valid_code_1_location}"
    [ "${status}" -eq "${MISSING_COMPILER_STATUS_CODE}" ]
}

@test "cannot compile only and preprocess only together" {
    run_entrypoint -p -r "${valid_code_1_location}"
    [ "${status}" -eq "${CONFLICTING_ARUGMENT_STATUS_CODE}" ]
}

@test "must supply compiler with argument" {
    run_entrypoint -c -- "${valid_code_1_location}"
    [ "${status}" -eq "${INVALID_ARGUMENT_STATUS_CODE}" ]
}

@test "invalid input file" {
    run_entrypoint "${valid_code_1_location}.not"
    [ "${status}" -eq "${INPUT_NOT_FOUND_STATUS_CODE}" ]
}

@test "invalid input compiler" {
    run_entrypoint --chip picaxe999m9 "${valid_code_1_location}"
    [ "${status}" -eq "${UNKNOWN_CHIP_STATUS_CODE}" ]
}

@test "invalid device path" {
    run_entrypoint -d /dev/does-not-exist "${valid_code_1_location}"
    [ "${status}" -eq "${DEVICE_NOT_FOUND_STATUS_CODE}" ]
}

@test "non-PICAXE device" {
    run_entrypoint --device /dev/tty "${valid_code_1_location}"
    [ "${status}" -eq "${COMPILE_AND_UPLOAD_FAIL_STATUS_CODE}" ]
}

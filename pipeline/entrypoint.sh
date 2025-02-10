#!/usr/bin/env bash

set -euf -o pipefail
shopt -s expand_aliases

if [[ "$(uname)" == "Darwin" ]]; then
    which greadlink > /dev/null && {
		alias readlink=greadlink
	} || {
		>&2 echo "GNU utils is required on Mac"
        # Note: this must map to MAC_RUNTIME_STATUS_CODE (not imported at this point)
		exit 19
	}
fi

script_directory="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" > /dev/null 2>&1 && pwd)"

. "${script_directory}/constants.sh"

DEFAULT_DEVICE=/dev/ttyUSB0


function print_usage() {
>&2 cat << EOM
usage: $(basename "$0") [options] code-location

Options:
    -c, --chip string           Name of the PICAXE chip to use, e.g. "picaxe20m2" (can be set through the environment: PICAXE_CHIP=string)
    -d, --device string         Location of the device to programme if applicable (default: ${DEFAULT_DEVICE}; can be set through the environment: PICAXE_DEVICE=string)
    -h, --help                  Display this help
    -n, --no-docker             Do not use Docker, even if found on the path (requires jinja2 and PICAXE binaries on PATH instead)
    -o, --output-preprocessed   Output the preprocessed PICAXE code onto stdout
    -p, --preprocessor-only     Only run the pre-processor (do not syntax check or upload to device)
    -r, --compiler-only         Only run the compiler (syntax check + device upload) (do not run the pre-processor)
    -s, --syntax-only           Only run the compiler to check syntax (do not upload to device)
    -v[vvv]                     Set log verbosity where more "v"s will give more verbosity (default=2; can be set through the environment: PICAXE_LOG_LEVEL=int)
EOM
}


##################################################
# Logging setup
##################################################
PICAXE_LOG_LEVEL="${PICAXE_LOG_LEVEL:-${WARN_LOG_LEVEL}}"
for argument in "$@"; do
    shift
        case "${argument}" in
            "-v"*)
                non_verbosity_flag=false
                number_of_v=0
                while read -n1 character; do
                    case "${character}" in
                        "")
                            ;;
                        "v")
                            number_of_v=$((${number_of_v} + 1))
                            ;;
                        *)
                            non_verbosity_flag=true
                            ;;
                    esac
                done < <(echo -n "${argument}" | sed -E 's|^-||')

                if ! "${non_verbosity_flag}"; then
                    PICAXE_LOG_LEVEL="${number_of_v}"
                    set -- "$@"
                else
                    set -- "$@" "$argument"
                fi
                ;;
            *)
                set -- "$@" "${argument}"
                ;;
    esac
done

export PICAXE_LOG_LEVEL
. "${script_directory}/logging.sh"

if [[ "${PICAXE_LOG_LEVEL}" -ge "${DEBUG_LOG_LEVEL}" ]]; then
    log_info "Turning on set -x (debug log level)"
    set -x
fi


##################################################
# Long args handler
##################################################v
for argument in "$@"; do
    shift
        case "${argument}" in
            "--chip")
                set -- "$@" "-c"
                ;;
            "--device")
                set -- "$@" "-d"
                ;;
            "--help")
                set -- "$@" "-h"
                ;;
            "--no-docker")
                set -- "$@" "-n"
                ;;
            "--output-preprocessed")
                set -- "$@" "-o"
                ;;
            "--preprocessor-only")
                set -- "$@" "-p"
                ;;
            "--compiler-only")
                set -- "$@" "-r"
                ;;
            "--syntax-only")
                set -- "$@" "-s"
                ;;
            "--"*)
                log_error "Invalid argument: ${argument}"
                print_usage
                exit "${INVALID_ARGUMENT_STATUS_CODE}"
                ;;
            *)
                set -- "$@" "${argument}"
                ;;
    esac
done


##################################################
# Options handling
##################################################
picaxe_chip="${PICAXE_CHIP:-}"
picaxe_device="${PICAXE_DEVICE:-"${DEFAULT_DEVICE}"}"
no_docker=false
compile_only=false
preprocess_only=false
syntax_only=false
output_preprocessed=false

while getopts ":c:d:hnoprs" option; do
    case "${option}" in
        c)
            picaxe_chip="${OPTARG}"
            if [[ -n ${PICAXE_CHIP+x} && "${PICAXE_CHIP}" != "${picaxe_chip}" ]]; then
                log_info "Overriding PICAXE_CHIP configuration (${PICAXE_CHIP}) with CLI configuration (${picaxe_chip})"
            else
                log_info "Set PICAXE chip to: ${picaxe_chip}"
            fi
            ;;
        d)
            picaxe_device="${OPTARG}"
            if [[ -n ${PICAXE_DEVICE+x} && "${PICAXE_DEVICE}" != "${picaxe_device}" ]]; then
                log_info "Overriding PICAXE_DEVICE configuration (${PICAXE_DEVICE}) with CLI configuration (${picaxe_device})"
            else
                log_info "Set PICAXE device to: ${picaxe_device}"
            fi
            ;;
        h)
            print_usage
            exit 0
            ;;
        n)
            no_docker=true
            log_info "No Docker mode enabled"
            ;;
        o)
            output_preprocessed=true
            log_info "Outputting preprocessed (on /dev/stdout)"
            ;;
        p)
            preprocess_only=true
            log_info "Processing only"
            ;;
        r)
            compile_only=true
            log_info "Compiling only"
            ;;
        s)
            syntax_only=true
            log_info "Syntax check only"
            ;;
        \?)
            log_error "Invalid option: ${OPTARG}"
            print_usage
            exit "${INVALID_ARGUMENT_STATUS_CODE}"
            ;;
        :)
            log_error "Option requires an argument: ${OPTARG}"
            print_usage
            exit "${INVALID_ARGUMENT_STATUS_CODE}"
            ;;
    esac
done
shift $(expr ${OPTIND} - 1)
log_info "Picaxe chip: ${picaxe_chip}"

if "${compile_only}" && "${preprocess_only}"; then
    log_error "Cannot set compile only and preprocess only flag together"
    exit "${CONFLICTING_ARUGMENT_STATUS_CODE}"
fi
if "${preprocess_only}" && ! "${output_preprocessed}"; then
    log_warning "Pre-processing only but not outputting pre-processed code (hint: pre-processed code is output with -o)"
fi


##################################################
# Positonal argument handling
##################################################
if [[ "$#" -ne 1 ]]; then
    log_error "Expecting 1 positional argument"
    print_usage
    exit "${INVALID_ARGUMENT_STATUS_CODE}"
fi

code_location="$1"
if [[ ! -f "${code_location}" ]]; then
    log_error "File does not exist: ${code_location}"
    exit "${INPUT_NOT_FOUND_STATUS_CODE}"
fi
code_location="$(readlink -f "$1")"

if ! "${no_docker}"; then
    which docker 2> /dev/null > /dev/null && {
        log_info "docker found on path"
    } || {
        log_info "docker not on path - switching to no Docker mode"
        no_docker=true
    }
fi


##################################################
# Processing
##################################################
temp_directory="$(mktemp -d)"
trap "rm -rf '${temp_directory}'" EXIT
log_info "Using temp directory: ${temp_directory}"

if ! "${compile_only}"; then
    log_info "Pre-processing..."

    processed_code_location="${temp_directory}/processed-code.bas"
    if "${output_preprocessed}"; then
        preprocessed_display_location=/dev/stdout
    else
        preprocessed_display_location=/dev/null
    fi
    "${script_directory}/preprocess.sh" "${code_location}" "${no_docker}" \
        | tee "${processed_code_location}" \
        > "${preprocessed_display_location}"

else
    processed_code_location="${code_location}"
fi


##################################################
# Compiling
##################################################
if ! "${preprocess_only}"; then
    log_info "Compiling..."

    if [[ "${picaxe_chip}" == "" ]]; then
        log_error "No PICAXE chip set (hint: set via the -c option or use the PICAXE_CHIP environment variable)"
        exit "${NO_CHIP_SET_STATUS_CODE}"
    fi

    "${script_directory}/compile.sh" "${picaxe_chip}" "${processed_code_location}" "${syntax_only}" "${picaxe_device}" "${no_docker}"
fi

log_info "Complete!"

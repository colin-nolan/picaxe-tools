[![Build Status](https://travis-ci.com/colin-nolan/docker-picaxe.svg?token=wHcb6TtzYWvisvZKjFKh&branch=main)](https://travis-ci.com/colin-nolan/docker-picaxe)

# PICAXE Programming Tools
## Overview
- Automated Docker-based setup that allows easy, cross-platform PICAXE programming. 
- Works on Mac, Linux (not yet armhf) and Windows.
- [Jinja2](https://jinja.palletsprojects.com) for powerful, cross-platform pre-processing.
- Cross-platform support for the [`include` directive](https://picaxe.com/basic-commands/directives/hash-include/).
- Works without docker (requires `jinja2` to be installed and for the PICAXE compilers to be on the path).


## Installation
To use this software, you will need [Jinja2](https://pypi.org/project/Jinja2), [Python3](https://www.python.org/downloads/), and 
[PICAXE compilers](https://picaxe.com/software/drivers/picaxe-compilers) [on your PATH](https://linuxize.com/post/how-to-add-directory-to-path-in-linux/)
or [Docker](https://docs.docker.com/get-docker) (will build suitable images automatically).

Clone the repository:
```
git clone https://github.com/colin-nolan/docker-tools.git
```
Then call the `picaxe` executable, `./picaxe`.

For a permanent installation, you may wish to clone the repository into `/usr/local/src/docker-picaxe` and symlink 
the `picaxe` file into `/usr/local/bin`, e.g `ln -s /usr/local/src/docker-picaxe/picaxe /usr/local/bin`.


## Usage
```
usage: picaxe [options] code-location

Options:
    -c, --chip string           Name of the PICAXE chip to use, e.g. "picaxe20m2" (can be set through the environment: PICAXE_CHIP=string)
    -d, --device string         Location of the device to programme if applicable (default: /dev/ttyUSB0; can be set through the environment: PICAXE_DEVICE=string)
    -h, --help                  Display this help
    -n, --no-docker             Do not use Docker, even if found on the path (requires jinja2 and PICAXE binaries on PATH instead)
    -o, --output-preprocessed   Output the preprocessed PICAXE code onto stdout
    -p, --preprocessor-only     Only run the pre-processor (do not syntax check or upload to device)
    -r, --compiler-only         Only run the compiler (syntax check + device upload) (do not run the pre-processor)
    -s, --syntax-only           Only run the compiler to check syntax (do not upload to device)
    -v[vvv]                     Set log verbosity where more "v"s will give more verbosity (default=2; can be set through the environment: PICAXE_LOG_LEVEL=int)
```

### Examples
#### Syntax Check
Syntax check code for use with picaxe20m2 chip and output pre-processed code (usually fed into compiler):
```
./picaxe --chip picaxe20m2 --syntax-only --output-preprocessed /path/to/code.bas
```
If the syntax is
- Correct: a zero status code will be given (`$1`). Info messages can be seen with `-vvv`.
- Incorrect: a non-zero is given, along with the error message.

_Hint: the pre-processed code can be redirected to a file and used with the simulator in the [PE6 Editor](https://picaxe.com/software/picaxe/picaxe-editor-6/)._

#### Pre-process + Compile (syntax check) + Upload
It is assumed by default that connection to the PICAXE is via USB cable (device: `/dev/ttyUSB0`):
```
./picaxe -vvv --chip picaxe20m2 /path/to/code.bas
```

The usual COM1 link location is `/dev/ttyS0`:
```
./picaxe -vvv --chip picaxe20m2 --device=/dev/ttyS0 /path/to/code.bas
```


## Notes
### Motivation
[PICAXE chips](https://picaxe.com/hardware/picaxe-chips) are great devices - they are cheap, resilient, and versatile.
However, the tooling is a little disappointing, particularly outside the Windows environment. This work makes the 
compilers a little easier to use on (e.g. in a CI environment).

### Pre-Processor
For some reason, the official pre-processor is only distributed for Windows, bundled with the PE6 editor. 
However, given that most interesting directives (e.g. `#macro`) are arguably not particularly well designed, this 
work does not attempt to provide a like-for-like replacement for the originally pre-processor. Instead, it uses
the modern [Jinja2](https://jinja.palletsprojects.com) template engine, which can be used to achieve thr same results.

If you require cross-platform support of the original directives, [this effort has been made in the community](https://github.com/Patronics/PicaxePreprocess) to preprocess some of them.

### Exit Codes
The exit codes that the program gives have a meaning - see [the constants file for details](./pipeline/constants.sh). There can be useful
if used as part of a script or if logging is turned down.

### Long Format Arguments
Yes: `--chip picaxe08m2`

No: `--chip=picaxe08m2`


## Development
### Code
- Python code has been formatted using `black -l 120`.

### Tests
To run the [bats](https://github.com/bats-core/bats-core) based test suite:
```
bats --jobs "$(nproc)" -r ./tests
```
(Requires Docker and `python3 -m venv` to be available.)


## Legal
Do not distribute the PICAXE compilers (including in Docker images).

I am not affiliated to [Revolution Education Ltd](https://rev-ed.co.uk/) in any way.

This work is in no way related to the company that I work for.

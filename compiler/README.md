# Docker PICAXE Compilers
## Building
To build the image from source:
```
docker build -t colinnolan/picaxe-compiler:latest .
```

The download location of the compilers archive can be changed with `COMPILERS_LOCATION` build arg.


## Usage
The picaxe compilers (e.g. `picaxe08m2`) will be on the path of containers based on the image. These tools act 
on files so remember to mount the files you wish to compile into your container.

### Syntax Check
The PICAXE compilers can be executed in a syntax check mode, by use of the `-s` flag:
```bash
CODE_LOCATION=/my/code/main.bas
PICAXE_CHIP=picaxe20m2
docker run -v "${CODE_LOCATION}":"${CODE_LOCATION}" \
        --rm colinnolan/picaxe-compiler:latest "${PICAXE_CHIP}" -s "${CODE_LOCATION}"
```
_Note: in the example above, `CODE_LOCATION` **must** be absolute (i.e. start with `/`)._

### Programming
The PICAXE "compilers" can programme connected PICAXE chips:
```bash
CODE_LOCATION=/my/code/main.bas
PICAXE_CHIP=picaxe20m2
# DEVICE_LOCATION=/dev/ttyS0    # Usual COM1 link location
DEVICE_LOCATION=/dev/ttyusb0    # Usual USB link location
docker run -v "${CODE_LOCATION}":"${CODE_LOCATION}" \
        --device "${DEVICE_LOCATION}":"${DEVICE_LOCATION}" \
        --rm colinnolan/picaxe-compiler:latest "${PICAXE_CHIP}" -c"${DEVICE_LOCATION}" "${CODE_LOCATION}"
```
_Note: `DEVICE_LOCATION` may be different on your machine._


## Legal
If built, the Docker image will contain software that cannot be distributed (e.g on Dockerhub) without permission from the manufacturer of the
PICAXE compilers. I am not responsible for how the products of this software are used.

I am not affiliated to [Revolution Education Ltd](https://rev-ed.co.uk/) in any way.

This work is in no way related to the company that I work for.

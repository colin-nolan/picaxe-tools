# Docker PICAXE Pre-processor

## Building
To build the image from source:
```
docker build -t colinnolan/picaxe-preprocessor:latest .
```


## Usage
### Programming
The PICAXE "compilers" can programme connected PICAXE chips:
```bash
CODE_LOCATION=/my/code/main.bas
docker run -v "${CODE_LOCATION}":"${CODE_LOCATION}" \
        --rm colinnolan/picaxe-preprocessor:latest "${CODE_LOCATION}"
```


## Legal
I am not affiliated to [Revolution Education Ltd](https://rev-ed.co.uk/) in any way.

This work is in no way related to the company that I work for.

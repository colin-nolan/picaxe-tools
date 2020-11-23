FROM alpine as downloader

RUN apk add \
    curl \
    tar

ARG COMPILERS_LOCATION=https://picaxe.com/downloads/picaxe.tgz

RUN mkdir /opt/picaxe \
    && curl -fsSL "${COMPILERS_LOCATION}" | tar -xzvC /opt/picaxe


FROM ubuntu:20.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc-multilib \
    && rm -rf /var/lib/apt/lists/*

COPY --from=downloader /opt/picaxe /opt/picaxe

ENV PATH="${PATH}:/opt/picaxe"

WORKDIR /data

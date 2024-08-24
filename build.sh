#!/bin/sh

DOCKER_HUB_PROJECT=snowdreamtech/postgres
DOCKER_HUB_PROJECT1=snowdreamtech/postgresql
GITHUB_PROJECT=ghcr.io/snowdreamtech/postgres
GITHUB_PROJECT1=ghcr.io/snowdreamtech/postgresql

docker buildx build --platform=linux/386,linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/riscv64,linux/s390x \
    -t ${DOCKER_HUB_PROJECT}:latest \
    -t ${DOCKER_HUB_PROJECT}:16.3\
    -t ${DOCKER_HUB_PROJECT}:16 \
    -t ${GITHUB_PROJECT}:latest \
    -t ${GITHUB_PROJECT}:16.3\
    -t ${GITHUB_PROJECT}:16 \
    -t ${DOCKER_HUB_PROJECT1}:latest \
    -t ${DOCKER_HUB_PROJECT1}:16.3\
    -t ${DOCKER_HUB_PROJECT1}:16 \
    -t ${GITHUB_PROJECT1}:latest \
    -t ${GITHUB_PROJECT1}:16.3\
    -t ${GITHUB_PROJECT1}:16 \
    . \
    --push

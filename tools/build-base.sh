#!/bin/bash

set -o allexport
source .env
set +o allexport

docker build \
  -t chip-base \
  --build-arg "FROM_KERNEL=$FROM_KERNEL" \
  --build-arg "NEW_KERNEL=$NEW_KERNEL" \
  --build-arg "BASE_DIR=$BASE_DIR" \
  -f Dockerfile.base .

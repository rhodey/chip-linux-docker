#!/bin/bash

set -o allexport
source .env
set +o allexport

docker build \
  -t chip-kernel \
  --build-arg "BASE_DIR=$BASE_DIR" \
  --build-arg "MAKE_J=$MAKE_J" .

#!/bin/bash

set -o allexport
source .env
set +o allexport

docker run \
  --name chip-config \
  -v $(pwd)/.config-in:$BASE_DIR/kernel/.config-in:ro \
  -it chip-base \
  bash -c 'make ARCH=arm CROSS_COMPILE=${CC_TOOL} menuconfig' || { echo 'docker run failed' ; exit 1; }

docker commit chip-config chip-config.img && \
  docker rm chip-config

#!/bin/bash

docker run \
  -v $(pwd)/loot:/tmp/loot \
  --rm -it chip-kernel-deb \
  bash -c 'cp $KERNEL_DIR/../*.deb /tmp/loot/'

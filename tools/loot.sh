#!/bin/bash

docker run \
  -v $(pwd)/loot:/tmp/loot \
  --rm -it chip-kernel \
  bash -c 'cp $KERNEL_DIR/arch/arm/boot/zImage /tmp/loot/vmlinuz-$NEW_KERNEL && \
  cp $KERNEL_DIR/.config /tmp/loot/config-$NEW_KERNEL && \
  cp $KERNEL_DIR/System.map /tmp/loot/System.map-$NEW_KERNEL && \
  cp -r $MOD_DIR/lib/modules /tmp/loot && \
  mkdir -p /tmp/loot/firmware/$NEW_KERNEL && \
  cp -r $MOD_DIR/lib/firmware/* /tmp/loot/firmware/$NEW_KERNEL && \
  unlink /tmp/loot/modules/$NEW_KERNEL/build && \
  unlink /tmp/loot/modules/$NEW_KERNEL/source'

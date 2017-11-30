#!/bin/bash

set -o allexport
source .env
set +o allexport

scp loot/vmlinuz-* loot/config-* loot/System.map-* root@$CHIP_IP:/boot || { echo 'scp kernel failed' ; exit 1; }
cd loot/modules && tar cf - $NEW_KERNEL | ssh root@$CHIP_IP 'cd /lib/modules; tar xf -' || { echo 'scp modules failed' ; exit 1; }
cd ../firmware && tar cf - $NEW_KERNEL | ssh root@$CHIP_IP 'cd /lib/firmware; tar xf -' || { echo 'scp firmware failed' ; exit 1; }

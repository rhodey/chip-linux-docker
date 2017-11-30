# chip-linux-docker
Tools for [cross-compiling](https://en.wikipedia.org/wiki/Cross_compiler) linux kernels for the
Next Thing Co. [Pocket CHIP](https://getchip.com/pages/pocketchip) using docker. Follow the steps
in order below, at the end of this all the `loot/` folder in this repository will contain your new
kernel image and modules. If you've had success with this build process please let me know, so far
this process has been reported to work well with:
  + 4.4.13-ntc-mlc

## Environment Variables
This is where you get to decide what kernel revision you want to build and the name of your new
kernel:
  + `FROM_KERNEL` will be used to download the correct [kernel sources](https://github.com/NextThingCo/CHIP-linux).
  + `NEW_KERNEL` should match the version of `FROM_KERNEL` but with a new postfix and `"+"`.
  + `CHIP_IP` is used to copy the correct kernel config from your CHIP via [scp](https://en.wikipedia.org/wiki/Secure_copy).
  + `MAKE_J` should be equal to `N+1`, where `N` is the number of CPU cores on your computer.
  + `BASE_DIR` can just be left as is.

```
$ export FROM_KERNEL=4.4.13-ntc-mlc
$ export NEW_KERNEL=4.4.13-rhodey+
$ export CHIP_IP=192.168.1.10
$ export MAKE_J=9
$ export BASE_DIR=/root/chip-linux
```

## Build Base Image
Here we're going to build a new docker image that contains all the dependencies needed to compile
the linux kernel. This image will also contain the [sources for CHIP-linux](https://github.com/NextThingCo/CHIP-linux)
along with the [RTL8723BS wifi/bluetooth driver](https://github.com/NextThingCo/RTL8723BS).
```
$ docker build \
    -t chip-base \
    --build-arg "FROM_KERNEL=$FROM_KERNEL" \
    --build-arg "NEW_KERNEL=$NEW_KERNEL" \
    --build-arg "BASE_DIR=$BASE_DIR" \
    -f Dockerfile.base .
```

## Configure Kernel
Next we need to compile the `make menuconfig` build target, this is an essential step in any kernel
compilation. The output of this process will be a file named `.config` that instructs the rest of
the build process as to what modules should be included in the kernel. It's best to start this
process from an existing config file and so that's what the `scp` line below is about, it is an
attempt to copy an existing (reliable) config file from your CHIP.

If this is your first try at kernel compilation you should avoid customizing too much from the
defaults, the only setting **you must change** is the `"Local version"` string, it must match the
postfix you added in the `NEW_KERNEL` environment variable above. After running the first two
commands below do it like this:
  1. select `"Load"`.
  2. enter `.config-in` and then `"OK"`.
  3. select `"General setup"`.
  4. select `"Local version - Append to kernel release"`.
  5. enter in your kernel postfix (except the `"+"`, in my example `-rhodey`) and then `"OK"`.
  6. select `"Save"`.
  7. enter `.config` and then `"OK"`.
  8. exit by pressing escape four times.

Don't forget to run the last command below, this `$ docker commit ...` command is a fancy little
trick to get around the bother that [docker doesn't support interactive build processes](https://github.com/moby/moby/issues/1669).
Basically what we're doing is creating a docker image from a stopped docker container, specifically
our `make menuconfig` process.
```
$ scp chip@$CHIP_IP:/boot/config-$FROM_KERNEL .config-in
$ docker run \
    --name chip-config \
    -v $(pwd)/.config-in:$BASE_DIR/kernel/.config-in:ro \
    -it chip-base \
    bash -c 'make ARCH=arm CROSS_COMPILE=${CC_TOOL} menuconfig'
$ docker commit chip-config chip-config.img && \
    docker rm chip-config
```

## Build Kernel
Yayyy! It is time to build the kernel, pretty easy so far huh? This process should take anywhere from
5 to 30 minutes depending on your system specs.
```
$ docker build \
    -t chip-kernel \
    --build-arg "BASE_DIR=$BASE_DIR" \
    --build-arg "MAKE_J=$MAKE_J" .
```

## Grab the Loot!
And that's it! Now all that's left to do is copy the kernel image, modules, and firmware out of the
docker image we just built in the step above. All these files will be copied to the `loot/` folder
in this repository.
```
$ ./tools/loot.sh
```

## CHIP Installation
The final step is to install the new kernel image, modules, and firmware onto your CHIP. All of the
commands below are perfectly safe to run except the last, the last command replaces the default
kernel image with the one we just built. If you want to be careful you can follow
[this procedure](http://www.raspibo.org/wiki/index.php/Chip9%24_U-Boot:_how_to_test_a_new_kernel_%28in_a_safe_way%29)
to test out the new kernel before replacing the default.

Worst case your CHIP won't boot and you'll need to find a USB-to-Serial converter to fix it.
However, if anything does go wrong it's most likely that you're CHIP will still boot fine but just
not load a module or two. You can restore the default kernel at anytime by running
`# cp /boot/zImage.bak /boot/zImage`.
```
$ scp loot/vmlinuz-* loot/config-* loot/System.map-* root@$CHIP_IP:/boot
$ cd loot/modules && tar cf - $NEW_KERNEL | ssh root@$CHIP_IP 'cd /lib/modules; tar xf -'
$ cd ../firmware && tar cf - $NEW_KERNEL | ssh root@$CHIP_IP 'cd /lib/firmware; tar xf -' && cd ../..
$ ssh root@$CHIP_IP cp /boot/vmlinuz-$NEW_KERNEL /boot/zImage
```

## Reboot & Good Luck!
Thanks to [Next Thing Co](https://nextthing.co/) for bringing such a cute, smol linux device to
life. Also a big thanks to [@renzo](https://bbs.nextthing.co/u/renzo/summary) for [their how-to](http://www.raspibo.org/wiki/index.php/Compile_the_Linux_kernel_for_Chip:_my_personal_HOWTO)
which gave me a good starting place.

## License
Copyright 2017 Rhodey Orbits, GPLv3.

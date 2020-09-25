#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix pixiecore python

set -eu -o pipefail

configFile=./config.json
pxe_ramdisk=$(nix-build --no-gc-warning --no-out-link system.nix -A config.system.build.netbootRamdisk --arg config "builtins.fromJSON (builtins.readFile $configFile)")
pxe_kernel=$(nix-build --no-gc-warning --no-out-link system.nix -A config.system.build.kernel --arg config "builtins.fromJSON (builtins.readFile $configFile)")
system=$(nix-build --no-gc-warning --no-out-link system.nix -A config.system.build.toplevel --arg config "builtins.fromJSON (builtins.readFile $configFile)")

sudo pixiecore boot $pxe_kernel/bzImage $pxe_ramdisk/initrd --cmdline "init=$system/init $(cat $system/kernel-params)"

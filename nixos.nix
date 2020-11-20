{ config, pkgs, lib, netbootPkgsSrc, ... }:

let
  netbootpkgs = pkgs.callPackage "${netbootpkgsSrc}" {};
in {

  # Create the squashfs image that contains the Nix store.
  system.build.squashfsStore = netbootpkgs.makeSquashfsManifest {
    name = "iso-manifest";
    storeContents = config.system.build.toplevel;
  };

  boot.loader.grub.enable = false;

  fileSystems."/" =
    { fsType = "tmpfs";
      options = [ "mode=0755" ];
    };

  fileSystems."/nix" =
    { fsType = "tmpfs";
      options = [ "mode=0755" ];
      neededForBoot = true;
    };

  nix.package = pkgs.nixUnstable;

  boot.initrd.availableKernelModules = [ "squashfs" "overlay" "rng_core" "tpm" "tpm_tis_core" "tpm_tis" ];

  boot.initrd.kernelModules = [ "loop" "overlay" ];

  boot.kernelParams = [ "panic=1" "boot.panic_on_fail" ];

  services.openssh.enable = true;
  users.users.builder = {
    useDefaultShell = true;
  };
  users.groups.nix-trusted-user = {};
  nix.trustedUsers = [ "root" "builder" "@nix-trusted-user" ];

  systemd.enableEmergencyMode = false;
  systemd.services."serial-getty@ttyS0".enable = false;
  systemd.services."serial-getty@hvc0".enable = false;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@".enable = false;

  services.udisks2.enable = false;
  documentation.enable = false;
  powerManagement.enable = false;
  programs.command-not-found.enable = false;

  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      userServices = true;
      addresses = true;
      hinfo = true;
      workstation = true;
      domain = true;
    };
  };
  environment.etc."avahi/services/ssh.service" = {
    text = ''
      <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name replace-wildcards="yes">%h</name>
        <service>
          <type>_ssh._tcp</type>
          <port>22</port>
        </service>
      </service-group>
    '';
  };

  services.logind.extraConfig = ''
    HandleLidSwitch = ignore
    HandleLidSwitchExternalPower = ignore
  '';

  nix.extraOptions = ''
    min-free = 1073741824 # 2^30
    max-free = 4294967296 # 2^32
  '';

  # We generate it ourselves
  services.openssh.hostKeys = lib.mkForce [];

  boot.postBootCommands = ''
    # After booting, register the contents of the Nix store
    # in the Nix database in the tmpfs.
    ${config.nix.package}/bin/nix-store --load-db < /nix/registration

    # nixos-rebuild also requires a "system" profile and an
    # /etc/NIXOS tag.
    touch /etc/NIXOS
    ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

    # Load ssh key from TPM NVRAM if it exists. Otherwise generate it
    # from scratch.
    tpm_ssh_host_key_index=133281
    mkdir -m 0755 -p /etc/ssh
    if ! [ -f /etc/ssh/ssh_host_rsa_key ]; then
      if [ -e /dev/tpm0 ] && ${pkgs.tpm2-tools}/bin/tpm2_nvread -T device:/dev/tpm0 $tpm_ssh_host_key_index -C o -o /etc/ssh/ssh_host_rsa_key.der 2>/tmp/stderr; then
        chmod 600 /etc/ssh/ssh_host_rsa_key.der
        ${pkgs.openssl}/bin/openssl rsa -inform der -in /etc/ssh/ssh_host_rsa_key.der -outform pem -out /etc/ssh/ssh_host_rsa_key
        chmod 600 /etc/ssh/ssh_host_rsa_key
      else
        ${pkgs.openssh}/bin/ssh-keygen -b 2048 -m PEM -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""

        # put the key in nvram
        if [ -e /dev/tpm0 ]; then
          ${pkgs.openssl}/bin/openssl rsa -in /etc/ssh/ssh_host_rsa_key -outform der -out /etc/ssh/ssh_host_rsa_key.der
          chmod 600 /etc/ssh/ssh_host_rsa_key.der
          ${pkgs.tpm2-tools}/bin/tpm2_nvdefine -T device:/dev/tpm0 $tpm_ssh_host_key_index -s 1194 -a "ownerread|ownerwrite" || true
          ${pkgs.tpm2-tools}/bin/tpm2_nvwrite -T device:/dev/tpm0 $tpm_ssh_host_key_index -C o -i /etc/ssh/ssh_host_rsa_key.der || true
        fi
      fi
    fi
  '';

  boot.initrd.compressor = "gzip -9n";

  system.build.nixStoreRamdisk = netbootpkgs.makeCpioRecursive {
    name = "better-initrd";
    inherit (config.boot.initrd) compressor;
    root = config.system.build.squashfsStore;
  };

  system.build.manifestRamdisk = pkgs.makeInitrd {
    inherit (config.boot.initrd) compressor;
    contents =
      [
        {
          object = config.system.build.squashfsStore.manifest;
          symlink = "/nix-store-squashes";
        }
      ];
  };

  boot.initrd.postMountCommands = ''
    echo "Mounting initial store"

    mkdir -p /mnt-root/nix/.squash
    mkdir -p /mnt-root/nix/store
    gunzip < /nix-store-squashes/registration.gz > /mnt-root/nix/registration
    # the manifest splits the /nix/store/.... path with a " " to
    # prevent Nix from determining it depends on things.
    for f in $(cat /nix-store-squashes/squashes | sed 's/ //'); do
      prefix=$(basename "$(dirname "$f")")
      suffix=$(basename "$f")
      dest="$prefix$suffix"
      mkdir "/mnt-root/nix/.squash/$dest"
      mount -t squashfs -o loop "$f" "/mnt-root/nix/.squash/$dest"
      (
        # Ideally, these would not be copied and the mounts would be
        # used directly. However, we can't: systemd tries to unmount
        # them all at shutdown and gets stuck. The trade-off here is
        # an increased RAM requirement and a slightly slower
        # start-up. However, all that is much faster than needing
        # to recreate the entire squashfs every time.
        cd /mnt-root/nix/store/
        cp -ar "../.squash/$dest/$dest" "./$dest"
      )
      umount "/mnt-root/nix/.squash/$dest"
      rm "$f"
    done
  '';

}

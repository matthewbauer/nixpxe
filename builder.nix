{ config, pkgs, lib, ... }:

{

  # Create the squashfs image that contains the Nix store.
  system.build.squashfsStore = pkgs.callPackage (pkgs.path + /nixos/lib/make-squashfs.nix) {
    storeContents = [ config.system.build.toplevel ];
  };

  # Create the initrd
  system.build.netbootRamdisk = pkgs.makeInitrd {
    inherit (config.boot.initrd) compressor;
    prepend = [ "${config.system.build.initialRamdisk}/initrd" ];

    contents =
      [ { object = config.system.build.squashfsStore;
          symlink = "/nix-store.squashfs";
        }
      ];
  };

  boot.loader.grub.enable = false;

  fileSystems."/" =
    { fsType = "tmpfs";
      options = [ "mode=0755" ];
    };

  fileSystems."/nix/.ro-store" =
    { fsType = "squashfs";
      device = "../nix-store.squashfs";
      options = [ "loop" ];
      neededForBoot = true;
    };

  fileSystems."/nix/.rw-store" =
    { fsType = "tmpfs";
      options = [ "mode=0755" ];
      neededForBoot = true;
    };

  fileSystems."/nix/store" =
    { fsType = "overlay";
      device = "overlay";
      options = [
        "lowerdir=/nix/.ro-store"
        "upperdir=/nix/.rw-store/store"
        "workdir=/nix/.rw-store/work"
      ];
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
    ${config.nix.package}/bin/nix-store --load-db < /nix/store/nix-path-registration

    # Load ssh key from TPM NVRAM if it exists. Otherwise generate it
    # from scratch.
    tpm_ssh_host_key_index=133279
    mkdir -m 0755 -p /etc/ssh
    if ! [ -f /etc/ssh/ssh_host_rsa_key ]; then
      if [ -e /dev/tpm0 ] && ${pkgs.tpm2-tools}/bin/tpm2_nvread $tpm_ssh_host_key_index -C o -o /etc/ssh/ssh_host_rsa_key.der 2>/tmp/stderr; then
        chmod 600 /etc/ssh/ssh_host_rsa_key.der
        ${pkgs.openssl}/bin/openssl rsa -inform der -in /etc/ssh/ssh_host_rsa_key.der -outform pem -out /etc/ssh/ssh_host_rsa_key
        chmod 600 /etc/ssh/ssh_host_rsa_key
      else
        ${pkgs.openssh}/bin/ssh-keygen -b 2048 -m PEM -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""

        # put the key in nvram
        if [ -e /dev/tpm0 ]; then
          ${pkgs.openssl}/bin/openssl rsa -in /etc/ssh/ssh_host_rsa_key -outform der -out /etc/ssh/ssh_host_rsa_key.der
          chmod 600 /etc/ssh/ssh_host_rsa_key.der
          ${pkgs.tpm2-tools}/bin/tpm2_nvdefine $tpm_ssh_host_key_index -s 1191 -a "ownerread|ownerwrite" || true
          ${pkgs.tpm2-tools}/bin/tpm2_nvwrite $tpm_ssh_host_key_index -C o -i /etc/ssh/ssh_host_rsa_key.der || true
        fi
      fi
    fi
  '';

}

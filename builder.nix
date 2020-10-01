{ config, pkgs, ... }:

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

  boot.initrd.availableKernelModules = [ "squashfs" "overlay" ];
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

  boot.postBootCommands = ''
    # After booting, register the contents of the Nix store
    # in the Nix database in the tmpfs.
    ${config.nix.package}/bin/nix-store --load-db < /nix/store/nix-path-registration
  '';

}

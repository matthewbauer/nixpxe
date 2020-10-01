{ pkgs ? import <nixpkgs> { }, config ? {}, macAddress ? "*"
, hostName ? "unknown" }: let
  config' = config.${macAddress} or config."*";
in import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = [
    ./builder.nix
    ({ lib, ... }: {
      nixpkgs.localSystem = lib.mkForce {
        system = if builtins.currentSystem == "x86_64-darwin"
                 then "x86_64-linux"
                 else builtins.currentSystem;
      };
      networking.hostName =
        if macAddress == "*" then hostName
        else config'.hostName;
      i18n.defaultLocale = "${config'.lang}.UTF-8";
      i18n.supportedLocales = [ "${config'.lang}.UTF-8/UTF-8" ];
      users.users.builder.openssh.authorizedKeys.keys = config'.authorizedKeys;
      users.users.root.openssh.authorizedKeys.keys = config'.rootAuthorizedKeys;

      nixpkgs.crossSystem = lib.mkIf (config' ? system) { inherit (config') system; };
      nix.maxJobs = lib.mkIf (config' ? maxJobs) config'.maxJobs;
      nix.buildCores = lib.mkIf (config' ? maxJobs) config'.cores;
    })
  ];
}

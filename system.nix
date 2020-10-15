{ pkgs ? import <nixpkgs> { }, config ? {}, macAddress ? "*"
, hostName ? "unknown" }: let
  config' = config.${macAddress} or config."*";
in import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = [
    ./builder.nix
    ({ lib, ... }: let
        system = if builtins.currentSystem == "x86_64-darwin"
                 then "x86_64-linux"
                 else builtins.currentSystem;
    in {
      nixpkgs.localSystem = lib.mkForce { inherit system; };
      networking.hostName =
        if macAddress == "*" then hostName
        else config'.hostName;
      time.timeZone = lib.mkIf (config' ? timeZone) config'.timeZone;
      i18n.defaultLocale = lib.mkIf (config' ? lang) "${config'.lang}.UTF-8";
      i18n.supportedLocales = lib.mkIf (config' ? lang) [ "${config'.lang}.UTF-8/UTF-8" ];
      users.users = lib.mkIf (config' ? users) config'.users;
      nixpkgs.crossSystem = lib.mkIf (config' ? system && config'.system != system) { inherit (config') system; };
      nix.maxJobs = lib.mkIf (config' ? maxJobs) config'.maxJobs;
      nix.buildCores = lib.mkIf (config' ? maxJobs) config'.cores;
    })
  ];
}

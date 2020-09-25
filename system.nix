{ pkgs ? import <nixpkgs> { }
, config ? {
  lang = "en_US";
  regDom = "US";
  hostName = "nixos";
  networks = {};
  authorizedKeys = [];
} }:
import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = [
    ./builder.nix
    ({ lib, ... }: {
      nixpkgs.localSystem = lib.mkForce {
        system = if builtins.currentSystem == "x86_64-darwin"
                 then "x86_64-linux"
                 else builtins.currentSystem;
      };
      networking.wireless.networks = builtins.mapAttrs (_: value: { pskRaw = value; }) (config.networks or {});
      networking.hostName = config.hostName;
      i18n.defaultLocale = config.lang;
      i18n.supportedLocales = [ "${config.lang}.UTF-8/UTF-8" ];
      boot.extraModprobeConfig = ''
        options cfg80211 ieee80211_regdom="${config.regDom}"
      '';
      users.users.builder.openssh.authorizedKeys.keys = config.authorizedKeys;
      users.users.root.openssh.authorizedKeys.keys = config.rootAuthorizedKeys;
    })
  ];
}

{
  description = "Nixpxe";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  inputs.netbootpkgs.url = "github:matthewbauer/netboot.nix?ref=flakes";

  outputs = { self, nixpkgs, netbootpkgs }: {
    nixosModule = import ./nixos.nix { netbootpkgsSrc = netbootpkgs; };
    defaultTemplate.path = ./template;
    defaultTemplate.description = "Default template";
  };

}

{
  description = "Nixpxe";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  inputs.netbootpkgs.url = "github:grahamc/netboot.nix";

  outputs = { self, nixpkgs, netbootpkgs }: {
    nixosModule = import ./nixos.nix { netbootpkgsSrc = netbootpkgs; };
  };

}

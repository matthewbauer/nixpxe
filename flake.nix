{
  description = "Nixpxe";

  inputs.netbootpkgs.url = "github:matthewbauer/netboot.nix?ref=flakes";

  outputs = { self, netbootpkgs }: {
    nixosModule = import ./nixos.nix { netbootpkgsSrc = netbootpkgs; };
    defaultTemplate.path = ./template;
    defaultTemplate.description = "Default template";
  };

}

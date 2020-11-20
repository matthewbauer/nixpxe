{
  description = "Example Nixpxe System";

  inputs.nixpxe.url = "github:matthewbauer/nixpxe?ref=flakes"; # this repo
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpxe, nixpkgs }: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixpxe.nixosModule
        ({ ... }: {
          users.users = {
            builder.openssh.authorizedKeys.keys = [
              "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6Z1uRAusNwBessHWbQ+FH3lTRw+9chp5BP4DzIw0SDzFooSKXlpVzYAjqmUc3yk1wnjFuz/srYTyFq9U1K8ttIGGrieyNYcUoX9KeGbeuL1x9CB+z65M6jH3VKMacbpNQPcWLCXy8IMIxuW4OcJMfFwA8D90evPf40GfivntfW+bCdhif2/6G90WhpdRQVpu3wSQ7cZnIb8YF4jXbVrF8/vHJPNfL0od9ZnqY/XofS9FIT0vvVqJT+l9GqK3x6185FKJp+8d5xJ22ii2T1nMAt73zIngDfLIDdvPd55m23JlRBo6LYMiuT8pcTJ+nIWb3M6ENtgXQ/5A6lUBXQh8O3y1cEi6cJqtKKZI+a8ctjyTcwvhopuW/G6WtgdkCLWVh/xquC4zzSTIucCalS6vChmBLVjb321XRWOvH8TN4EmPToLKA0VeU7H2nRlx6MoGAE/lQKsqHZjZL771hzCPbgVttibVbAwtg7W36e+nO6R7fpTcAeDB2o0MlnkecJKs= mbauer@MacBook-Pro"
            ];
            root.openssh.authorizedKeys.keys = [
              "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6Z1uRAusNwBessHWbQ+FH3lTRw+9chp5BP4DzIw0SDzFooSKXlpVzYAjqmUc3yk1wnjFuz/srYTyFq9U1K8ttIGGrieyNYcUoX9KeGbeuL1x9CB+z65M6jH3VKMacbpNQPcWLCXy8IMIxuW4OcJMfFwA8D90evPf40GfivntfW+bCdhif2/6G90WhpdRQVpu3wSQ7cZnIb8YF4jXbVrF8/vHJPNfL0od9ZnqY/XofS9FIT0vvVqJT+l9GqK3x6185FKJp+8d5xJ22ii2T1nMAt73zIngDfLIDdvPd55m23JlRBo6LYMiuT8pcTJ+nIWb3M6ENtgXQ/5A6lUBXQh8O3y1cEi6cJqtKKZI+a8ctjyTcwvhopuW/G6WtgdkCLWVh/xquC4zzSTIucCalS6vChmBLVjb321XRWOvH8TN4EmPToLKA0VeU7H2nRlx6MoGAE/lQKsqHZjZL771hzCPbgVttibVbAwtg7W36e+nO6R7fpTcAeDB2o0MlnkecJKs= mbauer@MacBook-Pro"
            ];
            mbauer = {
              extraGroups = [ "wheel", "nix-trusted-user" ];
              isNormalUser = true;
              openssh.authorizedKeys.keys = [
                "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6Z1uRAusNwBessHWbQ+FH3lTRw+9chp5BP4DzIw0SDzFooSKXlpVzYAjqmUc3yk1wnjFuz/srYTyFq9U1K8ttIGGrieyNYcUoX9KeGbeuL1x9CB+z65M6jH3VKMacbpNQPcWLCXy8IMIxuW4OcJMfFwA8D90evPf40GfivntfW+bCdhif2/6G90WhpdRQVpu3wSQ7cZnIb8YF4jXbVrF8/vHJPNfL0od9ZnqY/XofS9FIT0vvVqJT+l9GqK3x6185FKJp+8d5xJ22ii2T1nMAt73zIngDfLIDdvPd55m23JlRBo6LYMiuT8pcTJ+nIWb3M6ENtgXQ/5A6lUBXQh8O3y1cEi6cJqtKKZI+a8ctjyTcwvhopuW/G6WtgdkCLWVh/xquC4zzSTIucCalS6vChmBLVjb321XRWOvH8TN4EmPToLKA0VeU7H2nRlx6MoGAE/lQKsqHZjZL771hzCPbgVttibVbAwtg7W36e+nO6R7fpTcAeDB2o0MlnkecJKs= mbauer@MacBook-Pro"
              ];
            };
          };
        })
      ];
    };
    nixosConfigurations."00:e0:4c:68:01:df" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixpxe.nixosModule
        ({ lib, ... }: {
          networking.hostName = "dellbook";
          nixpkgs.crossSystem = lib.mkForce { system = "x86_64-linux"; };
          time.timeZone = "America/New_York";
          i18n.defaultLocale = "en_us.UTF-8";
          i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
          users.users = {
            builder.openssh.authorizedKeys.keys = [
              "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6Z1uRAusNwBessHWbQ+FH3lTRw+9chp5BP4DzIw0SDzFooSKXlpVzYAjqmUc3yk1wnjFuz/srYTyFq9U1K8ttIGGrieyNYcUoX9KeGbeuL1x9CB+z65M6jH3VKMacbpNQPcWLCXy8IMIxuW4OcJMfFwA8D90evPf40GfivntfW+bCdhif2/6G90WhpdRQVpu3wSQ7cZnIb8YF4jXbVrF8/vHJPNfL0od9ZnqY/XofS9FIT0vvVqJT+l9GqK3x6185FKJp+8d5xJ22ii2T1nMAt73zIngDfLIDdvPd55m23JlRBo6LYMiuT8pcTJ+nIWb3M6ENtgXQ/5A6lUBXQh8O3y1cEi6cJqtKKZI+a8ctjyTcwvhopuW/G6WtgdkCLWVh/xquC4zzSTIucCalS6vChmBLVjb321XRWOvH8TN4EmPToLKA0VeU7H2nRlx6MoGAE/lQKsqHZjZL771hzCPbgVttibVbAwtg7W36e+nO6R7fpTcAeDB2o0MlnkecJKs= mbauer@MacBook-Pro"
            ];
            root.openssh.authorizedKeys.keys = [
              "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6Z1uRAusNwBessHWbQ+FH3lTRw+9chp5BP4DzIw0SDzFooSKXlpVzYAjqmUc3yk1wnjFuz/srYTyFq9U1K8ttIGGrieyNYcUoX9KeGbeuL1x9CB+z65M6jH3VKMacbpNQPcWLCXy8IMIxuW4OcJMfFwA8D90evPf40GfivntfW+bCdhif2/6G90WhpdRQVpu3wSQ7cZnIb8YF4jXbVrF8/vHJPNfL0od9ZnqY/XofS9FIT0vvVqJT+l9GqK3x6185FKJp+8d5xJ22ii2T1nMAt73zIngDfLIDdvPd55m23JlRBo6LYMiuT8pcTJ+nIWb3M6ENtgXQ/5A6lUBXQh8O3y1cEi6cJqtKKZI+a8ctjyTcwvhopuW/G6WtgdkCLWVh/xquC4zzSTIucCalS6vChmBLVjb321XRWOvH8TN4EmPToLKA0VeU7H2nRlx6MoGAE/lQKsqHZjZL771hzCPbgVttibVbAwtg7W36e+nO6R7fpTcAeDB2o0MlnkecJKs= mbauer@MacBook-Pro"
            ];
            mbauer = {
              extraGroups = [ "wheel", "nix-trusted-user" ];
              isNormalUser = true;
              openssh.authorizedKeys.keys = [
                "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6Z1uRAusNwBessHWbQ+FH3lTRw+9chp5BP4DzIw0SDzFooSKXlpVzYAjqmUc3yk1wnjFuz/srYTyFq9U1K8ttIGGrieyNYcUoX9KeGbeuL1x9CB+z65M6jH3VKMacbpNQPcWLCXy8IMIxuW4OcJMfFwA8D90evPf40GfivntfW+bCdhif2/6G90WhpdRQVpu3wSQ7cZnIb8YF4jXbVrF8/vHJPNfL0od9ZnqY/XofS9FIT0vvVqJT+l9GqK3x6185FKJp+8d5xJ22ii2T1nMAt73zIngDfLIDdvPd55m23JlRBo6LYMiuT8pcTJ+nIWb3M6ENtgXQ/5A6lUBXQh8O3y1cEi6cJqtKKZI+a8ctjyTcwvhopuW/G6WtgdkCLWVh/xquC4zzSTIucCalS6vChmBLVjb321XRWOvH8TN4EmPToLKA0VeU7H2nRlx6MoGAE/lQKsqHZjZL771hzCPbgVttibVbAwtg7W36e+nO6R7fpTcAeDB2o0MlnkecJKs= mbauer@MacBook-Pro"
              ];
            };
          };
          nix.maxJobs = 12;
          nix.buildCores = 6;
          networking.wireless.networks = lib.mkIf (builtins.pathExists ./networks.json) then builtins.fromJSON (builtins.readFile ./networks.json);
          networking.wireless.enable = builtins.pathExists ./networks.json;
          hardware.enableRedistributableFirmware = builtins.pathExists ./networks.json;
          networking.dhcpcd.extraConfig = ''
            interface ens20u1
            nogateway
          '';
        })
      ];
    };
  }

}

{
  description = "An NixOS flake template that you can adapt to your own system";

  # Flake inputs
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0"; # Stable Nixpkgs (use 0.1 for unstable)
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3"; # Determinate 3.*
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    antigravity-nix.url = "github:jacopone/antigravity-nix/v2.0.1-6566078776737792";
  };

  # Flake outputs
  outputs =
    { self, ... }@inputs:
    let
      # Change this if you're building for a system type other than x86 AMD Linux
      system = "x86_64-linux";

      # The flake output name of your system (`nixosConfigurations.${key}`). Change this
      # to make it less generic
    in
    {
      # A minimal (but updatable!) NixOS configuration output by this flake
      nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
        inherit system;

        # NixOS modules
        modules = [
          # Load the Determinate module, which provides Determinate Nix
          inputs.determinate.nixosModules.default
          # Load the Flatpak module
          inputs.nix-flatpak.nixosModules.nix-flatpak
          # Load sops-nix for setting up age + sops
          inputs.sops-nix.nixosModules.sops
          # Load the hardware configuration from a separate file (a common convention for NixOS)
          ./configuration.nix
          # This module provides a minimum viable NixOS configuration
          {
            nixpkgs.overlays = [
              inputs.antigravity-nix.overlays.default
            ];
          }
        ];

        specialArgs = {
          # Values to pass to modules
          unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        };
      };

      # Nix formatter

      # This applies the formatter that follows RFC 166, which defines a standard format:
      # https://github.com/NixOS/rfcs/pull/166

      # To format all Nix files:
      # git ls-files -z '*.nix' | xargs -0 -r nix fmt
      # To check formatting:
      # git ls-files -z '*.nix' | xargs -0 -r nix develop --command nixfmt --check
    };
}

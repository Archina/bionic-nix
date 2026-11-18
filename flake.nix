{
  description = "Bionic - LM Studio's agent for work and code (Linux AppImage packaging)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        # Bionic is unfree; allow it here so `nix profile add` works without
        # the user having to enable unfree packages globally.
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate =
            pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "bionic" ];
        };
      in
      {
        packages.default = pkgs.callPackage ./default.nix { };
        legacyPackages.default = self.packages.${system}.default;
        checks.basic = self.packages.${system}.default.passthru.tests.basic;
      });
}

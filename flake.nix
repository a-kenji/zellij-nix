{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    zellij.url = "github:zellij-org/zellij";
    zellij.flake = false;

    devshell.url = "github:numtide/devshell";

    rust-overlay.url = "github:oxalica/rust-overlay";

    utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
  };

  description = "A very basic flake";

  outputs = { self, nixpkgs, zellij, devshell, rust-overlay, naersk, utils}:
       utils.lib.eachDefaultSystem (system: let
        overlays = [ rust-overlay ];
        pkgs = import "${nixpkgs}".legacyPackages"${system}" {
        inherit overlays system;
      };
      naersk-lib = naersk.lib."${system}";
  in
    rec {
        # `nix build`
      packages.my-project = naersk-lib.buildPackage {
        pname = "my-project";
        root = zellij;
      };
      defaultPackage = packages.my-project;

      # `nix run`
      apps.my-project = utils.lib.mkApp {
        drv = packages.my-project;
      };
      defaultApp = apps.my-project;

      # `nix develop`
      devShell = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [ rustc cargo ];
      };
    });
}

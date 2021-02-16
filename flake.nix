{
description = "Zellij Environment";

inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    naersk.url = "github:nmattia/naersk";
    devshell.url = "github:numtide/devshell";

    binaryen.url = "github:WebAssembly/binaryen";
    binaryen.flake = false;

    utils.url = "github:numtide/flake-utils";
    utils.inputs.nixpkgs.follows = "nixpkgs";

    zellij.url = "github:zellij-org/zellij";
    zellij.flake = false;
  };

outputs = { self, nixpkgs, zellij, binaryen, devshell, rust-overlay, naersk, utils}:
       utils.lib.eachDefaultSystem (system: let

         binaryenUnstable = pkgs.stdenv.mkDerivation rec {
           pname = "binaryen";
           version = "99";
           src = binaryen;
           nativeBuildInputs = with pkgs;[ cmake python3 ];
         };

      overlays = [ (import rust-overlay) ];

      pkgs = import nixpkgs {
        inherit system overlays;
      };

      naersk-lib = naersk.lib."${system}";
      RUST_BACKTRACE = 1;
      targets = [ "wasm32-wasi" ];
      extensions = [
        "rust-src"
        "rustfmt-preview"
        "clippy-preview"
        "rust-analysis"
      ];

  ruststable = pkgs.rust-bin.stable.latest.rust.override {
    inherit extensions targets;
  };

    buildInputs = [
      ruststable
      #pkgs.rustc
      pkgs.cargo
      pkgs.rust-analyzer
      #pkgs.binaryen
      #pkgs.wasm-pack
      binaryenUnstable
    ];

  in
    rec {
        # `nix build`
      packages.zellij = naersk-lib.buildPackage {
        pname = "zellij";
        root = zellij;
      };
      defaultPackage = packages.zellij;

      # `nix run`
      apps.zellij = utils.lib.mkApp {
        drv = packages.zellij;
      };
      defaultApp = apps.zellij;

      # `nix develop`
      devShell = pkgs.mkShell {
        inherit  buildInputs RUST_BACKTRACE;
      };
    });
}

{
  description = "Zellij Nix Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    flake-utils.url = "github:numtide/flake-utils";

    zellij.url = "github:zellij-org/zellij";
    zellij.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    zellij,
    rust-overlay,
    flake-utils,
    ...
  }: let
    src = zellij;
    cargoTOML = builtins.fromTOML (builtins.readFile (src + "/Cargo.toml"));
    inherit (cargoTOML.package) version name;
    cargoLock = {
      lockFile = builtins.path {
        path = src + "/Cargo.lock";
        name = "Cargo.lock";
      };
      allowBuiltinFetchGit = true;
    };
    make-zellij = {
      makeRustPlatform,
      rustPlatform,
      cargo,
      rustc,
      stdenv,
      pkg-config,
      protobuf,
      openssl,
      patchPlugins ? true,
      is_cross ? false,
    }:
      (
        if is_cross
        then rustPlatform
        else
          (
            makeRustPlatform
            {
              inherit cargo rustc;
            }
          )
      )
      .buildRustPackage {
        inherit
          cargoLock
          name
          src
          stdenv
          version
          ;
        nativeBuildInputs = [
          pkg-config
          protobuf
        ];

        buildInputs = [
          openssl
          protobuf
        ];
        patchPhase =
          if patchPlugins
          then ''
            cp ${self.outputs.plugins.x86_64-linux.tab-bar}/bin/tab-bar.wasm zellij-utils/assets/plugins/tab-bar.wasm
            cp ${self.outputs.plugins.x86_64-linux.status-bar}/bin/status-bar.wasm zellij-utils/assets/plugins/status-bar.wasm
            cp ${self.outputs.plugins.x86_64-linux.strider}/bin/strider.wasm zellij-utils/assets/plugins/strider.wasm
            cp ${self.outputs.plugins.x86_64-linux.compact-bar}/bin/compact-bar.wasm zellij-utils/assets/plugins/compact-bar.wasm
            cp ${self.outputs.plugins.x86_64-linux.session-manager}/bin/session-manager.wasm zellij-utils/assets/plugins/session-manager.wasm
          ''
          else ":";
      };
  in
    # flake outputs
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        overlays = [(import rust-overlay)];

        pkgs = import nixpkgs {
          inherit system overlays;
        };

        stdenv =
          if pkgs.stdenv.isLinux
          then pkgs.stdenvAdapters.useMoldLinker pkgs.stdenv
          else pkgs.stdenv;

        rustToolchainTOML = pkgs.rust-bin.fromRustupToolchainFile (src + /rust-toolchain.toml);
        rustWasmToolchainTOML = rustToolchainTOML.override {
          extensions = [];
          targets = ["wasm32-wasi"];
        };

        rustc = rustToolchainTOML;
        cargo = rustToolchainTOML;

        devInputs = [
          rustToolchainTOML
          pkgs.binaryen
          pkgs.mkdocs
          pkgs.just
          pkgs.protobuf
        ];

        fmtInputs = [
          pkgs.alejandra
          pkgs.treefmt
        ];

        defaultPlugins = pkgs.callPackage ./default-plugins.nix {
          inherit cargoLock src;
          rustc = rustWasmToolchainTOML;
          cargo = rustWasmToolchainTOML;
        };
      in rec {
        packages = rec {
          # The default build compiles the plugins from src
          default = zellij;
          zellij = pkgs.callPackage make-zellij {inherit stdenv rustc cargo;};
          # The upstream build relies on precompiled binary plugins that are included in the upstream src
          zellij-upstream = pkgs.callPackage make-zellij {
            inherit stdenv rustc cargo;
            patchPlugins = false;
          };
          # The cross build doesn't use an overlay to always pull in the exact version of rust
          # that upstream is using
          zellij-cross = pkgs.callPackage make-zellij {
            inherit stdenv rustc cargo;
            is_cross = true;
          };
          zellij-cross-upstream = pkgs.callPackage make-zellij {
            inherit stdenv rustc cargo;
            is_cross = false;
            patchPlugins = false;
          };
        };
        plugins = {
          inherit (defaultPlugins) tab-bar status-bar strider compact-bar session-manager;
        };

        apps = {
          default =
            flake-utils.lib.mkApp
            {
              drv = packages.default;
            };
          zellij-upstream =
            flake-utils.lib.mkApp
            {
              drv = packages.zellij-upstream;
            };
          zellij-cross-upstream =
            flake-utils.lib.mkApp
            {
              drv = packages.zellij-cross-upstream;
            };
          zellij-cross =
            flake-utils.lib.mkApp
            {
              drv = packages.zellij-cross;
            };
        };

        devShells = {
          default = pkgs.mkShell {
            inherit name;
            # buildInputs;
            nativeBuildInputs = devInputs;
            # nativeBuildInputs ++ devInputs;
            RUST_BACKTRACE = 1;
          };
          fmtShell = pkgs.mkShell {
            buildInputs = fmtInputs;
          };
          actionlintShell = pkgs.mkShell {
            buildInputs = [pkgs.actionlint];
          };
        };

        checks = {
          inherit (self.outputs.packages.${system}) default zellij-upstream zellij-cross zellij-cross-upstream;
          inherit (self.outputs.plugins.${system}) tab-bar status-bar strider compact-bar session-manager;
        };
        formatter = pkgs.alejandra;
      }
    )
    // {
      overlays = {
        default = final: _: {
          zellij = final.callPackage make-zellij {};
          zellij-upstream = final.callPackage make-zellij {patchPlugins = false;};
          zellij-cross = final.callPackage make-zellij {
            is_cross = true;
          };
          zellij-cross-upstream = final.callPackage make-zellij {
            is_cross = false;
            patchPlugins = false;
          };
        };
        nightly = final: _: {
          zellij-nightly = final.callPackage make-zellij {};
          zellij-upstream-nightly = final.callPackage make-zellij {patchPlugins = false;};
          zellij-cross = final.callPackage make-zellij {
            is_cross = true;
          };
          zellij-cross-upstream = final.callPackage make-zellij {
            is_cross = false;
            patchPlugins = false;
          };
        };
      };
    };
}

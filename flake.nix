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

  outputs =
    { self
    , nixpkgs
    , zellij
    , rust-overlay
    , flake-utils
    , ...
    }:
    # flake outputs
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        overlays = [ (import rust-overlay) ];

        pkgs = import nixpkgs {
          inherit system overlays;
        };

        src = zellij;

        stdenv =
          if pkgs.stdenv.isLinux
          then pkgs.stdenvAdapters.useMoldLinker pkgs.stdenv
          else pkgs.stdenv;

        rustToolchainTOML = pkgs.rust-bin.fromRustupToolchainFile (src + /rust-toolchain.toml);
        rustWasmToolchainTOML = rustToolchainTOML.override {
          extensions = [ ];
          targets = [ "wasm32-wasi" ];
        };
        cargoTOML = builtins.fromTOML (builtins.readFile (src + "/Cargo.toml"));
        inherit (cargoTOML.package) version name;

        rustc = rustToolchainTOML;
        cargo = rustToolchainTOML;

        cargoLock = {
          lockFile = builtins.path {
            path = src + "/Cargo.lock";
            name = "Cargo.lock";
          };
          allowBuiltinFetchGit = true;
        };

        nativeBuildInputs = [
          pkgs.openssl
          pkgs.pkg-config
        ];


        buildInputs = [
          rustToolchainTOML
          pkgs.mkdocs

          pkgs.openssl
          pkgs.binaryen

          # formatting
          pkgs.just
          pkgs.nixpkgs-fmt
          pkgs.treefmt
        ];

        defaultPlugins = pkgs.callPackage ./default-plugins.nix {
          inherit cargoLock src;
          rustc = rustWasmToolchainTOML;
          cargo = rustWasmToolchainTOML;
        };
        patchPhase = ''
          ${pkgs.tree}/bin/tree
          cp ${defaultPlugins.tab-bar}/bin/tab-bar.wasm zellij-utils/assets/plugins/tab-bar.wasm
          cp ${defaultPlugins.status-bar}/bin/status-bar.wasm zellij-utils/assets/plugins/status-bar.wasm
          cp ${defaultPlugins.strider}/bin/strider.wasm zellij-utils/assets/plugins/strider.wasm
          cp ${defaultPlugins.compact-bar}/bin/compact-bar.wasm zellij-utils/assets/plugins/compact-bar.wasm
        '';
      in
      rec {
        packages = {
          # The default build compiles the plugins from src
          default =
            (
              pkgs.makeRustPlatform
                {
                  inherit cargo rustc;
                }
            ).buildRustPackage {
              inherit
                buildInputs
                cargoLock
                name
                nativeBuildInputs
                patchPhase
                src
                stdenv
                version
                ;
            };
          # The upstream build relies on precompiled binary plugins that are included in the upstream src
          zellij-upstream =
            (
              pkgs.makeRustPlatform
                {
                  inherit cargo rustc;
                }
            ).buildRustPackage {
              inherit
                buildInputs
                cargoLock
                name
                nativeBuildInputs
                src
                stdenv
                version
                ;
            };
        };
        plugins = {
          inherit (defaultPlugins) tab-bar status-bar strider compact-bar;
        };

        apps = {
          default = flake-utils.lib.mkApp
            {
              drv = packages.default;
            };
          zellij-upstream = flake-utils.lib.mkApp
            {
              drv = packages.zellij-upstream;
            };
        };

        devShell = pkgs.mkShell {
          name = "zellij-dev";
          inherit buildInputs nativeBuildInputs;
          RUST_BACKTRACE = 1;
        };

        checks = {
          inherit (self.outputs.packages.${system}) default zellij-upstream;
          inherit (self.outputs.plugins.${system}) tab-bar status-bar strider compact-bar;
        };
      });
}

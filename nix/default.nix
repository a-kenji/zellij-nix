{ self
, nixpkgs
, zellij
, rust-overlay
, flake-utils
, flake-compat
, # only here so we don't support `...`
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

    # env
    RUST_BACKTRACE = 1;

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
      inherit cargoLock;
      src = zellij;
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
    #`nix build`
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

    # `nix run`
    apps.zellij = flake-utils.lib.mkApp {
      drv = packages.zellij;
    };
    defaultApp = apps.zellij;

    devShell = pkgs.callPackage ./devShell.nix { inherit buildInputs RUST_BACKTRACE; };

    formatter = pkgs.alejandra;

    checks = {
      inherit (self.outputs.packages.${system}) default zellij-upstream;
      inherit (self.outputs.plugins.${system}) tab-bar status-bar strider compact-bar;
    };
  })

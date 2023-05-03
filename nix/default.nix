{ self
, nixpkgs
, zellij
, rust-overlay
, flake-utils
, flake-compat # only here so we don't support `...`
}:
# flake outputs

flake-utils.lib.eachDefaultSystem
  (system:
  let

    overlays = [ (import rust-overlay) ];

    pkgs = import nixpkgs {
      inherit system overlays;
    };

    stdenv =
      if pkgs.stdenv.isLinux
      then pkgs.stdenvAdapters.useMoldLinker pkgs.stdenv
      else pkgs.stdenv;


    # The root directory of this project
    ZELLIJ_ROOT = toString ./.;
    # Set up a local directory to install binaries in
    CARGO_INSTALL_ROOT = "${ZELLIJ_ROOT}/.cargo";

    rustToolchainToml = pkgs.rust-bin.fromRustupToolchainFile (zellij + /rust-toolchain.toml);
    rustc = rustToolchainToml;
    cargo = rustToolchainToml;

    cargoLock = {
      lockFile = builtins.path {
        path = zellij + "/Cargo.lock";
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
      rustToolchainToml
      pkgs.cargo-make
      pkgs.rust-analyzer
      pkgs.mkdocs

      # in order to run tests
      pkgs.openssl
      pkgs.pkg-config
      pkgs.binaryen

      pkgs.just
      # formatting
      pkgs.nixpkgs-fmt
      pkgs.treefmt
    ];

  in
  rec {
    #`nix build`
    packages.zellij = (pkgs.makeRustPlatform
      {
        inherit cargo rustc;
      }
    ).buildRustPackage {
      inherit buildInputs nativeBuildInputs cargoLock stdenv
        ;
      name = "zellij";
      src = zellij;
    };

    defaultPackage = packages.zellij;

    # `nix run`
    apps.zellij = flake-utils.lib.mkApp {
      drv = packages.zellij;
    };
    defaultApp = apps.zellij;

    devShell = pkgs.callPackage ./devShell.nix { inherit buildInputs RUST_BACKTRACE CARGO_INSTALL_ROOT; };
  })

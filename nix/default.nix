{ self
, nixpkgs
, zellij
, flake-compat # only here so we don't support `...`
, binaryen
, devshell
, mozillapkgs
, rust-overlay
, naersk
, flake-utils
}:
# flake outputs

flake-utils.lib.eachDefaultSystem (system:
  let

    binaryenUnstable = pkgs.callPackage ./binaryen.nix { inherit binaryen; };

    overlays = [ (import rust-overlay) ];

    pkgs = import nixpkgs {
      inherit system overlays;
    };

    # The root directory of this project
    ZELLIJ_ROOT = toString ./.;
    # Set up a local directory to install binaries in
    CARGO_INSTALL_ROOT = "${ZELLIJ_ROOT}/.cargo";

    rustToolchainToml = pkgs.rust-bin.fromRustupToolchainFile (zellij + /rust-toolchain);

    naersk-lib = naersk.lib."${system}".override {
      cargo = rustToolchainToml;
      rustc = rustToolchainToml;
    };

    RUSTFLAGS = "-Z macro-backtrace";

    # needs to be a function from list to list
    cargoOptions = opts: opts ++ [ ];

    # env
    RUST_BACKTRACE = 1;

    targets = [ "wasm32-wasi" ];
    extensions = [
      "rust-src"
      #"rustfmt-preview"
      "clippy-preview"
      "rust-analysis"
    ];

    buildInputs = [
      #rustNaerskBuild
      rustToolchainToml
      pkgs.cargo-make
      pkgs.rust-analyzer
      pkgs.mkdocs
      #binaryenUnstable

      # in order to run tests
      pkgs.openssl
      pkgs.pkg-config
      pkgs.binaryen

      # formatting
      pkgs.nixpkgs-fmt
      pkgs.treefmt
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
    apps.zellij = flake-utils.lib.mkApp {
      drv = packages.zellij;
    };
    defaultApp = apps.zellij;

    devShell = pkgs.callPackage ./devShell.nix { inherit buildInputs RUST_BACKTRACE CARGO_INSTALL_ROOT; };
  })

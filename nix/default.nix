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

flake-utils.lib.eachDefaultSystem (system: let

       # Get a specific rust version
      mozilla = pkgs.callPackage (mozillapkgs + "/package-set.nix") {};

      binaryenUnstable = pkgs.callPackage ./binaryen.nix {inherit binaryen;};

      overlays = [ (import rust-overlay) ];

      pkgs = import nixpkgs {
        inherit system overlays;
      };

       # The root directory of this project
      ZELLIJ_ROOT = toString ./.;
      # Set up a local directory to install binaries in
      CARGO_INSTALL_ROOT = "${ZELLIJ_ROOT}/.cargo";

      rustToolchainToml = pkgs.rust-bin.fromRustupToolchainFile (zellij + /rust-toolchain);
      #rustToolchainToml = (mozilla.rustChannelOf { rustToolchain = zellij + /rust-toolchain; }).rust;
      #rustToolchainToml = mozilla.rustChannels.beta.rust.override {
    #inherit extensions targets;
  #};

      naersk-lib = naersk.lib."${system}".override {
        #error: the `-Z` flag is only accepted on the nightly channel of Cargo, but this is the `stable` channel
        cargo = rustNaerskBuild;
        #rustc = rustNaerskBuild;
        #cargo = rustToolchainToml;
        rustc = rustToolchainToml;
      };

      RUSTFLAGS="-Z macro-backtrace";

      # needs to be a function from list to list
      cargoOptions = opts: opts ++ [ ];

      #cargoBuild = opts: ''bash ${zellij}/build-all.sh --release &&'' + opts;

      # env
      RUST_BACKTRACE = 1;

      targets = [ "wasm32-wasi" ];
      extensions = [
        "rust-src"
        #"rustfmt-preview"
        "clippy-preview"
        "rust-analysis"
      ];

      #oxalica
  #rustNaerskBuild = mozilla.rust-bin.nightly.latest.rust.override {
    #inherit extensions targets;
  #};

  #mozilla
  rustNaerskBuild = mozilla.latest.rustChannels.nightly.rust;
  #.override {
    #inherit extensions targets;
  #};

    buildInputs = [
      #rustNaerskBuild
      rustToolchainToml
      pkgs.cargo-make
      pkgs.rust-analyzer
      pkgs.mkdocs
      binaryenUnstable
      #pkgs.binaryen
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

    devShell = pkgs.callPackage ./devShell.nix {inherit buildInputs RUST_BACKTRACE CARGO_INSTALL_ROOT;};
    })

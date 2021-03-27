{
description = "Zellij Nix Environment";

inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    naersk.url = "github:nmattia/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell/master";

    binaryen.url = "github:WebAssembly/binaryen/main";
    binaryen.flake = false;

    utils.url = "github:numtide/flake-utils";
    utils.inputs.nixpkgs.follows = "nixpkgs";

    zellij.url = "github:zellij-org/zellij";
    zellij.flake = false;

    zellij-checkout.url = "/home/kenji/projects/zellij-nix/zellij";
    zellij-checkout.flake = false;
  };

  outputs = { ... } @ args: import ./outputs.nix args;
}

#outputs = { self, nixpkgs, zellij, zellij-checkout, binaryen, devshell, rust-overlay, naersk, utils}:
       #utils.lib.eachDefaultSystem (system: let

         ##binaryenUnstable = pkgs.stdenv.mkDerivation rec {
           ##pname = "binaryen";
           ##version = "100";
           ##src = binaryen;
           ##nativeBuildInputs = with pkgs;[ cmake python3 ];
         ##};
      #binaryenUnstable = pkgs.callPackage ./nix/binaryen.nix {};

      #overlays = [ (import rust-overlay) ];

      #pkgs = import nixpkgs {
        #inherit system overlays;
      #};

       ## The root directory of this project
      #ZELLIJ_ROOT = toString ./.;
      ## Set up a local directory to install binaries in
      #CARGO_INSTALL_ROOT = "${ZELLIJ_ROOT}/.cargo";

      #rustToolchainToml = pkgs.rust-bin.fromRustupToolchainFile (zellij-checkout + /rust-toolchain);

      #naersk-lib = naersk.lib."${system}".override {
        ##error: the `-Z` flag is only accepted on the nightly channel of Cargo, but this is the `stable` channel
        ##cargo = rustToolchainToml;
        ##rustc = rustToolchainToml;
        #cargo = rustNaerskBuild;
        #rustc = rustNaerskBuild;
      #};

      #RUSTFLAGS="-Z macro-backtrace";

      ## needs to be a function from list to list
      #cargoOptions = opts: opts ++ [ ];

      ## env
      #RUST_BACKTRACE = 1;

      #targets = [ "wasm32-wasi" ];
      #extensions = [
        #"rust-src"
        #"rustfmt-preview"
        #"clippy-preview"
        #"rust-analysis"
      #];

  #rustNaerskBuild = pkgs.rust-bin.nightly.latest.rust.override {
    #inherit extensions targets;
  #};


    #buildInputs = [
      ##rustNaerskBuild
      #rustToolchainToml
      #pkgs.cargo
      #pkgs.rust-analyzer
      #pkgs.mkdocs
      #binaryenUnstable
    #];

  #in
    #rec {
        ## `nix build`
      #packages.zellij = naersk-lib.buildPackage {
        #pname = "zellij";
        #root = zellij;
        #inherit cargoOptions  RUSTFLAGS;
      #};
      #defaultPackage = packages.zellij;

      ## `nix run`
      #apps.zellij = utils.lib.mkApp {
        #drv = packages.zellij;
      #};
      #defaultApp = apps.zellij;

      ## `nix develop`
      ## `nix develop`
      #devShell = pkgs.mkShell {
      #name = "zellij-dev";
      #inherit  buildInputs RUST_BACKTRACE CARGO_INSTALL_ROOT;
    #};
    #});}

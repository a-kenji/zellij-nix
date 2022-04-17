{
  description = "Zellij Nix Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell/master";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    binaryen.url = "github:WebAssembly/binaryen/main";
    binaryen.flake = false;

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";

    zellij.url = "github:zellij-org/zellij";
    zellij.flake = false;
  };

  outputs = { ... } @ args: import ./nix args;
}

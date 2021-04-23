{
description = "Zellij Nix Environment";

inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    naersk.url = "github:nmattia/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell/master";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    binaryen.url = "github:WebAssembly/binaryen/main";
    binaryen.flake = false;

    utils.url = "github:numtide/flake-utils";
    utils.inputs.nixpkgs.follows = "nixpkgs";

    zellij.url = "github:zellij-org/zellij";
    zellij.flake = false;

  };

  outputs = { ... } @ args: import ./nix args;
}

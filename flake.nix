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

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";

    zellij.url = "github:zellij-org/zellij";
    zellij.flake = false;

    zellij-checkout.url = "/home/kenji/projects/zellij-nix/zellij";
    zellij-checkout.flake = false;
  };

  outputs = { ... } @ args: import ./outputs.nix args;
}

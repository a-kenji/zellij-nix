# Zellij Nix Environment
supports `direnv && lorri`

- dependencies:
have `nix` installed (with flake support)

# usage:

- devshell
`nix develop`

- run package
`nix run`

- build package
`nix build`

The default outputs will build the plugins from source, making them patchable.
For example `packages.x86_64-linux.default` and `plugins.x86_64-linux.compact-bar.
`

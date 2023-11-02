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

# Outputs
```bash
nix flake show github:a-kenji/zellij-nix
```

Example output adjusted (systems omitted & commented):
```
github:a-kenji/zellij-nix
├───apps
│   └───x86_64-linux
│       ├───default: app
│       └───zellij-upstream: app
├───devShells
│   └───x86_64-linux
│       ├───default: development environment 'zellij'
├───overlays
│   ├───default: Nixpkgs overlay
│   └───nightly: Nixpkgs overlay
├───packages
│   └───x86_64-linux
│       ├───default: package 'zellij'
│       ├───zellij: package 'zellij' # Builds plugins from source, making them patcheable.
│       └───zellij-upstream: package 'zellij' # Doesn't build plugins.
└───plugins: unknown
    └───x86_64-linux
        ├───compact-bar: package 'compact-bar'
        ├───status-bar: package 'status-bar'
        ├───session-manager: package 'session-manager'
        ├───strider: package 'strider'
        └───tab-bar: package 'tab-bar'
```

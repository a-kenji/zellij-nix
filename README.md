# Zellij Nix Environment
supports 'direnv && lorri'

- dependencies:
have 'nix' installed with flake support

- packages:
builds 'binaryen' from source currently


# usage:
'git clone https://github.com/zellij-org/zellij' or a fork

- devshell
'nix develop'

- integrate devshell with 'direnv'
'cat .envrc' && read it
'direnv allow'

- run package
'nix run'

- build package
'nix build'

- update lockfile
'nix flake update'

- update lockfile & commit
'nix flake update --commit-lock-file'



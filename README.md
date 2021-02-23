# Zellij Nix Environment
supports 'direnv && lorri'

- dependencies:
have 'nix' installed with flake support

- packages:
builds 'binaryen' from source currently


# usage:
'git clone https://github.com/zellij-org/zellij' or a fork


- update lockfile
'nix flake update --recreate-lock-file'

- update lockfile & commit
'nix flake update --recreate-lock-file --commit-lock-file'

- build package
'nix build'

- run package
'nix run'

- devshell
'nix develop'

- integrate devshell with 'direnv'
'cat .envrc' && read it
'direnv allow'



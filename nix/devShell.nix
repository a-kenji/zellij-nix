{ mkShell
, buildInputs
, RUST_BACKTRACE
,
}:
mkShell {
  name = "zellij-dev";
  inherit buildInputs RUST_BACKTRACE;
}

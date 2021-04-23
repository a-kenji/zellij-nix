{mkShell
, buildInputs
, RUST_BACKTRACE
, CARGO_INSTALL_ROOT
}:

mkShell {
name = "zellij-dev";
inherit  buildInputs RUST_BACKTRACE CARGO_INSTALL_ROOT;
}

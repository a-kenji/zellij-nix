{
  cargo,
  cargoLock,
  pkgs,
  rustc,
  src,
  stdenv,
  binaryen,
}: let
  makeDefaultPlugin = name:
    (pkgs.makeRustPlatform {inherit cargo rustc;}).buildRustPackage {
      inherit
        cargoLock
        name
        src
        stdenv
        ;
      nativeBuildInputs = [binaryen];
      buildPhase = ''
        cargo build --package ${name} --release --target=wasm32-wasi
        mkdir -p $out/bin;
        wasm-opt \
        -O target/wasm32-wasi/release/${name}.wasm \
        -o $out/bin/${name}.wasm
      '';
      installPhase = ":";
      checkPhase = ":";
    };
in {
  status-bar = makeDefaultPlugin "status-bar";
  tab-bar = makeDefaultPlugin "tab-bar";
  strider = makeDefaultPlugin "strider";
  compact-bar = makeDefaultPlugin "compact-bar";
}

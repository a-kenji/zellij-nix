{
  cargo,
  cargoLock,
  pkgs,
  protobuf,
  rustc,
  src,
  stdenv,
  binaryen,
  optimize ? true,
}:
let
  makeDefaultPlugin =
    name:
    (pkgs.makeRustPlatform { inherit cargo rustc; }).buildRustPackage {
      inherit
        cargoLock
        name
        src
        stdenv
        ;
      nativeBuildInputs = [
        binaryen
        protobuf
      ];
      buildPhase = ''
        cargo build --package ${name} --release --target=wasm32-wasi
        mkdir -p $out/bin;
      '';
      installPhase =
        if optimize then
          ''
            wasm-opt \
            -Oz target/wasm32-wasi/release/${name}.wasm \
            -o $out/bin/${name}.wasm \
            --enable-bulk-memory
          ''
        else
          ''
            mv \
            target/wasm32-wasi/release/${name}.wasm \
            $out/bin/${name}.wasm
          '';
      doCheck = false;
    };
in
{
  compact-bar = makeDefaultPlugin "compact-bar";
  configuration = makeDefaultPlugin "configuration";
  session-manager = makeDefaultPlugin "session-manager";
  status-bar = makeDefaultPlugin "status-bar";
  strider = makeDefaultPlugin "strider";
  tab-bar = makeDefaultPlugin "tab-bar";
}

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
  wasmTarget ? "wasm32-wasip1",
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
        cargo build --package ${name} --release --target=${wasmTarget}
        mkdir -p $out/bin;
      '';
      installPhase =
        if optimize then
          ''
            wasm-opt \
            -Oz target/${wasmTarget}/release/${name}.wasm \
            -o $out/bin/${name}.wasm \
            --enable-bulk-memory
          ''
        else
          ''
            mv \
            target/${wasmTarget}/release/${name}.wasm \
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

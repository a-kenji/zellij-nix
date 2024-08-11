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
  makePlugin =
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
            substituteInPlace dev.kdl --replace 'file:target/wasm32-wasi/debug/multitask.wasm' "${placeholder "out"}"
            mkdir -p $out/share;
            cp  dev.kdl $out/share/multitask.kdl
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
  multitask = makePlugin "multitask";
}

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
        cargo build --package ${name} --release --target=${wasmTarget}
        mkdir -p $out/bin;
      '';
      installPhase =
        if optimize then
          ''
            wasm-opt \
            -Oz target/${wasmTarget}/release/${name}.wasm \
            -o $out/bin/${name}.wasm \
            --enable-bulk-memory \
            --enable-nontrapping-float-to-int
            substituteInPlace dev.kdl --replace 'file:target/${wasmTarget}/debug/multitask.wasm' "${placeholder "out"}"
            mkdir -p $out/share;
            cp  dev.kdl $out/share/multitask.kdl
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
  multitask = makePlugin "multitask";
}

{ stdenv
, pkgs
, binaryen
, cmake
, python3
}:

stdenv.mkDerivation rec {
  pname = "binaryen";
  version = "101";
  src = binaryen;
  nativeBuildInputs = with pkgs;[ cmake python3 ];
}

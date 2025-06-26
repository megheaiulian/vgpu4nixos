{
  stdenv,
  fetchFromGitLab,
  cmake,
  pkg-config,
  lief
}:
stdenv.mkDerivation rec {
  pname = "gridd-unlock-patcher";
  version = "1.1";

  src = fetchFromGitLab {
    owner = "vGPU";
    repo = pname;
    rev = "16fb0727724d1dd9b1f57e4ac619cdab64e595fb";
    sha256 = "sha256-kho3DIepg52HF1ktcLadKg3jUsyvVWQr3q3wiAmWHkM=";
    domain = "git.collinwebdesigns.de";
  };

  patches = [
    ./remove-cpm.patch
  ];

  preConfigure = "cd src";

  installPhase = ''
    mkdir -p $out/bin
    mv gridd-unlock-patcher $out/bin
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DLIEF_SRC_ADDED=TRUE"
    "-DLIEF_SRC_SOURCE_DIR=${lief.src}"
  ];
}

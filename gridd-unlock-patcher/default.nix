{
  stdenv,
  fetchFromGitLab,
  cmake,
  pkg-config,
  lief
}:
stdenv.mkDerivation rec {
  pname = "gridd-unlock-patcher";
  version = "0.2";

  src = fetchFromGitLab {
    owner = "oscar.krause";
    repo = pname;
    rev = "010b21ea6fa64a5fcab5421854cfdfbc491b6d89";
    sha256 = "sha256-qJJT/9NVT1okLOBdbpLJETKMPheZYnEsZ2kDfJcJ2Os=";
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

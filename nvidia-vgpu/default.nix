/*
 Copyright (c) 2003-2024 Eelco Dolstra and the Nixpkgs/NixOS contributors

 Original source code:
 https://github.com/NixOS/nixpkgs/blob/54fee3a7e34a613aabc6dece34d5b7993183369c/pkgs/os-specific/linux/nvidia-x11/generic.nix
*/
{ version
, sha256
, openSha256 ? null # TODO: nvidia-open support
, settingsSha256 ? null
, settingsVersion ? version
, persistencedSha256 ? null
, persistencedVersion ? version
, vgpuPatcher ? null
, patcherArgs ? ""
, gridVersion
, zipFilename
, linuxSha256 # Linux guest driver SHA256
, useGLVND ? true
, useProfiles ? true
, preferGtk2 ? false
, settings32Bit ? false
, useSettings ? true
, usePersistenced ? true
, ibtSupport ? false
, guest ? false
, merged ? false
, # don't include the bundled 32-bit libraries on 64-bit platforms
  disable32Bit ? false
, # Whether to extract the GSP firmware
  firmware ? openSha256 != null

, prePatch ? null
, postPatch ? null
, patchFlags ? null
, patches ? [ ]
, preInstall ? null
, postInstall ? null
, broken ? false
, brokenOpen ? broken

, inputs
, kernel ? config.boot.kernelPackages.kernel
, pkgs
, lib
, config
}:

with lib;

assert useSettings -> settingsSha256 != null;
assert usePersistenced -> persistencedSha256 != null;

let
  vgpuCfg = config.hardware.nvidia.vgpu;

  patcher = if vgpuPatcher == null then null else (vgpuPatcher src);

  requireNvidiaFile = { name, ... }@args: pkgs.requireFile (args // rec {
    url = "https://www.nvidia.com/object/vGPU-software-driver.html";
    message = ''
      Unfortunately, we cannot download file ${name} automatically.
      Please go to ${url} to download it yourself or ask the vGPU Discord community
      for support (https://discord.com/invite/5rQsSV3Byq). Add it to the Nix store
      using either
        nix-store --add-fixed sha256 ${name}
      or
        nix-prefetch-url --type sha256 file:///path/to/${name}
    '';
  });
  getDriver = {name ? "", url ? "", sha256 ? null, zipSha256, linuxSha256, gridVersion, curlOptsList ? []}@args: let
      sha256 = if args.sha256 != null then args.sha256 else if guest && !(lib.hasSuffix ".zip" args.name) then linuxSha256 else zipSha256;
      name = if args.name != "" then args.name else
        if !guest && sha256 != args.sha256 then zipFilename
        else "NVIDIA-Linux-x86_64-${version}-${if guest then "grid" else "vgpu-kvm"}.run";
      url = if args.url != "" then args.url else if guest && args.name == "" && args.sha256 == null
        then "https://storage.googleapis.com/nvidia-drivers-us-public/GRID/vGPU${gridVersion}/${name}" else null;
    in
      if (lib.hasSuffix ".zip" name) && sha256 != zipSha256 then
        throw "The .run file was expected as the source of the NVIDIA vGPU driver due to a overriden hash, got a .zip GRID archive instead"
      else if (lib.hasSuffix ".run" name) && sha256 == zipSha256 then
        throw ''
          Please specify the correct SHA256 hash of the NVIDIA vGPU driver in `hardware.nvidia.vgpu.driverSource.sha256`
          (for example with `nix hash file --type sha256 /path/to/${name}`)
        ''
      else

      if url == null then
        (requireNvidiaFile { inherit name sha256; })
      else
        (pkgs.fetchurl { inherit name url sha256 curlOptsList; });

  getNixpkgsFile = path: (if builtins.hasAttr "nixpkgs" inputs
    then inputs.nixpkgs else <nixpkgs>) + path;

  # TODO: use graphics-related libraries for merged drivers only
  libPathFor = pkg: lib.makeLibraryPath (with pkg; [
    libdrm
    xorg.libXext
    xorg.libX11
    xorg.libXv
    xorg.libXrandr
    xorg.libxcb
    zlib
    stdenv.cc.cc
    wayland
    mesa
    libGL
    openssl
    dbus # for nvidia-powerd
  ]);

  src = getDriver {
    inherit (vgpuCfg.driverSource) name url sha256 curlOptsList;
    inherit linuxSha256 gridVersion;
    zipSha256 = sha256;
  };

  self = pkgs.stdenv.mkDerivation {
    name = "nvidia-vgpu-${version}-${kernel.version}";

    builder = ./builder.sh;

    inherit src patcher patcherArgs;
    inherit prePatch postPatch patchFlags;
    inherit preInstall postInstall;
    inherit version useGLVND useProfiles;
    inherit patches guest;

    postFixup = optionalString (!guest) ''
      # wrap sriov-manage
      wrapProgram $bin/bin/sriov-manage \
        --set PATH ${lib.makeBinPath (with pkgs; [
          coreutils
          pciutils
          gawk
        ])}
    '';

    system = if
      lib.elem "x86_64" pkgs.stdenv.hostPlatform.system
      then pkgs.stdenv.hostPlatform.system
      else throw "nvidia-vgpu does not support platform ${pkgs.stdenv.hostPlatform.system}";

    i686bundled = !disable32Bit && (merged || guest);
    guiBundled = merged || guest;

    outputs = [ "out" "bin" ]
      ++ optional (!disable32Bit && (merged || guest)) "lib32"
      ++ optional firmware "firmware";
    outputDev = "bin";

    kernel = kernel.dev;
    kernelVersion = kernel.modDirVersion;

    makeFlags = kernel.makeFlags ++ [
      "IGNORE_PREEMPT_RT_PRESENCE=1"
      "NV_BUILD_SUPPORTS_HMM=1"
      "SYSSRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/source"
      "SYSOUT=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    ];

    hardeningDisable = [ "pic" "format" ];

    dontStrip = true;
    dontPatchELF = true;

    libPath = libPathFor pkgs;
    libPath32 = optionalString (!disable32Bit && (merged || guest)) (libPathFor pkgs.pkgsi686Linux);

    buildInputs = optional (!guest) pkgs.pciutils;
    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.perl
      pkgs.nukeReferences
      pkgs.which
      pkgs.libarchive
      pkgs.jq
      kernel.moduleBuildDependencies
    ] ++ optional (!guest) pkgs.bbe;

    disallowedReferences = [ kernel.dev ];

    passthru =
      let
        fetchFromGithubOrNvidia = { owner, repo, rev, ... }@args:
          let
            args' = builtins.removeAttrs args [ "owner" "repo" "rev" ];
            baseUrl = "https://github.com/${owner}/${repo}";
          in
          pkgs.fetchzip (args' // {
            urls = [
              "${baseUrl}/archive/${rev}.tar.gz"
              "https://download.nvidia.com/XFree86/${repo}/${repo}-${rev}.tar.bz2"
            ];
            # github and nvidia use different compression algorithms,
            #  use an invalid file extension to force detection.
            extension = "tar.??";
          });
      in
      {
        #open = null; # TODO: nvidia-open support
        settings =
          if useSettings then
            (if settings32Bit then pkgs.pkgsi686Linux.callPackage else pkgs.callPackage)
              (import (getNixpkgsFile "/pkgs/os-specific/linux/nvidia-x11/settings.nix") self settingsSha256)
              {
                withGtk2 = preferGtk2;
                withGtk3 = !preferGtk2;
                fetchFromGitHub = fetchFromGithubOrNvidia;
              } else { };
        persistenced =
          if usePersistenced then
            mapNullable
              (hash: pkgs.callPackage
              (import (getNixpkgsFile "/pkgs/os-specific/linux/nvidia-x11/persistenced.nix") self hash) {
                fetchFromGitHub = fetchFromGithubOrNvidia;
              })
              persistencedSha256
          else { };
        fabricmanager = (throw ''
          NVIDIA datacenter drivers are not compatible with vGPU drivers.
          Did you set `hardware.nvidia.datacenter.enable` to `true`?
        '');
        inherit persistencedVersion settingsVersion;
        compressFirmware = false;
        ibtSupport = ibtSupport || (lib.versionAtLeast version "530");
        vgpuPatcher = patcher;
      };

    meta = {
      platforms = [ "x86_64-linux" ]; # for compatibility with persistenced.nix and settings.nix
      priority = 4; # resolves collision with xorg-server's "lib/xorg/modules/extensions/libglx.so"
    };
  };

in
self

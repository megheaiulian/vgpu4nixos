{ inputs ? {}, guest ? false }:
{ pkgs, lib, config, ... }:

with lib;

let
  callPackage = package: args: (if builtins.hasAttr "nixpkgs" inputs then
    (inputs.nixpkgs.legacyPackages."x86_64-linux")
  else
    (import <nixpkgs> {})).callPackage package args;
  generic = kernel: args: callPackage ./nvidia-vgpu (args //
    { inherit config kernel guest; nixpkgs = (inputs.nixpkgs or <nixpkgs>); });

  tryGetPatcherConf = option: default:
    if (builtins.hasAttr option config.hardware.nvidia.vgpu.patcher)
    then config.hardware.nvidia.vgpu.patcher.${option} else default;

  merged = !guest && (lib.elem "nvidia" config.services.xserver.videoDrivers);

  makePatcher = { patcherSha256, patcherRev,
    generalSha256, generalVersion, # General driver (for general-merge)
    linuxSha256, linuxGuest, # Linux guest driver (for grid, grid-merge)
    windowsSha256, windowsGuestFilename, # Windows guest driver (for wsys)
    gridVersion }@args:
    let
      args' = (builtins.removeAttrs args [ "patcherRev" "patcherSha256" ]) // {
        rev = patcherRev;
        sha256 = patcherSha256;
        # Linux guest and host drivers always have the same major and minor
        version = lib.versions.majorMinor linuxGuest;
        fetchGuests = tryGetPatcherConf "enablePatcherCmd" false;
        extraVGPUProfiles = tryGetPatcherConf "copyVGPUProfiles" {};
      };
    in
    vgpuDriver: callPackage ./patcher (args' // { inherit vgpuDriver merged; });

  getPackages = kernel:
  let
    makeName = version: (if guest then "grid" else "vgpu")
      + "_" + (builtins.replaceStrings ["."] ["_"] version);
    makePackage = gridVersion: args:
      let
        argsMakePatcher = { inherit (args) patcherSha256 patcherRev
          generalSha256 generalVersion linuxSha256 linuxGuest
          windowsSha256 windowsGuestFilename; inherit gridVersion; };
        vgpuPatcher = makePatcher argsMakePatcher;
        args' = lib.filterAttrs (n: _: !(builtins.hasAttr n argsMakePatcher)) args;
      in generic kernel (args'
        // { inherit (args) linuxSha256; inherit gridVersion merged;
          settingsVersion = args.generalVersion; persistencedVersion = args.generalVersion; }
        // (optionalAttrs guest { version = args.linuxGuest; })
        // (optionalAttrs config.hardware.nvidia.vgpu.patcher.enable { inherit vgpuPatcher patcherArgs; }));

    patcherArgs = with config.hardware.nvidia.vgpu.patcher.options;
      builtins.concatStringsSep " " (optional (!doNotForceGPLLicense)
      "--enable-nvidia-gpl-for-experimenting --force-nvidia-gpl-I-know-it-is-wrong"
      # TODO: nvidia-open support
      /*
      ++ optional (!guest && !doNotPatchNvidiaOpen) "--nvoss"
      */
      ++ optional (!guest && remapP40ProfilesToV100D) "--remap-p2v"
      ++ extra ++ [ (if merged then "general-merge" else if guest then "grid" else "vgpu-kvm") ]);
  in mapAttrs' (version: data:
    nameValuePair (makeName version) (makePackage version data)) (import ./versions.nix);

  overlayNvidiaPackages = func: (self: super: {
   linuxKernel = super.linuxKernel // {
     packagesFor = kernel: (super.linuxKernel.packagesFor kernel).extend
     (_: super': {
       nvidiaPackages = super'.nvidiaPackages.extend (_: _: func kernel);
     });
   };
  });
in
{
  imports = [
    # Load host- or guest-specific options and config
    (if guest then ./guest.nix else ./host.nix)
  ];
  options = {
    hardware.nvidia.vgpu = {
      patcher = {
        enable = mkEnableOption "driver patching using vGPU-Unlock-patcher";
        options.doNotForceGPLLicense = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Disables a kernel module hack that makes the driver usable on higher kernel versions.
            Turn it on if you have patched the kernel for support. Has no effect starting from 17.2.
          '';
        };
        # TODO: 17.x
        /* options.doNotPatchNvidiaOpen = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Will not patch open source NVIDIA kernel modules. For 17.x releases only.
            Enabled by default as a reinsurance against the possibility that you use open source drivers without even knowing it
            (for example, by accidentally setting `hardware.nvidia.open = true;`).
          '';
        }; */
        options.extra = mkOption {
          type = types.listOf types.str;
          default = [];
          example = [ "--test-dmabuf-export" ];
          description = "Extra flags to pass to the patcher.";
        };
      };
      driverSource.name = mkOption {
        type = types.str;
        default = "";
        example = "NVIDIA-GRID-Linux-KVM-535.129.03-537.70.zip";
        description = "The name of the driver file.";
      };
      driverSource.url = mkOption {
        type = types.nullOr types.str;
        default = "";
        example = "https://drive.google.com/uc?export=download&id=n0TaR34LliNKG3t7h4tYOuR5elF";
        description = "The address of your local server from which to download the driver, if any.";
      };
      driverSource.sha256 = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "sha256-tFgDf7ZSIZRkvImO+9YglrLimGJMZ/fz25gjUT0TfDo=";
        description = ''
          SHA256 hash of your driver. Note that anything other than null will automatically require a .run file, not a .zip GRID archive.
          Set the value to "" to get the correct hash (only when fetching from an HTTP(s) server).
        '';
      };
      driverSource.curlOptsList = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "-u" "admin:12345678" ];
        description = "Additional curl options, similar to curlOptsList in pkgs.fetchurl.";
      };
    };
  };
  config = {
    # Add our packages to nvidiaPackages
    nixpkgs.overlays = [ (overlayNvidiaPackages getPackages) ];
  };
}

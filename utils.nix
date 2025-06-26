{
  pkgs,
  lib,

  guest,
  merged,
  kernel,
  vgpuCfg,
  ...
}:
rec {
  # Generate command (xmlstarlet) for XML overrides to vgpuConfig.xml
  attrsToVgpuXmlCmd =
    overrides:
    lib.attrsets.foldlAttrs (
      s: n: v:
      s
      + (lib.attrsets.foldlAttrs (
        s': n': v':
        let
          vFlags =
            if builtins.isAttrs v' then
              # yes, three nested loops
              (lib.attrsets.foldlAttrs (
                ss: nn: vv:
                ss + " -u '/vgpuconfig/vgpuType[@id=\"${n}\"]/${n'}/@${nn}' -v ${vv}"
              ) "" v')
            else
              " -u '/vgpuconfig/vgpuType[@id=\"${n}\"]/${n'}/text()' -v ${builtins.toString v'}";
        in
        s' + vFlags
      ) "" v)
    ) "xmlstarlet ed -P" overrides;

  genVgpuXmlCmd =
    overridesCfg: attrsToVgpuXmlCmd (
      lib.mapAttrs (
        _: v:
        (lib.optionalAttrs (v.vramAllocation != null) (
          let
            # a little bit modified version of
            # https://discord.com/channels/829786927829745685/1162008346551926824/1171897739576086650
            profSizeDec = 1048576 * v.vramAllocation;
            fbResDec = 134217728 + ((v.vramAllocation - 1024) * 65536);
          in
          {
            profileSize = "0x${lib.toHexString profSizeDec}";
            framebuffer = "0x${lib.toHexString (profSizeDec - fbResDec)}";
            fbReservation = "0x${lib.toHexString fbResDec}";
          }
        ))
        // (lib.optionalAttrs (v.heads != null) { numHeads = (builtins.toString v.heads); })
        // (lib.optionalAttrs (v.display.width != null && v.display.height != null) {
          display = {
            width = (builtins.toString v.display.width);
            height = (builtins.toString v.display.height);
          };
          maxPixels = (builtins.toString (v.display.width * v.display.height));
        })
        // (lib.optionalAttrs (v.framerateLimit != null) {
          frlConfig = "0x${lib.toHexString v.framerateLimit}";
          frame_rate_limiter = if v.framerateLimit > 0 then "1" else "0";
        })
        // v.xmlConfig
      ) overridesCfg
    );

  vgpuXmlCmd = genVgpuXmlCmd vgpuCfg.patcher.profileOverrides;

  # Creates overlay that modifies config.kernelPackages.nvidiaPackages
  overlayNvidiaPackages =
    args:
    (self: super: {
      linuxKernel = super.linuxKernel // {
        packagesFor =
          kernel:
          (super.linuxKernel.packagesFor kernel).extend (
            _: super': {
              nvidiaPackages = super'.nvidiaPackages.extend (_: _: args);
            }
          );
      };
    });

  requireNvidiaFile =
    { name, ... }@args:
    pkgs.requireFile (
      args
      // rec {
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
      }
    );

  # Retrieves driver source
  getDriver =
    {
      name ? "",
      url ? "",
      sha256 ? null,
      zipFilename,
      zipSha256,
      guestSha256,
      version,
      gridVersion,
      curlOptsList ? [ ],
    }@args:
    let
      # driver hash
      sha256 =
        if args.sha256 != null then
          args.sha256
        else if guest && !(lib.hasSuffix ".zip" args.name) then
          guestSha256
        else
          zipSha256;
      # driver filename
      name =
        if args.name != "" then
          args.name
        else if !guest && sha256 != args.sha256 then
          zipFilename
        else
          "NVIDIA-Linux-x86_64-${version}-${if guest then "grid" else "vgpu-kvm"}.run";
      # driver location (local or remote)
      url =
        if args.url != "" then
          args.url
        else if guest && args.name == "" && args.sha256 == null then
          "https://storage.googleapis.com/nvidia-drivers-us-public/GRID/vGPU${gridVersion}/${name}"
        else
          null;
    in
    (
      if url == null then
        (requireNvidiaFile { inherit name sha256; })
      else
        (pkgs.fetchurl {
          inherit
            name
            url
            sha256
            curlOptsList
            ;
        })
    );

  griddUnlock = pkgs.callPackage ./gridd-unlock-patcher {};
  patcherArgs =
    with vgpuCfg.patcher;
    builtins.concatStringsSep " " (
      lib.optionals (!options.doNotForceGPLLicense) [
        "--enable-nvidia-gpl-for-experimenting"
        "--force-nvidia-gpl-I-know-it-is-wrong"
      ]
      ++ lib.optional (options.remapP40ProfilesToV100D or false) "--remap-p2v"
      ++ options.extra
      ++ [
        (
          if merged then
            "general-merge"
          else if guest then
            "grid"
          else
            "vgpu-kvm"
        )
      ]
    );

  # Used to create driver derivations
  mkVgpuDriver =
    args:
    let
      version = if guest then args.guestVersion else args.version;
      args' =
        {
          inherit version;
          vgpuPatcher = if vgpuCfg.patcher.enable then args.vgpuPatcher else null;
          settingsVersion = args.generalVersion;
          persistencedVersion = args.generalVersion;
        }
        // (builtins.removeAttrs args [
          "version"
          "guestVersion"
          "sha256"
          "guestSha256"
          "openSha256"
          "generalVersion"
          "gridVersion"
          "zipFilename"
          "vgpuPatcher"
        ])
        // (lib.optionalAttrs (vgpuCfg.griddUnlock.enable or false) {
          postPatch = (args.postPatch or "")
            + ''
              ${griddUnlock}/bin/gridd-unlock-patcher \
                -g nvidia-gridd \
                -c ${vgpuCfg.griddUnlock.rootCaFile}
            '';
        });
      src = getDriver {
        inherit (vgpuCfg.driverSource)
          name
          url
          sha256
          curlOptsList
          ;
        inherit (args) guestSha256 gridVersion zipFilename;
        inherit version;
        zipSha256 = args.sha256;
      };
    in
    pkgs.callPackage (import ./nvidia-vgpu args') {
      inherit
        kernel
        src
        guest
        merged
        patcherArgs
        ;
    };

  # Used to create patcher derivations
  mkVgpuPatcher =
    args: vgpuDriver:
    pkgs.callPackage ./vgpu-unlock-patcher (
      args
      // {
        inherit vgpuDriver merged;
        extraVGPUProfiles = vgpuCfg.patcher.copyVGPUProfiles or { };
        fetchGuests = vgpuCfg.patcher.enablePatcherCmd or false;
      }
    );
}

{ pkgs, lib, config, inputs, ... }@args:

with lib;

let
  nvidiaCfg = config.hardware.nvidia;

  # https://gist.github.com/corpix/f761c82c9d6fdbc1b3846b37e1020e11#file-numbers-nix-L58-L71
  decToHex =
    let
      intToHex = [
        "0" "1" "2" "3" "4" "5" "6" "7" "8" "9"
        "A" "B" "C" "D" "E" "F"
      ];
      toHex' = q: a:
        if q > 0
        then (toHex'
          (q / 16)
          ((elemAt intToHex (mod q 16)) + a))
        else a;
    in
      v: toHex' v "";

  genXmlstarletCmd = overrides: lib.attrsets.foldlAttrs (s: n: v:
    s + (lib.attrsets.foldlAttrs (s': n': v': let
      vFlags = if builtins.isAttrs v' then
          # yes, three nested loops
          (lib.attrsets.foldlAttrs(ss: nn: vv: ss + " -u '/vgpuconfig/vgpuType[@id=\"${n}\"]/${n'}/@${nn}' -v ${vv}") "" v')
        else
          " -u '/vgpuconfig/vgpuType[@id=\"${n}\"]/${n'}/text()' -v ${builtins.toString v'}";
    in s' + vFlags) "" v)
    ) "xmlstarlet ed -P" overrides;

  xmlstarletCmd = genXmlstarletCmd (lib.mapAttrs (_: v:
    (optionalAttrs (v.vramAllocation != null) (let
      # a little bit modified version of
      # https://discord.com/channels/829786927829745685/1162008346551926824/1171897739576086650
      profSizeDec = 1048576 * v.vramAllocation;
      fbResDec = 134217728 + ((v.vramAllocation - 1024) * 65536);
    in {
      profileSize = "0x${decToHex profSizeDec}";
      framebuffer = "0x${decToHex (profSizeDec - fbResDec)}";
      fbReservation = "0x${decToHex fbResDec}";
    }))
    // (optionalAttrs (v.heads != null) { numHeads = (builtins.toString v.heads); })
    // (optionalAttrs (v.display.width != null && v.display.height != null) {
      display = {
        width = (builtins.toString v.display.width);
        height = (builtins.toString v.display.height);
      };
      maxPixels = (builtins.toString (v.display.width * v.display.height));
    })
    // (optionalAttrs (v.framerateLimit != null) {
      frlConfig = "0x${decToHex v.framerateLimit}";
      frame_rate_limiter = if v.framerateLimit > 0 then "1" else "0";
    })
    // v.xmlConfig
  ) nvidiaCfg.vgpu.patcher.profileOverrides);
in
{
  options = {
    hardware.nvidia.vgpu = {
      patcher = {
        options.remapP40ProfilesToV100D = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Allows Pascal GPUs which use profiles from P40 to use latest guest drivers. Otherwise you're stuck with 16.x drivers. Not
            required for Maxwell GPUs. Only for 17.x releases.
          '';
        };
        copyVGPUProfiles = mkOption {
          type = types.attrs;
          default = {};
          example = {
            "5566:7788" = "1122:3344";
          };
          description = ''
            Adds vcfgclone lines to the patcher. For more information, see the vGPU-Unlock-Patcher README.
            The value in the example above is equivalent to vcfgclone 0x1122 0x3344 0x5566 0x7788.
          '';
        };
        profileOverrides = mkOption {
          type = (types.attrsOf (types.submodule {
            options = {
              vramAllocation = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "vRAM allocation in megabytes. `profileSize`, `framebuffer` and `fbReservation` will be calculated automatically.";
              };
              heads = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Maximum allowed virtual monitors (heads).";
              };
              enableCuda = mkOption {
                type = types.nullOr types.bool;
                default = null;
                description = "Whenether to enable CUDA support.";
              };
              display.width = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Display width in pixels. `maxPixels` will be calculated automatically.";
              };
              display.height = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Display height in pixels. `maxPixels` will be calculated automatically.";
              };
              framerateLimit = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Cap FPS to specific value. `0` will disable limit.";
              };
              xmlConfig = mkOption {
                type = types.attrs;
                default = {};
                example = {
                  eccSupported = "1";
                  license = "NVS";
                };
                description = ''
                  Additional XML configuration.
                  `{ a = "b"; }` is equal to `<a>b</a>`, `{ a = { b = "d"; c = "e"; }; }` is equal to `<a b="d" c="e"/>`.
                '';
              };
            };
          }));
          default = {};
          description = "Allows to edit vGPU profiles' properties like vRAM allocation, maximum display size, etc.";
        };
        enablePatcherCmd = mkOption {
          type = types.bool;
          default = false;
          description = "Adds the vGPU-Unlock-patcher script (renamed to nvidia-vup) to environment.systemPackages for convenience.";
        };
      };
    };
  };
  config = mkMerge [
    (mkIf (builtins.hasAttr "vgpuPatcher" nvidiaCfg.package) {
      systemd.services.nvidia-vgpud = {
        description = "NVIDIA vGPU Daemon";
        wants = [ "syslog.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "forking";
          ExecStart = "${lib.getBin nvidiaCfg.package}/bin/nvidia-vgpud";
          ExecStopPost = "${pkgs.coreutils}/bin/rm -rf /var/run/nvidia-vgpud";
        };
      };
      systemd.services.nvidia-vgpu-mgr = {
        description = "NVIDIA vGPU Manager Daemon";
        wants = [ "syslog.target" ];
        wantedBy = [ "multi-user.target" ];
        requires = [ "nvidia-vgpud.service" ];
        after = [ "nvidia-vgpud.service" ];

        serviceConfig = {
          Type = "forking";
          KillMode = "process";
          ExecStart = "${lib.getBin nvidiaCfg.package}/bin/nvidia-vgpu-mgr";
          ExecStopPost = "${pkgs.coreutils}/bin/rm -rf /var/run/nvidia-vgpu-mgr";
        };
      };
      systemd.services.nvidia-xid-logd = {
        enable = false; # disabled by default
        description = "NVIDIA Xid Log Daemon";
        wantedBy = [ "multi-user.target" ];
        after = [ "nvidia-vgpu-mgr.service" ];

        serviceConfig = {
          Type = "forking";
          ExecStart = "${lib.getBin nvidiaCfg.package}/bin/nvidia-xid-logd";
          RuntimeDirectory = "nvidia-xid-logd";
        };
      };

      environment.systemPackages = lib.optional (nvidiaCfg.vgpu.patcher.enablePatcherCmd) nvidiaCfg.package.vgpuPatcher;

      environment.etc."nvidia/vgpu/vgpuConfig.xml".source =
        (if nvidiaCfg.vgpu.patcher.enable && nvidiaCfg.vgpu.patcher.profileOverrides != {}
        then
          (pkgs.runCommand "vgpuconfig-override" { nativeBuildInputs = [ pkgs.xmlstarlet ]; } ''
            mkdir -p $out
            ${xmlstarletCmd} ${nvidiaCfg.package + /vgpuConfig.xml} > $out/vgpuConfig.xml
          '')
        else
          nvidiaCfg.package) + /vgpuConfig.xml;
    })

    # The absence of the "nvidia" element in the config.services.xserver.videoDrivers option (to use non-merged drivers in our case)
    # will result in the driver not being installed properly without this fix
    (mkIf ((builtins.hasAttr "vgpuPatcher" nvidiaCfg.package) && !(lib.elem "nvidia" config.services.xserver.videoDrivers)) {
      boot = {
        blacklistedKernelModules = [ "nouveau" "nvidiafb" ];
        extraModulePackages = [ nvidiaCfg.package.bin ]; # TODO: nvidia-open support
        kernelModules = [ "nvidia" "nvidia-vgpu-vfio" ];
      };
      environment.systemPackages = [ nvidiaCfg.package.bin ];

      # taken from nixpkgs
      systemd.tmpfiles.rules = lib.mkIf config.virtualisation.docker.enableNvidia [ "L+ /run/nvidia-docker/bin - - - - ${nvidiaCfg.package.bin}/origBin" ];
    })
  ];
}

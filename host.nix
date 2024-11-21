{ pkgs, lib, config, inputs, ... }@args:

with lib;

{
  options = {
    hardware.nvidia.vgpu = {
      patcher = {
        # TODO: 17.x
        /* options.remapP40ProfilesToV100D = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Allows Pascal GPUs which use profiles from P40 to use latest guest drivers. Otherwise you're stuck with 16.x drivers. Not
            required for Maxwell GPUs. Only for 17.x releases.
        '';
        }; */
        copyVGPUProfiles = mkOption {
          default = {};
          type = types.attrs;
          example = {
            "5566:7788" = "1122:3344";
          };
          description = ''
            Adds vcfgclone lines to the patcher. For more information, see the vGPU-Unlock-Patcher README.
            The value in the example above is equivalent to vcfgclone 0x1122 0x3344 0x5566 0x7788.
          '';
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
    (mkIf (builtins.hasAttr "vgpuPatcher" config.hardware.nvidia.package) {
      systemd.services.nvidia-vgpud = {
        description = "NVIDIA vGPU Daemon";
        wants = [ "syslog.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "forking";
          ExecStart = "${lib.getBin config.hardware.nvidia.package}/bin/nvidia-vgpud";
          ExecStopPost = "${pkgs.coreutils}/bin/rm -rf /var/run/nvidia-vgpud";
        };
      };
      systemd.services.nvidia-vgpu-mgr = {
        description = "NVIDIA vGPU Manager Daemon";
        wants = [ "syslog.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "forking";
          KillMode = "process";
          ExecStart = "${lib.getBin config.hardware.nvidia.package}/bin/nvidia-vgpu-mgr";
          ExecStopPost = "${pkgs.coreutils}/bin/rm -rf /var/run/nvidia-vgpu-mgr";
        };
      };

      environment.systemPackages = with config.hardware.nvidia; lib.optional (vgpu.patcher.enablePatcherCmd) package.vgpuPatcher;
      environment.etc."nvidia/vgpu/vgpuConfig.xml".source = config.hardware.nvidia.package + /vgpuConfig.xml;
    })

    # The absence of the "nvidia" element in the config.services.xserver.videoDrivers option (to use non-merged drivers in our case)
    # will result in the driver not being installed properly without this fix
    (mkIf ((builtins.hasAttr "vgpuPatcher" config.hardware.nvidia.package) && !(lib.elem "nvidia" config.services.xserver.videoDrivers)) {
      boot = {
        blacklistedKernelModules = [ "nouveau" "nvidiafb" ];
        extraModulePackages = [ config.hardware.nvidia.package.bin ]; # TODO: nvidia-open support
        kernelModules = [ "nvidia" "nvidia-vgpu-vfio" ];
      };
      environment.systemPackages = [ config.hardware.nvidia.package.bin ];

      # taken from nixpkgs
      systemd.tmpfiles.rules = lib.mkIf config.virtualisation.docker.enableNvidia [ "L+ /run/nvidia-docker/bin - - - - ${config.hardware.nvidia.package.bin}/origBin" ];
    })
  ];
}

{
  pkgs,
  lib,
  config,
  ...
}:

let
  vgpuCfg = config.hardware.nvidia.vgpu;
in
{
  options = {
    hardware.nvidia.vgpu.griddUnlock = {
      enable = lib.mkEnableOption "certificate patching using gridd-unlock-patcher";
      rootCaFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/home/user/Downloads/root_certificate.pem";
        description = "Path to root certificate authority of licensing server.";
      };
    };
  };
  config = lib.mkIf (builtins.hasAttr "vgpuPatcher" config.hardware.nvidia.package) {
    assertions = [
      {
        assertion = (vgpuCfg.griddUnlock.enable -> vgpuCfg.griddUnlock.rootCaFile != null);
        message = ''
          `hardware.nvidia.vgpu.griddUnlock.rootCaFile` must be defined when `gridd-unlock-patcher` is enabled
        '';
      }
      {
        assertion = (lib.versionAtLeast config.hardware.nvidia.package.version "570.124.03");
        message = "`hardware.nvidia.vgpu.griddUnlock` is supported on 18.x releases only";
      }
    ];
    systemd.services.nvidia-gridd = {
      description = "NVIDIA Grid Daemon";
      wants = [
        "network-online.target"
        "nvidia-persistenced.service"
      ];
      after = [
        "systemd-resolved.service"
        "network-online.target"
        "nvidia-persistenced.service"
      ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        LD_LIBRARY_PATH = "${lib.getOutput "out" config.hardware.nvidia.package}/lib";
      };
      serviceConfig = {
        Type = "forking";
        # make sure /var/lib/nvidia exists, otherwise service will fail
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/lib/nvidia";
        ExecStart = "${lib.getBin config.hardware.nvidia.package}/bin/nvidia-gridd";
        ExecStopPost = "${pkgs.coreutils}/bin/rm -rf /var/run/nvidia-gridd";
      };
      restartIfChanged = false;
    };
    systemd.services.nvidia-topologyd = {
      description = "NVIDIA Topology Daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${lib.getBin config.hardware.nvidia.package}/bin/nvidia-topologyd";
      };
      restartIfChanged = false;
    };

    environment.etc = {
      "nvidia/gridd.conf.template".source = config.hardware.nvidia.package + /gridd.conf.template;
      "nvidia/nvidia-topologyd.conf.template".source =
        config.hardware.nvidia.package + /nvidia-topologyd.conf.template;
    };
    hardware.nvidia = {
      # nvidia modeset MUST be enabled in order to work correctly
      modesetting.enable = lib.mkDefault true;

      # nixpkgs requires to define these options now, but in our case they are useless
      open = lib.mkDefault false;
      gsp.enable = lib.mkDefault false;
    };
  };
}

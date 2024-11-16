{ pkgs, lib, config, inputs, ... }@args:

with lib;

{
  config = mkIf (builtins.hasAttr "vgpuPatcher" config.hardware.nvidia.package) {
    systemd.services.nvidia-gridd = {
      description = "NVIDIA Grid Daemon";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = { LD_LIBRARY_PATH = "${getOutput "out" config.hardware.nvidia.package}/lib"; };

      serviceConfig = {
        Type = "forking";
        # make sure /var/lib/nvidia exists, otherwise service will fail
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/lib/nvidia";
        ExecStart = "${getBin config.hardware.nvidia.package}/bin/nvidia-gridd";
        ExecStopPost = "${pkgs.coreutils}/bin/rm -rf /var/run/nvidia-gridd";
      };
    };
    systemd.services.nvidia-topologyd = {
      description = "NVIDIA Topology Daemon";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "forking";
        ExecStart = "${getBin config.hardware.nvidia.package}/bin/nvidia-topologyd";
      };
    };

    # nvidia modeset MUST be enabled in order to work correctly
    hardware.nvidia.modesetting.enable = true;
    environment.etc = {
      "nvidia/gridd.conf.template".source = config.hardware.nvidia.package + /gridd.conf.template;
      "nvidia/nvidia-topologyd.conf.template".source = config.hardware.nvidia.package + /nvidia-topologyd.conf.template;
    };
  };
}

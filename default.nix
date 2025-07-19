{
  guest ? false
}:
{
  pkgs,
  lib,
  config,
  ...
}@args:

let
  vgpuCfg = config.hardware.nvidia.vgpu;
  merged = !guest && (lib.elem "nvidia" config.services.xserver.videoDrivers);
  
  utils = import ./utils.nix
    {
      inherit (config.boot.kernelPackages) kernel;
      inherit pkgs lib guest merged vgpuCfg;
    };

  pref = if guest then "grid" else "vgpu";
  vgpuNixpkgsPkgs = with utils; {
    inherit mkVgpuDriver mkVgpuPatcher;

    "${pref}_18_4" = mkVgpuDriver {
      version = "570.172.07";
      sha256 = "sha256-gnfbx+EHgabI2ZrsvunsS4LBCZnfLQI0yZRpAzqXFIw=";
      guestVersion = "570.172.08";
      guestSha256 = "sha256-4oPQAXl2ScAi0D1EfR6wAltZlfhb9e08i1jsiJT0j8w=";
      openSha256 = null;
      generalVersion = "570.169";
      settingsSha256 = "sha256-0E3UnpMukGMWcX8td6dqmpakaVbj4OhhKXgmqz77XZc=";
      usePersistenced = false;
      gridVersion = "18.4";
      zipFilename = "NVIDIA-GRID-Linux-KVM-570.172.07-570.172.08-573.48.zip";
      vgpuPatcher = null;
    };
    "${pref}_18_3" = mkVgpuDriver {
      version = "570.158.02";
      sha256 = "sha256-BRPEsOGk4oyoJr/fSlYCZfzqGaK685FGWswQIBbBqX8=";
      guestVersion = "570.158.01";
      guestSha256 = "sha256-EsvHFO/dtTKWvtGByBlk6201tnvpYCtDS6ky+6S6EtI=";
      openSha256 = null;
      generalVersion = "570.153.02";
      settingsSha256 = "sha256-5m6caud68Owy4WNqxlIQPXgEmbTe4kZV2vZyTWHWe+M=";
      usePersistenced = false;
      gridVersion = "18.3";
      zipFilename = "NVIDIA-GRID-Linux-KVM-570.158.02-570.158.01-573.39.zip";
      vgpuPatcher = null;
    };
    "${pref}_18_2" = mkVgpuDriver {
      version = "570.148.06";
      sha256 = "sha256-9ZRgjbkR52iJgLd7e1hX9ShAZukdstS33Zmy/V4tPKo=";
      guestVersion = "570.148.08";
      guestSha256 = "sha256-m2qRCeu6BJel2ctbDWVPcyD9WFl35hngEN5quF3Ry4w=";
      openSha256 = null;
      generalVersion = "570.144";
      settingsSha256 = "sha256-VcCa3P/v3tDRzDgaY+hLrQSwswvNhsm93anmOhUymvM=";
      usePersistenced = false;
      gridVersion = "18.2";
      zipFilename = "NVIDIA-GRID-Linux-KVM-570.148.06-570.148.08-573.07.zip";
      vgpuPatcher = null;
    };
    "${pref}_18_1" = mkVgpuDriver {
      version = "570.133.10";
      sha256 = "sha256-ybQkOshVruMtKUWqi7lYnO3zrclB2W/O2RZZ5350Tec=";
      guestVersion = "570.133.20";
      guestSha256 = "sha256-3VM9X188aiVKUPDNHgT0NW072TD28che5ElBkY7wYVQ=";
      openSha256 = null;
      generalVersion = "570.133.07";
      settingsSha256 = "sha256-XMk+FvTlGpMquM8aE8kgYK2PIEszUZD2+Zmj2OpYrzU=";
      usePersistenced = false;
      gridVersion = "18.1";
      zipFilename = "NVIDIA-GRID-Linux-KVM-570.133.10-570.133.20-572.83.zip";
      vgpuPatcher = null;
    };
    "${pref}_18_0" = mkVgpuDriver {
      version = "570.124.03";
      sha256 = "sha256-g8nUKslFOmYd8ibQ+5v21mrZeBqNhiQPkPZKPUfCwAA=";
      guestVersion = "570.124.06";
      guestSha256 = "sha256-zqLM9cICZvSnTSWyvn8VMga6nTEQ0KiZqe9mFWIzKJU=";
      openSha256 = null;
      generalVersion = "570.124.04";
      settingsSha256 = "sha256-LNL0J/sYHD8vagkV1w8tb52gMtzj/F0QmJTV1cMaso8=";
      usePersistenced = false;
      gridVersion = "18.0";
      zipFilename = "NVIDIA-GRID-Linux-KVM-570.124.03-570.124.06-572.60.zip";
      vgpuPatcher = null;
    };
    "${pref}_17_6" = mkVgpuDriver {
      version = "550.163.02";
      sha256 = "sha256-CFK1IPg9uAyEa5cA0vou47/SvobZ5DK5ap81j/AjCBQ=";
      guestVersion = "550.163.01";
      guestSha256 = "sha256-Y+FkfxvlccynuUEtkAvJR3k5xRNX/StpnmvjTHCnOGY=";
      openSha256 = null;
      generalVersion = "550.144.03";
      settingsSha256 = "sha256-ZopBInC4qaPvTFJFUdlUw4nmn5eRJ1Ti3kgblprEGy4=";
      usePersistenced = false;
      gridVersion = "17.6";
      zipFilename = "NVIDIA-GRID-Linux-KVM-550.163.02-550.163.01-553.74.zip";
      vgpuPatcher = null;
    };
    "${pref}_17_5" = mkVgpuDriver {
      version = "550.144.02";
      sha256 = "sha256-VeXJUqF82jp3wEKmCaH5VKQTS9e0gQmwkorf4GBcS8g=";
      guestVersion = "550.144.03";
      guestSha256 = "sha256-7EWHVpF6mzyhPUmASgbTJuYihUhqcNdvKDTHYQ53QFY=";
      openSha256 = null;
      generalVersion = "550.144.03";
      settingsSha256 = "sha256-ZopBInC4qaPvTFJFUdlUw4nmn5eRJ1Ti3kgblprEGy4=";
      usePersistenced = false;
      gridVersion = "17.5";
      zipFilename = "NVIDIA-GRID-Linux-KVM-550.144.02-550.144.03-553.62.zip";
      vgpuPatcher = null;
    };
    "${pref}_17_4" = mkVgpuDriver {
      version = "550.127.06";
      sha256 = "sha256-w5Oow0G8R5QDckNw+eyfeaQm98JkzsgL0tc9HIQhE/g=";
      guestVersion = "550.127.05";
      guestSha256 = "sha256-gV9T6UdjhM3fnzITfCmxZDYdNoYUeZ5Ocf9qjbrQWhc=";
      openSha256 = null;
      generalVersion = "550.127.05";
      settingsSha256 = "sha256-cUSOTsueqkqYq3Z4/KEnLpTJAryML4Tk7jco/ONsvyg=";
      persistencedSha256 = "sha256-8nowXrL6CRB3/YcoG1iWeD4OCYbsYKOOPE374qaa4sY=";
      gridVersion = "17.4";
      zipFilename = "NVIDIA-GRID-Linux-KVM-550.127.06-550.127.05-553.24.zip";
      vgpuPatcher = null;
    };
    "${pref}_17_3" = mkVgpuDriver {
      version = "550.90.05";
      sha256 = "sha256-ydNOnbhbqkO2gVaUQXsIWCZsbjw0NMEYl9iV0T01OX0=";
      guestVersion = "550.90.07";
      guestSha256 = "sha256-hR0b+ctNdXhDA6J1Zo1tYEgMtCvoBQ4jQpQvg1/Kjg4=";
      openSha256 = null;
      generalVersion = "550.90.07";
      settingsSha256 = "sha256-sX9dHEp9zH9t3RWp727lLCeJLo8QRAGhVb8iN6eX49g=";
      persistencedSha256 = "sha256-qe8e1Nxla7F0U88AbnOZm6cHxo57pnLCqtjdvOvq9jk=";
      gridVersion = "17.3";
      zipFilename = "NVIDIA-GRID-Linux-KVM-550.90.05-550.90.07-552.74.zip";
      vgpuPatcher = mkVgpuPatcher {
        version = "550.90";
        rev = "8f19e550540dcdeccaded6cb61a71483ea00d509";
        sha256 = "sha256-TyZkZcv7RI40U8czvcE/kIagpUFS/EJhVN0SYPzdNJM=";
        generalVersion = "550.90.07";
        generalSha256 = "sha256-Uaz1edWpiE9XOh0/Ui5/r6XnhB4iqc7AtLvq4xsLlzM=";
        linuxGuest = "550.90.07";
        linuxSha256 = "sha256-hR0b+ctNdXhDA6J1Zo1tYEgMtCvoBQ4jQpQvg1/Kjg4=";
        windowsGuestFilename = "552.74_grid_win10_win11_server2022_dch_64bit_international.exe";
        windowsSha256 = "sha256-UU+jbwlfg9xCie8IjPASb/gWalcEzAwzy+VAmgr0868=";
        gridVersion = "17.3";
      };
    };
    "${pref}_16_11" = mkVgpuDriver {
      version = "535.261.04";
      sha256 = "sha256-bJ0sV1gn6JVlRmbt2MYhajb1t59FPzi/ypA3CVyh9Ug=";
      guestVersion = "535.261.03";
      guestSha256 = "sha256-wkpKenOh7Rni3hDdrM3tOXnSH2JEub5H6EH0Mn1iBdc=";
      openSha256 = null;
      generalVersion = "535.216.01";
      settingsSha256 = "sha256-9PgaYJbP1s7hmKCYmkuLQ58nkTruhFdHAs4W84KQVME=";
      usePersistenced = false;
      gridVersion = "16.11";
      zipFilename = "NVIDIA-GRID-Linux-KVM-535.261.04-535.261.03-539.41.zip";
      vgpuPatcher = null;
    };
    "${pref}_16_10" = mkVgpuDriver {
      version = "535.247.02";
      sha256 = "sha256-DI/se2GQG3cwiCvIQUThFXVyGkE2JH9+rps520L+SGQ=";
      guestVersion = "535.247.01";
      guestSha256 = "sha256-WJ7faV6XDkaYjC+ElQ+3MpnHbKkR4hzqr5sohqEof+k=";
      openSha256 = null;
      generalVersion = "535.216.01";
      settingsSha256 = "sha256-9PgaYJbP1s7hmKCYmkuLQ58nkTruhFdHAs4W84KQVME=";
      usePersistenced = false;
      gridVersion = "16.10";
      zipFilename = "NVIDIA-GRID-Linux-KVM-535.247.02-535.247.01-539.28.zip";
      vgpuPatcher = null;
    };
    "${pref}_16_9" = mkVgpuDriver {
      version = "535.230.02";
      sha256 = "sha256-FMzf35R3o6bXVoAcYXrL3eBEFkQNRh96RnZ/qn5eeWs=";
      guestVersion = "535.230.02";
      guestSha256 = "sha256-7/ujzYAMNnMFOT/pV+z4dYsbMUDaWf5IoqNHDr1Pf/w=";
      openSha256 = null;
      generalVersion = "535.113.01";
      settingsSha256 = "sha256-hiX5Nc4JhiYYt0jaRgQzfnmlEQikQjuO0kHnqGdDa04=";
      usePersistenced = false;
      gridVersion = "16.9";
      zipFilename = "NVIDIA-GRID-Linux-KVM-535.230.02-539.19.zip";
      vgpuPatcher = null;
    };
    "${pref}_16_8" = mkVgpuDriver {
      version = "535.216.01";
      sha256 = "sha256-7C5cELcb2akv8Vpg+or2317RUK2GOW4LXvrtHoYOi/4=";
      guestVersion = "535.216.01";
      guestSha256 = "sha256-47s58S1X72lmLq8jA+n24lDLY1fZQKIGtzfKLG+cXII=";
      openSha256 = null;
      generalVersion = "535.216.01";
      settingsSha256 = "sha256-9PgaYJbP1s7hmKCYmkuLQ58nkTruhFdHAs4W84KQVME=";
      persistencedSha256 = "sha256-ckF/BgDA6xSFqFk07rn3HqXuR0iGfwA4PRxpP38QZgw=";
      gridVersion = "16.8";
      zipFilename = "NVIDIA-GRID-Linux-KVM-535.216.01-538.95.zip";
      vgpuPatcher = null;
    };
    "${pref}_16_5" = mkVgpuDriver {
      version = "535.161.05";
      sha256 = "sha256-uXBzzFcDfim1z9SOrZ4hz0iGCElEdN7l+rmXDbZ6ugs=";
      guestVersion = "535.161.08";
      guestSha256 = "sha256-5K1hmS+Oax6pGdS8pBthVQferAbVXAHfaLbd0fzytCA=";
      openSha256 = null;
      generalVersion = "535.161.07";
      settingsSha256 = "sha256-qKiKSNMUM8UftedmXtidVbu9fOkxzIXzBRIZNb497OU=";
      persistencedSha256 = "sha256-1kblNpRPlZ446HpKF1yMSK36z0QDQpMtu6HCdRdqwo8=";
      gridVersion = "16.5";
      zipFilename = "NVIDIA-GRID-Linux-KVM-535.161.05-535.161.08-538.46.zip";
      vgpuPatcher = mkVgpuPatcher {
        version = "535.161";
        rev = "59c75f98baf4261cf42922ba2af5d413f56f0621";
        sha256 = "sha256-IUBK+ni+yy/IfjuGM++4aOLQW5vjNiufOPfXOIXCDeI=";
        generalVersion = "535.161.07";
        generalSha256 = "sha256-7cUn8dz6AhKjv4FevzAtRe+WY4NKQeEahR3TjaFZqM0=";
        linuxGuest = "535.161.08";
        linuxSha256 = "sha256-5K1hmS+Oax6pGdS8pBthVQferAbVXAHfaLbd0fzytCA=";
        windowsGuestFilename = "538.46_grid_win10_win11_server2019_server2022_dch_64bit_international.exe";
        windowsSha256 = "sha256-GHD2kVo1awyyZZvu2ivphrXo2XhanVB9rU2mwmfjXE4=";
        gridVersion = "16.5";
      };
    };
    "${pref}_16_2" = mkVgpuDriver {
      version = "535.129.03";
      sha256 = "sha256-tFgDf7ZSIZRkvImO+9YglrLimGJMZ/fz25gjUT0TfDo=";
      guestVersion = "535.129.03";
      guestSha256 = "sha256-RWemnuEuZRPszUvy+Mj1/rXa5wn8tsncXMeeJHKnCxw=";
      openSha256 = null;
      generalVersion = "535.129.03";
      settingsSha256 = "sha256-QKN/gLGlT+/hAdYKlkIjZTgvubzQTt4/ki5Y+2Zj3pk=";
      persistencedSha256 = "sha256-FRMqY5uAJzq3o+YdM2Mdjj8Df6/cuUUAnh52Ne4koME=";
      gridVersion = "16.2";
      zipFilename = "NVIDIA-GRID-Linux-KVM-535.129.03-537.70.zip";
      vgpuPatcher = mkVgpuPatcher {
        version = "535.129";
        rev = "3765eee908858d069e7b31842f3486095b0846b5";
        sha256 = "sha256-jNyZbaeblO66aQu9f+toT8pu3Tgj1xpdiU5DgY82Fv8=";
        generalVersion = "535.129.03";
        generalSha256 = "sha256-5tylYmomCMa7KgRs/LfBrzOLnpYafdkKwJu4oSb/AC4=";
        linuxGuest = "535.129.03";
        linuxSha256 = "sha256-RWemnuEuZRPszUvy+Mj1/rXa5wn8tsncXMeeJHKnCxw=";
        windowsGuestFilename = "537.70_grid_win10_win11_server2019_server2022_dch_64bit_international.exe";
        windowsSha256 = "sha256-3eBuhVfIpPo5Cq4KHGBuQk+EBKdTOgpqcvs+AZo0q3M=";
        gridVersion = "16.2";
      };
    };
  };
in
{
  imports = [
    # Load host- or guest-specific options and config
    (import
      (if guest then ./guest.nix else ./host.nix)
      (args // { inherit utils; })
    )
  ];
  options = {
    hardware.nvidia.vgpu = {
      patcher = {
        enable = lib.mkEnableOption "driver patching using vGPU-Unlock-patcher";
        options.doNotForceGPLLicense = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Disables a kernel module hack that makes the driver usable on higher kernel versions.
            Turn it on if you have patched the kernel for support. Has no effect starting from 17.2.
          '';
        };
        # TODO: 17.x
        /*
          options.doNotPatchNvidiaOpen = lib.mkOption {
            type = lib.lib.types.bool;
            default = true;
            description = ''
              Will not patch open source NVIDIA kernel modules. For 17.x releases only.
              Enabled by default as a reinsurance against the possibility that you use open source drivers without even knowing it
              (for example, by accidentally setting `hardware.nvidia.open = true;`).
            '';
          };
        */
        options.extra = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "--test-dmabuf-export" ];
          description = "Extra flags to pass to the patcher.";
        };
      };
      driverSource = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "NVIDIA-GRID-Linux-KVM-535.129.03-537.70.zip";
          description = "The name of the driver file.";
        };
        url = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "";
          example = "https://drive.google.com/uc?export=download&id=n0TaR34LliNKG3t7h4tYOuR5elF";
          description = "The address of your local server from which to download the driver, if any.";
        };
        sha256 = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "sha256-tFgDf7ZSIZRkvImO+9YglrLimGJMZ/fz25gjUT0TfDo=";
          description = ''
            SHA256 hash of your driver. Note that anything other than null will automatically require a .run file, not a .zip GRID archive.
            Set the value to "" to get the correct hash (only when fetching from an HTTP(s) server).
          '';
        };
        curlOptsList = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "-u"
            "admin:12345678"
          ];
          description = "Additional curl options, similar to curlOptsList in pkgs.fetchurl.";
        };
      };
    };
  };
  config = {
    assertions = lib.optionals (config.hardware.nvidia.package ? vgpuPatcher) [
      {
        assertion = (pkgs.stdenv.hostPlatform.system == "x86_64-linux");
        message = "nvidia-vgpu only supports platform x86_64-linux";
      }
      {
        assertion = (merged -> vgpuCfg.patcher.enable);
        message = ''
          vGPU-Unlock-patcher must be enabled to make merged NVIDIA vGPU/GRID driver
          (did you accidentally set `services.xserver.videoDrivers = ["nvidia"]`?)
        '';
      }
      {
        assertion = (config.hardware.nvidia.package.vgpuPatcher == null -> !vgpuCfg.patcher.enable);
        message = "vGPU-Unlock-patcher is not supported for vGPU version ${config.hardware.nvidia.package.version}";
      }
      {
        assertion = (vgpuCfg.driverSource.sha256 == null -> lib.hasSuffix ".zip" (with vgpuCfg.driverSource; if name != "" then name else ".zip"));
        message = ''
          NVIDIA vGPU driver hash is not set, but `hardware.nvidia.vgpu.driverSource.name` has an extensions that differs from .zip
          Declare `hardware.nvidia.vgpu.driverSource.sha256` or change `name` option to have .run extension at the end
        '';
      }
      {
        assertion = (vgpuCfg.driverSource.sha256 != null -> lib.hasSuffix ".run" (with vgpuCfg.driverSource; if name != "" then name else ".run"));
        message = ''
          NVIDIA vGPU driver hash is set, but `hardware.nvidia.vgpu.driverSource.name` has an extensions that differs from .run
          Remove `hardware.nvidia.vgpu.driverSource.sha256` or change `name` option to have .zip extension at the end
        '';
      }
    ];

    # Add our packages to nvidiaPackages
    nixpkgs.overlays = [
      (utils.overlayNvidiaPackages (
        vgpuNixpkgsPkgs
        // {
          vgpuNixpkgsOverlay = utils.overlayNvidiaPackages vgpuNixpkgsPkgs;
        }
      ))
    ];
  };
}

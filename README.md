# vgpu4nixos

Use NVIDIA vGPU on NixOS, for both host and guest. Supports 16.x, 17.x and 18.x releases

Module adds new packages that can be selected in `hardware.nvidia.package`. Additionally, there is `hardware.nvidia.vgpu` submodule for additional configuration

Also features an integration with [vGPU-Unlock-patcher](https://github.com/VGPU-Community-Drivers/vGPU-Unlock-patcher)

### List of supported releases:
Releases not mentioned here can still be used, but you have to [create your own driver derivation](#custom-vgpu-version).
- 16.x: 16.2, 16.5, 16.8, 16.9, 16.10
- 17.x: 17.3, 17.4, 17.5, 17.6
- 18.x: 18.0, 18.1

## Installation

`vgpu4nixos` supports both Flakes and non-flake environments, though former is recommended

> [!IMPORTANT]
> Module will not be able to download host drivers automatically since they are not available for public download. Error message will contain instructions on how to add local GRID archive to Nix store
>
> **This is the case for host only.** Guest drivers are fetched from [Google Cloud](https://cloud.google.com/compute/docs/gpus/grid-drivers-table). 

### Flakes
flake.nix:
```nix
{
  inputs = {
    /* ... */
    vgpu4nixos.url = "github:mrzenc/vgpu4nixos";
  };

  outputs = { self, nixpkgs, vgpu4nixos, ... }@inputs: {
    nixosConfigurations.mrzenc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        /* ... */
        vgpu4nixos.nixosModules.host # Use nixosModules.guest for VMs
      ];
      /* ... */
    };
  };
}
```

### Without Flakes
configuration.nix:
```nix
{ pkgs, lib, config }:
{
  imports = [
    ./hardware-configuration.nix
    /* ... */
    (import (builtins.fetchGit {
      url = "https://github.com/mrzenc/vgpu4nixos.git";
      # Pin to specific commit (example value)
      # rev = "b6ddaeb51b1575c6c8ec05b117c3a8bfa3539e92";
    }) { guest = false; }) # Use { guest = true; } for VMs
  ];

  /* ... */
}
```
---
New packages will be available in `config.boot.kernelPackages.nvidiaPackages` in the form of `vgpu_XX_X` for the host or `grid_XX_X` for the guest. Specify the package in your configuration as follows:
```nix
{ config, pkgs, lib, ... }:
{
  /* ... */

  # You want to include this if you're using guest drivers
  # or want to use vGPU-Unlock-patcher's merged driver
  # services.xserver.videoDrivers = [ "nvidia" ];
  
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.vgpu_17_3;

  /* ... */
}
```

## Configuration

`hardware.nvidia.vgpu` consists of three submodules:
- `patcher` - driver patching utility
- `griddUnlock` - patch 18.x to use with `fastapi-dls`
- `driverSource` - where to get driver from

### `hardware.nvidia.vgpu.patcher`
Manages vGPU-Unlock-patcher's options. Please read its [README](https://github.com/VGPU-Community-Drivers/vGPU-Unlock-patcher/blob/535.161/README.md) if you don't know how to use it. Most likely, you will only need to specify `hardware.nvidia.vgpu.patcher.enable = true` and in some cases `hardware.nvidia.vgpu.patcher.copyVGPUProfiles`

> [!NOTE]
> The target for the vGPU patcher is determined automatically. For a guest, it will always be `grid`. For the host, if `services.xserver.videoDrivers = ["nvidia"];` is specified, it will be `general-merge` (merged), otherwise `vgpu-kvm`.

#### Available options
- `hardware.nvidia.vgpu.patcher.enable` (bool) - enable VUP
- `hardware.nvidia.vgpu.patcher.options.doNotForceGPLLicense` (bool)
	- if set to `false`, then the `--enable-nvidia-gpl-for-experimenting --force-nvidia-gpl-I-know-it-is-wrong` options will be applied, which allows using the driver with slightly newer kernels
- `hardware.nvidia.vgpu.patcher.options.remapP40ProfilesToV100D` (bool; only for host) - applies the `--remap-p2v` option. Only for 17.x releases
- `hardware.nvidia.vgpu.patcher.options.extra` (list of strings) - additional `patch.sh` command options
- `hardware.nvidia.vgpu.patcher.copyVGPUProfiles` (attrset; only for host) - additional `vcfgclone` lines (see VUP's README)
	- For example, `{"AAAA:BBBB" = "CCCC:DDDD"}` is the same as `vcfgclone ${TARGET}/vgpuConfig.xml 0xCCCC 0xDDDD 0xAAAA 0xBBBB`
- `hardware.nvidia.vgpu.patcher.enablePatcherCmd` (bool; only for host) - add a patcher to system packages (which will be available as `nvidia-vup`) for convenience
- `hardware.nvidia.vgpu.patcher.profileOverrides` (only for host) - custom properties for vGPU profiles

#### Profile overrides
Replace `*` in the following options with your profile ID (`"333"` in case of `nvidia-333`). Multiple overrides can be specified
- `profileOverrides.*.vramAllocation` (integer) - vRAM allocation in megabytes
- `profileOverrides.*.heads` (integer) - the maximum number of virtual monitors for one VM
- `profileOverrides.*.enableCuda` (bool)
- `profileOverrides.*.display.width` (integer) - maximum display width in pixels
- `profileOverrides.*.display.height` (integer) - maximum display height in pixels
- `profileOverrides.*.framerateLimit` (integer) - limits FPS to a certain value (`0` to disable limit)
- `profileOverrides.*.xmlConfig` (attrset) - additional configuration

An example of a profile override:
```nix
hardware.nvidia.vgpu.patcher.profileOverrides = {
  "333" = {
    vramAllocation = 3584; # 3.5GiB
    heads = 1;
    display.width = 1920;
    display.height = 1080;
    framerateLimit = 144;
  };
};
```

### `hardware.nvidia.vgpu.griddUnlock`
Integration with [`gridd-unlock-patcher`](https://git.collinwebdesigns.de/oscar.krause/gridd-unlock-patcher), for 18.x guests only

#### Available options
- `hardware.nvidia.vgpu.griddUnlock.enable` (bool) - enable/disable patch
- `hardware.nvidia.vgpu.griddUnlock.rootCaFile` (path) - path to `fastapi-dls` instance's root certificate authority. Required when submodule is enabled

### `hardware.nvidia.vgpu.driverSource`
Manages the driver source. It can accept either `Linux-KVM` GRID archive or a plain .run driver file. It can also fetch from Nix store or HTTP(s) server

> [!NOTE]
> To calculate `sha256` of local file you can use `nix-hash`:
> ```
> nix-hash --flat --base64 --type sha256 /path/to/file.zip
> ```
> If file is fetched from URL then it will throw error with correct hash.

#### Available options
- `hardware.nvidia.vgpu.driverSource.name` (string) - driver filename
  	- Host will expect a .zip by default, while guest expects a .run. The extension part of this option will force file type
- `hardware.nvidia.vgpu.driverSource.url` (string)
  	- Set to `null` to force fetch from Nix store
- `hardware.nvidia.vgpu.driverSource.sha256` (string)
  	- If set, then **.run is always expected**. If not, then .zip is expected on host, on guest .run is still expected but that can be overridden by `name`
  	- If value contradicts with `name` then rebuild will fail
- `hardware.nvidia.vgpu.driverSource.curlOptsList` (list of strings) - a list of arguments to pass to `curl`
	- For example, `["-u" "admin:some nice password"]`

### Custom vGPU version
The `mkVgpuDriver` and `mkVgpuPatcher` allow you to create your own driver derivation that can be passed to `hardware.nvidia.package`. This way you can use a version of the vGPU that is not available by default (yet)

#### Available attributes for `mkVgpuDriver`
- `version` (string) - version of the host driver
- `sha256` (string) - SHA-256 for **GRID .zip**, not .run
- `guestVersion` (string) - version of the guest driver
- `guestSha256` (string) - SHA-256 of the guest .run
- `useSettings` (bool; optional) - whether to use nVidia X Server settings
- `settingVersion` (string; optional) - the version of the settings app. Not required if `useSettings = false`
- `settingsSha256` (string; optional) - SHA-256 of the settings app. Not required if `useSettings = false`
- `usePersistenced` (bool; optional) - whether to use `nvidia-persistenced`
- `persistencedVersion` (string; optional) - the version of `nvidia-persistenced`. Not required if `usePersistenced = false`
- `persistencedSha256` (string; optional) - SHA-256 of `nvidia-persistenced`. Not required if `usePersistenced = false`
- `generalVersion` (string) - The closest version of consumer nVidia graphics drivers to the vGPU version (usually with the same major and minor versions). Used to build `nvidia-settings` and `nvidia-persistenced`
- `gridVersion` (string) - vGPU release (for example, 16.7, 17.2...)
- `zipFilename` (string) - the full name of the GRID .zip file (including extension)
- `vgpuPatcher` - a patcher derivation obtained from `mkVgpuPatcher` (set to `null` to disable patching)
- `prePatch`, `postPatch`, `patchFlags`, `patches`, `preInstall`, `postInstall`, `broken` are passed directly to `stdenv.mkDerivation` and are optional

#### Available attributes for `mkVgpuPatcher`
> [!IMPORTANT]
> The patcher created by `mkVgpuPatcher` cannot be overridden directly, because it returns a function that returns the derivation, not the derivation itself. You can still override it as follows:
> ```nix
> hardware.nvidia.package = (config.boot.kernelPackages.nvidiaPackages.mkVgpuDriver {
>   version = "555.44.33";
>   vgpuPatcher = config.boot.kernelPackages.nvidiaPackages.mkVgpuPatcher { /* ... */ };
>   # ...
> }).overrideAttrs (self: super: {
>   patcher = self.patcher.override {
>     # your overrides
>   };
> });
> ```
- `version` (string; optional) - the branch of the patcher, for visual appearance only
- `rev` (string) - git revision of the patcher (usually a specific commit or `refs/heads/your-branch`)
- `sha256` (string) - SHA-256 of the patcher source code
- `generalVersion` (string) - version of the consumer (general) driver
- `generalSha256` (string) - SHA-256 of the general driver
- `linuxGuest` (string) - version of the Linux guest drivers
- `linuxSha256` (string) - SHA-256 of Linux guest drivers
- `windowsGuestFilename` (string) - the full name of the Windows guest driver file (including extension)
- `windowsSha256` (string) - SHA-256 of Windows guest drivers
- `gridVersion` (string) - vGPU release (for example, 16.7, 17.2...). Useless if `vgpuUrl` is specified.
- `generalUrl` (string; optional) - URL where general drivers can be obtained
- `vgpuUrl` (string; optional) - URL where guest drivers can be obtained

## Attribution
The files in the `nvidia-vgpu` directory are modified versions of those from the `nvidia-x11` package of Nixpkgs, which is distributed under the [MIT license](https://github.com/NixOS/nixpkgs/blob/master/COPYING)

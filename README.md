# vgpu4nixos

Use NVIDIA vGPU on NixOS (both host and guest). Also supports [vGPU-Unlock-patcher](https://github.com/VGPU-Community-Drivers/vGPU-Unlock-patcher) (VUP for short) to unlock vGPU capabilities on consumer cards

## Installation
Currently these vGPU releases are selectable (you still can use your own version, see [Custom vGPU version](#custom-vgpu-version)):
- With unlock support: 17.3, 16.5, 16.2
- Without unlock: 18.1, 18.0, 17.5, 17.4, 16.9, 16.8

### With Flakes
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
Now more packages will be available in `config.boot.kernelPackages.nvidiaPackages`, for example `vgpu_16_2` for the host or `grid_16_2` for the guest. Specify the package in your configuration as follows:
```nix
{ config, pkgs, lib, ... }:
{
  /* ... */
  
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.vgpu_16_2;

  /* ... */
}
```

After that (during the first `nixos-rebuild`), the module will require you to add the GRID .zip archive (it must be `Linux-KVM` one, for example `NVIDIA-GRID-Linux-KVM-535.129.03-537.70.zip`) to the Nix store on the host. **This does not apply to the guest**

## Configuration
New options should appear in `hardware.nvidia.vgpu` after you specify the vGPU package

### `hardware.nvidia.vgpu.patcher`
VUP-related options. Please read the repository's [README](https://github.com/VGPU-Community-Drivers/vGPU-Unlock-patcher/blob/535.161/README.md) if you don't know how to use it. Most likely, you will only need to specify `hardware.nvidia.vgpu.patcher.enable = true` and in some cases `hardware.nvidia.vgpu.patcher.copyVGPUProfiles`

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
Replace `*` in the following options with your profile ID (`"333"` in case of `nvidia-333`, also referred to as `GeForce RTX 2070-3`). Multiple overrides can be specified
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

### `hardware.nvidia.vgpu.driverSource`
Manages the driver source. It can be used, for example, to download the driver from your HTTP(s) server. You can use a .run or GRID .zip file. You can also use a previously patched file. 

The module makes some assumptions about what file to retrieve and from where:
- by default, the host tries to fetch the GRID .zip from the Nix store, the guest fetches the driver online
- if `sha256` is specified, a .run file is always expected
- `url = null` will force the driver to be fetched from the Nix store (useful for guests)
- if `name` ends with the extension `.run`, then the .run file will be expected, the same with .zip (useful for guests)

To calculate `sha256` (not necessary when fetching from url, set it to `""` to find out) you can use `nix-hash`:
```
nix-hash --flat --base64 --type sha256 /path/to/file.zip
```

#### Available options
- `hardware.nvidia.vgpu.driverSource.name` (string) - driver filename
- `hardware.nvidia.vgpu.driverSource.url` (string)
- `hardware.nvidia.vgpu.driverSource.sha256` (string)
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
- `prePatch`, `postPatch`, `patchFlags`, `patches`, `preInstall`, `postInstall`, `broken` are passed directly to `stdenv.mkDerivation`

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

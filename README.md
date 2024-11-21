# nvidia-vgpu-nixos
> [!WARNING]
> Not to be confused with [nixos-nvidia-vgpu](https://github.com/Yeshey/nixos-nvidia-vgpu) by Yeshey

NixOS module to support NVIDIA vGPU drivers (including GRID guest drivers). Also supports [vGPU-Unlock-patcher](https://github.com/VGPU-Community-Drivers/vGPU-Unlock-patcher) for vGPU unlock

## Installation
Currently vGPU releases 16.5, 17.3 (latest with unlock support) and 16.2 are supported. Flakes must be enabled

Add a new input to your `flake.nix`:
```nix
{
  inputs = {
    /* ... */
    nvidia-vgpu-nixos.url = "github:mrzenc/nvidia-vgpu-nixos";
  };

  outputs = { self, nixpkgs, nvidia-vgpu-nixos, ... }@inputs: {
    nixosConfigurations.mrzenc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        /* ... */
        nvidia-vgpu-nixos.nixosModules.host # Use nixosModules.guest for VMs
        ./configuration.nix
      ];
      /* ... */
    };
  };
}
```

Now more packages will be available in `config.boot.kernelPackages.nvidiaPackages`, for example `vgpu_16_2` for the host or `grid_16_2` for the guest. Specify the package in the `configuration.nix` file as follows:
```nix
{ config, pkgs, lib, ... }:
{
  /* ... */
  
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.vgpu_16_2;

  /* ... */
}
```

After that (during the first rebuild), the module will require you to add the GRID .zip archive (it must be `Linux-KVM` one, for example `NVIDIA-GRID-Linux-KVM-535.129.03-537.70.zip`) to the Nix store on the host. This does not apply to the guest

## Configuration
After installation, new options should appear in `hardware.nvidia.vgpu`

### `hardware.nvidia.vgpu.patcher`
VUP-related options. Please read the repository's [README](https://github.com/VGPU-Community-Drivers/vGPU-Unlock-patcher/blob/535.129/README.md) if you don't know how to use it. Most likely, you will only need to specify `hardware.nvidia.vgpu.patcher.enable = true` and in some cases `hardware.nvidia.vgpu.patcher.copyVGPUProfiles`

> [!NOTE]
> The target for the vGPU patcher is determined automatically. For a guest, it will always be `grid`. For the host, if `services.xserver.videoDrivers = [ "nvidia" ];` is specified, it will be `general-merge` (merged), otherwise `vgpu-kvm`.

#### Available options
- `hardware.nvidia.vgpu.patcher.enable` (bool) - enable VUP
- `hardware.nvidia.vgpu.patcher.options.doNotForceGPLLicense` (bool)
	- if set to `false`, then the `--enable-nvidia-gpl-for-experimenting --force-nvidia-gpl-I-know-it-is-wrong` options will be applied, which allows using the driver with slightly newer kernels
- `hardware.nvidia.vgpu.patcher.options.remapP40ProfilesToV100D` (bool; only for host) - applies the `--remap-p2v` option. Only for 17.x releases
- `hardware.nvidia.vgpu.patcher.options.extra` (list of strings) - additional `patch.sh` command options
- `hardware.nvidia.vgpu.patcher.copyVGPUProfiles` (attrset; only for host) - additional `vcfgclone` lines (see VUP's README)
	- For example, `{"AAAA:BBBB" = "CCCC:DDDD"}` is the same as `vcfgclone ${TARGET}/vgpuConfig.xml 0xCCCC 0xDDDD 0xAAAA 0xBBBB`
- `hardware.nvidia.vgpu.patcher.enablePatcherCmd` (bool; only for host) - add a patcher to system packages (which will be available as `nvidia-vup`) for convenience

### `hardware.nvidia.vgpu.driverSource`
Manages the driver source. It can be used, for example, to download the driver from your HTTP(s) server. You can use a .run or GRID .zip file. You can also use a previously patched file. 

The module makes some assumptions about what file to retrieve and from where:
- by default, the host tries to fetch the GRID .zip from the Nix store, the guest fetches the driver online
- if `sha256` is specified, a .run file is always expected
- `url = null` will force the driver to be fetched from the Nix store (useful for guests)
- if `name` ends with the extension `.run`, then the .run file will be expected, the same with .zip (useful for guests)

To calculate `sha256` (if you have the file locally, otherwise set it to `""` which will throw an error with the correct hash) you can use `nix-hash`:
```
nix-hash --flat --base64 --type sha256 /path/to/file.zip
```

#### Available options
- `hardware.nvidia.vgpu.driverSource.name` (string) - driver filename
- `hardware.nvidia.vgpu.driverSource.url` (string)
- `hardware.nvidia.vgpu.driverSource.sha256` (string)
- `hardware.nvidia.vgpu.driverSource.curlOptsList` (list of string) - a list of arguments to pass to `curl`
	- For example, `["-u" "admin:some nice password"]`

## Credits
Some files from the `nvidia-x11` package in Nixpkgs are used. Nixpkgs is distributed under [the MIT license](https://github.com/NixOS/nixpkgs/blob/master/COPYING)

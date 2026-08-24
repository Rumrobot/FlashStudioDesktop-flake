# FlashStudioDesktop-flake

[![CI](https://img.shields.io/github/actions/workflow/status/Rumrobot/FlashStudioDesktop-flake/ci.yml?branch=main&label=CI)](https://github.com/Rumrobot/FlashStudioDesktop-flake/actions/workflows/ci.yml)
[![Update sources](https://img.shields.io/github/actions/workflow/status/Rumrobot/FlashStudioDesktop-flake/update.yml?label=update)](https://github.com/Rumrobot/FlashStudioDesktop-flake/actions/workflows/update.yml)
[![Version](https://img.shields.io/github/v/tag/Rumrobot/FlashStudioDesktop-flake?sort=semver&label=version)](https://github.com/Rumrobot/FlashStudioDesktop-flake/tags)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Built with Nix](https://img.shields.io/badge/built%20with-nix-5277C3?logo=nixos&logoColor=white)](https://nixos.org)

A Nix flake that packages the official Flash Studio Desktop AppImage releases for `x86_64-linux`, from [FlashForge/Orca-Flashforge](https://github.com/FlashForge/Orca-Flashforge/releases).

Versions are automatically updated daily.

> FlashForge's [website](https://www.flashforge.com/pages/flash-studio-desktop) ships newer Windows/macOS builds, but its Linux
> download lags behind the GitHub releases, so GitHub is the source used here.

## Usage

Run it directly:

```sh
nix run github:Rumrobot/FlashStudioDesktop-flake
```

Or add it to your flake inputs:

```nix
inputs.flash-studio.url = "github:Rumrobot/FlashStudioDesktop-flake";
```

and put the package in your system/home packages:

```nix
# NixOS
environment.systemPackages = [ inputs.flash-studio.packages.${pkgs.system}.default ];

# home-manager
home.packages = [ inputs.flash-studio.packages.${pkgs.system}.default ];
```

To pin a specific version, use its tag:

```nix
inputs.flash-studio.url = "github:Rumrobot/FlashStudioDesktop-flake/v1.7.9";
```

### NVIDIA workaround

Like the [OrcaSlicer](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/or/orca-slicer/package.nix) package, this flake includes a fix for rendering issues/crashes/laggy behaviour on NVIDIA systems:

```nix
inputs.flash-studio.packages.${pkgs.system}.default.override { withNvidiaGLWorkaround = true; }
```

## Development

`nix develop` (or direnv) enables the devshell with the lint tools and [Task](https://taskfile.dev), and installs the pre-commit hooks.

Run `task -l` to see available tasks.

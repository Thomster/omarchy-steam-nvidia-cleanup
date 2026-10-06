# omarchy-steam-nvidia-cleanup

An [Omarchy](https://omarchy.org/) shell service that notices NVIDIA
userspace drivers which installing Steam pulled onto a machine **without**
an NVIDIA GPU (found on an iMac19,1 with a Radeon Pro 580X).

Steam depends on the virtual packages `vulkan-driver` and
`lib32-vulkan-driver`. When pacman asks which provider to install, accepting
the first choice can install `nvidia-utils` and `lib32-nvidia-utils` on an
AMD or Intel machine. Installing the right driver afterwards
(`lib32-vulkan-radeon`, `lib32-vulkan-intel`) doesn't remove them. They cost
~1.4 GB and cause a boot error from systemd-modules-load:

```
Failed to find module 'nvidia_uvm'
```

No bar icon, no UI. Shortly after login and then hourly it runs the check
below and sends one desktop notification per boot if the packages can go,
pointing you at the bundled script. It never removes anything itself.

## What it checks

In this order, stopping at the first "no":

1. **Steam installed?**
2. **`nvidia-utils` / `lib32-nvidia-utils` installed as dependencies?**
   Explicitly installed packages are left alone.
3. **No NVIDIA hardware or kernel driver?** It refuses if an NVIDIA GPU is
   on the PCI bus, or if an NVIDIA kernel driver (`nvidia`, `nvidia-open`,
   any `*-dkms` variant, or any `nvidia.ko`) is installed. The second test
   catches an NVIDIA eGPU that just isn't plugged in right now.
4. **Removal leaves Steam a Vulkan driver?** `pacman -Rs` is simulated
   first. It fails if the AMD/Intel driver is missing, and the script tells
   you which package to install.

| Exit | Meaning |
|---|---|
| `0` | Nothing to do: no Steam, no stray packages, or NVIDIA hardware/driver present |
| `1` | Stray NVIDIA packages can be removed |
| `3` | Stray, but removing them would leave Steam without a Vulkan driver; install the right one first |

## The fix

```
sudo ~/.config/omarchy/plugins/steam-nvidia-cleanup/bin/omarchy-steam-nvidia-cleanup
```

Re-runs the check, creates a snapshot with `omarchy-snapshot create`, then
runs `pacman -Rs nvidia-utils lib32-nvidia-utils`. That also removes the
EGL helpers only they needed (`egl-wayland`, `egl-gbm`, ...). pacman shows
the list and asks before removing. `--yes` skips the question,
`--no-snapshot` skips the snapshot.

`linux-firmware-nvidia` stays: it's part of `linux-firmware`.

Read-only check, no root needed:

```
~/.config/omarchy/plugins/steam-nvidia-cleanup/bin/omarchy-steam-nvidia-cleanup --check
```

## Install

```
omarchy plugin add https://github.com/Thomster/omarchy-steam-nvidia-cleanup.git --enable
```

## Related

Built like [omarchy-dkms-audio-guard](https://github.com/Thomster/omarchy-dkms-audio-guard)
and [omarchy-nvidia-dkms-guard](https://github.com/Thomster/omarchy-nvidia-dkms-guard).
The latter is the opposite case: machines that *do* have an NVIDIA GPU.

After the cleanup, [omarchy-amdgpu-guard](https://github.com/Thomster/omarchy-amdgpu-guard)
checks that the AMD stack (Vulkan 64/32-bit, VA-API) still works.

## Changelog

Current version: **1.0.0**. See [CHANGELOG.md](CHANGELOG.md).

## How this came to be

This is a personal customization for my own Omarchy setup, built with the
help of [Claude Code](https://claude.com/claude-code) (Anthropic's AI coding
agent). I'm not a professional plugin developer — please read through the
source before installing, and open an issue if something looks off.

## License

MIT

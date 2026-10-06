# Changelog

All notable changes to omarchy-steam-nvidia-cleanup. Versions follow [Semantic Versioning](https://semver.org/).

## 1.0.0 – 2026-10-06

### Added

- Initial release: detects `nvidia-utils` / `lib32-nvidia-utils` installed as Steam's Vulkan driver on a machine without an NVIDIA GPU or NVIDIA kernel driver; simulates the removal first; notifies once per boot; bundled script snapshots and runs `pacman -Rs`.

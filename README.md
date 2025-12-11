# Demo

![nixos-nixbsd](https://github.com/user-attachments/assets/a2a635e9-9426-4c65-8bab-a565dd14dfd7)

# What is this?

This is my attempt to get my system dual-booting with NixOS and NixBSD.

It may not look like much, but it took me a lot of trial and error to get here!

# See also

- https://github.com/jonhermansen/nixpkgs/commits/beachepisode/
- https://github.com/jonhermansen/nixbsd

# Problems

- Many corners were cut
- FreeBSD barely boots (single-user mode shell access)
- System can't be compiled natively, only cross-compiled from Linux
- NixBSD configuration lives in a separate repo

# Achievements

- Upgraded to FreeBSD 15 last minute (ouch)
- Sorted out why init was crashing (no serial console was attached)
- Resolved ZFS mounting on boot ([libdevdctl still doesn't build](https://github.com/jonhermansen/nixpkgs/commit/7dbfd4741a6f86a422ca9fd72171003830299761) but is required by zfsd)
- Idempotent bootloader installation (... and NixOS and NixBSD coexist peacefully)
- Fully reproducible

# Planned TODO

- Upload artifacts to Cachix
- Consolidate all NixBSD configuration into this repository (but still consume upstream NixBSD as a flake)
- Produce a NixBSD install ISO
- Upstream fix for infinite recursion
- Investigate failing tests which I disabled to get to this point

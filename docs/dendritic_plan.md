# Dendritic Configuration Roadmap

This document outlines the layout plan for scaling this repository to support multiple machines and shared configurations when the repository grows.

## Target Structure

```text
.
├── flake.nix
├── flake.lock
├── .sops.yaml
├── secrets.yaml
├── docs/
│   ├── dendritic_plan.md
│   └── sops_setup.md
├── hosts/
│   └── laptop/
│       ├── configuration.nix
│       └── hardware-configuration.nix
└── modules/
    ├── core/                # Core settings shared by all hosts
    │   ├── default.nix
    │   └── packages.nix
    └── desktop/             # Graphical environment modules
        ├── gnome.nix
        ├── niri.nix
        └── fonts.nix
```

## Modularization Steps
1. **Move Host Configuration:** Relocate `configuration.nix` and `hardware-configuration.nix` into `hosts/laptop/`. Update paths in `flake.nix` and `configuration.nix`.
2. **Core Settings Extracted:** Move global system preferences, timezones, locales, and baseline CLI packages from the laptop config into `modules/core/`.
3. **Desktop Settings Extracted:** Extract audio settings, dconf keys, fonts, and display servers into specialized modules inside `modules/desktop/`.
4. **Host-Specific Cleanliness:** Keep host files (`hosts/laptop/configuration.nix`) minimal, specifying only options specific to that hardware profile.

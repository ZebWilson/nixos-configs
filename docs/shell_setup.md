# Shell Setup & Customization Notes

This guide documents tips and setup procedures for system shells (specifically **Zsh**) on NixOS.

## Zsh First-Time Setup

When Zsh starts up for a user for the first time, it checks for startup files. If they don't exist, it may prompt you to run the configuration helper.

### Rerunning the Configuration Helper
If you skipped the helper or want to re-run the interactive configuration manager in the future, you can execute the following commands in Zsh:
```zsh
autoload -Uz zsh-newuser-install
zsh-newuser-install -f
```

### Auto-generated Blocks in `~/.zshrc`
The configuration helper writes its lines to `~/.zshrc`. These are marked by the following comments:
```zsh
# Lines configured by zsh-newuser-install
...
# End of lines configured by zsh-newuser-install
```

> [!IMPORTANT]
> Do not manually edit anything between these lines if you plan to run `zsh-newuser-install` again in the future. You can freely edit any other parts of your `~/.zshrc` outside of these markers.

## NixOS Configuration Integration
In [configuration.nix](file:///home/zeb/nixos-configs/configuration.nix), Zsh is enabled globally and assigned to the user:
```nix
programs.zsh = {
  enable = true;
  autosuggestions.enable = true;
  syntaxHighlighting.enable = true;
};

users.users.zeb.shell = pkgs.zsh;
```
This ensures Zsh is added to `/etc/shells` and proper system-wide completions and environment files are loaded. Any user-specific configurations can be added to `~/.zshrc` alongside the interactive helper block.

# NixOS sops-nix Setup Guide

This document explains the steps taken to configure `sops-nix` for managing secrets (like your user account password hash) securely in a public Git repository.

---

## 1. How the Setup Works (FAQ)

### Q: What is the deal with `/var/lib/sops-nix/key.txt`?
**It is not needed in our setup.** 
By setting `sops.age.keyFile = null;` in `configuration.nix`, we tell `sops-nix` not to look for a separate standalone `age` keyfile. Instead, it will read your machine's SSH private host key (`/etc/ssh/ssh_host_ed25519_key`) directly and convert it on-the-fly to decrypt the secrets. This avoids "file not found" errors and makes the setup simpler.

### Q: What is `config.sops`? Is it short for `configuration.nix`?
**No.** `config` is a special input argument passed to your configuration function (at the top of `configuration.nix` on line 6: `{ config, pkgs, ... }:`).
* `config` represents the **entire evaluated configuration state of your NixOS system**.
* When we import the `sops-nix` module, it adds its own options under `config.sops`.
* `config.sops.secrets.user-password.path` dynamically evaluates to the path where the secret is decrypted in RAM (by default, `/run/secrets/user-password`).
* It has nothing to do with the filename `configuration.nix`.

### Q: How was `secrets.yaml` generated?
We generated it using the `sops` CLI tool:
1. We wrote the plaintext password hash to `secrets.yaml`:
   ```yaml
   user-password: "$6$KtjICxQy2GZfhYUJ$JlM..."
   ```
2. We ran the encryption command:
   ```bash
   nix run nixpkgs#sops -- --encrypt --in-place secrets.yaml
   ```
3. `sops` automatically read the encryption rules in `.sops.yaml` (which contains your public SSH keys), generated a one-off symmetric file key, encrypted the plaintext password, encrypted the file key for both public keys, and overwrote `secrets.yaml` with the final encrypted block.

### Q: How does sops handle encryption cryptographically (Envelope Encryption)?
* **The Data Key**: `sops` generates a random one-time symmetric data key (using AES-256 GCM).
* **Secret Encryption**: It encrypts your actual secrets (like `user-password`) using this data key.
* **Key Encryption**: It then encrypts that same data key multiple times, once for each of the public `age` recipient keys defined in `.sops.yaml`. These encrypted data keys are stored in the `sops.age` metadata section of `secrets.yaml`.
* **Decryption**: When decrypting, your private key (or the host's private key) is used to decrypt the data key, which is then used to decrypt the actual secrets.

### Q: What is `unencrypted_suffix: _unencrypted` in the secrets metadata?
* This configures a suffix filter for `sops`.
* Any key in `secrets.yaml` that ends with `_unencrypted` (e.g. `description_unencrypted`) will not be encrypted, allowing you to store public comments or non-sensitive metadata in the file while keeping actual secrets secure.

---

## 2. Step-by-Step Implementation Details

### Step 1: Configured `.sops.yaml`
We created a file named `.sops.yaml` in the root of your flake directory. This file acts as the rulebook for `sops`. It defines which public keys are allowed to encrypt and decrypt the files:

```yaml
keys:
  - &zeb_nix age1apc0xzutxqypjj66z04lp0jcw288t7cpvf5un8sllrjlz8r99duq9ndqp8
  - &laptop age1z4jg3fr678vtqa7ft2sexc7zhdg405sw80fdr5m33gsa84cgqf9snzvkuv

creation_rules:
  - path_regex: secrets\.yaml$
    key_groups:
      - age:
        - *zeb_nix
        - *laptop
```

### Step 2: Added `sops-nix` to `flake.nix`
We imported the `sops-nix` input and registered its NixOS module so the configuration can understand `sops` attributes:
```nix
inputs.sops-nix.url = "github:Mic92/sops-nix";

# Under outputs:
modules = [
  # ...
  inputs.sops-nix.nixosModules.sops
  ./configuration.nix
];
```

### Step 3: Configured `configuration.nix`
1. Added `sops` and `age` to your `environment.systemPackages` so you can manage secrets from the terminal.
2. Linked your user password to the decrypted secret path:
   ```nix
   users.users.zeb.hashedPasswordFile = config.sops.secrets.user-password.path;
   ```
3. Defined the `sops` configuration block at the bottom:
   ```nix
   sops = {
     defaultSopsFile = ./secrets.yaml;
     defaultSopsFormat = "yaml";
     age = {
       keyFile = null;
       sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
     };
     secrets = {
       user-password = {
         neededForUsers = true;
       };
     };
   };
   ```

---

## 3. Maintenance Commands

Here are the commands you will use to manage this setup in the future:

### To edit your secrets:
```bash
sops secrets.yaml
```
*(This will decrypt the file in memory, open it in your default CLI text editor, and re-encrypt it automatically upon saving and exiting).*

### To add more secrets:
1. Open the file: `sops secrets.yaml`
2. Add a new key-value pair, e.g.:
   ```yaml
   another-secret: "my-super-secret-value"
   ```
3. Save and close.
4. Add it to `configuration.nix` under `sops.secrets`:
   ```nix
   sops.secrets.another-secret = {};
   ```
5. You can then reference it using `config.sops.secrets.another-secret.path`.

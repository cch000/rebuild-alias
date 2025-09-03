# rebuild-alias

Dead simple flake that auto-generates `nixos-rebuild` aliases for all your hosts.
All systems compatible with nixpkgs are supported.

## Usage

For rebuilding `localhost` the special aliases `local-rebuild`, `local-boot` are available.

If we instead want to rebuild a remote host, we use aliases generated with this name scheme 
`${host}-${subcommand}`. E.g., `athena-rebuild`, `hephaestus-boot`, `apolo-test`, etc.

> [!NOTE]
> ssh must be properly configured so that rebuild-alias works, meaning that `ssh $REMOTE-HOSTNAME` should be a valid command. This can be achieved by following this tutorial on the [NixOS Wiki](https://nixos.wiki/wiki/SSH_public_key_authentication), for example.

## Install

First, we instantiate rebuild-alias by adding it to our flake.

```nix
{
  inputs = {
    rebuild-alias = {
      url = "github:cch000/rebuild-alias";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = {nixpkgs, self, rebuild-alias}: {
    # Imagine the contents
  };
}

```

Now that rebuild-alias is in scope, we evaluate its `lib` attribute.

Finally, the only thing left to do is adding the aliases to our `devsShells` 
or `systemPackages`.

> [!NOTE]
> To target systems other than `x86_64-linux`, we can also pass as an argument our local's flake `pkgs`. 


```nix
{
  inputs = {
    rebuild-alias = {
      url = "github:cch000/rebuild-alias";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = {nixpkgs, self, rebuild-alias}: let 
  
    # Evaluate rebuild-alias.lib
    rebuildAliases = rebuild-alias.lib.evalModule {
      # We pass "self" as an argument so rebuild-alias can find the hosts in our flake 
      inherit self;
      # Optional, default: pkgs for x86_64-linux
      inherit pkgs;
      # Optional, default: current directory
      configPath = "~/dotfiles";
      # Optional, subcommands to generate aliases for, default: all
      subCommands = ["boot" "switch" "build"];
      # Optional, hosts to avoid generating aliases for, default: none
      blacklist = ["athena"];
    };
  
  in {
    # Add the aliases to the devshell
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = [ rebuildAliases ];
    };
  };
}
```

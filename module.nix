{
  args,
  pkgs,
  lib,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    concatMap
    strings
    ;
  inherit
    (strings)
    optionalString
    ;
  inherit
    (builtins)
    elem
    attrNames
    ;
  inherit
    (pkgs)
    writeShellScriptBin
    symlinkJoin
    ;
  inherit
    (types)
    package
    ;
in {
  options.evalModule = mkOption {
    type = package;
    readOnly = true;
  };

  config.evalModule = let
    hosts = attrNames (
      args.self.nixosConfigurations
      or (throw "`self` is a required argument for rebuild-alias")
    );
    configPath = args.configPath or ".#";

    command = args.command or "nixos-rebuild";

    subCommands = let
      validateSubCommands = subCommands:
        map (
          subCommand:
            if !(elem subCommand default)
            then throw "Invalid subcommand: `${subCommand}` passed as an argument"
            else subCommand
        )
        subCommands;

      default = [
        "switch"
        "boot"
        "test"
        "build"
        "dry-build"
        "dry-activate"
        "build-vm"
        "build-vm-with-bootloader"
      ];
    in
      if !(args ? subCommands)
      then default
      else validateSubCommands args.subCommands;

    requireSudo = ["switch" "boot"];

    genCommands = host: let
      mkCommand = host: subCommand: {
        name =
          if host == "LOCALHOST"
          then "local-${subCommand}"
          else "${host}-${subCommand}";
        command =
          "${command} ${subCommand} --flake ${configPath}"
          + (optionalString (host != "LOCALHOST") " --target-host ${host}")
          + (optionalString (elem subCommand requireSudo) " --sudo --ask-sudo-password");
      };
    in
      map (subCommand: mkCommand host subCommand) subCommands;

    localCommands = genCommands "LOCALHOST";

    remoteCommands = concatMap (host: genCommands host) hosts;

    commands = localCommands ++ remoteCommands;

    paths = map (x: writeShellScriptBin x.name x.command) commands;
  in
    symlinkJoin {
      name = "rebuild-alias";
      inherit paths;
    };
}

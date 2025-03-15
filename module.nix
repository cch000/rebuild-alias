{
  hosts,
  configPath,
  subCommands,
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
    ;
in {
  options.evalModule = mkOption {
    type = with types; package;
    readOnly = true;
  };
  config.evalModule = let
    inherit hosts;

    types =
      if subCommands == []
      then [
        "switch"
        "boot"
        "test"
        "build"
        "dry-build"
        "dry-activate"
        "build-vm"
        "build-vm-with-bootloader"
      ]
      else subCommands;

    requireSudo = ["switch" "boot"];

    mkCommand = host: type: {
      name =
        if host == "LOCALHOST"
        then "local-${type}"
        else "${host}-${type}";
      command =
        "nixos-rebuild ${type} --flake ${configPath}"
        + (optionalString (host != "LOCALHOST") " --target-host ${host}")
        + (optionalString (elem type requireSudo) " --use-remote-sudo");
    };

    localCommands = map (type: mkCommand "LOCALHOST" type) types;

    remoteCommands = concatMap (host: map (type: mkCommand host type) types) hosts;

    commands = localCommands ++ remoteCommands;

    paths = map (x: pkgs.writeShellScriptBin x.name x.command) commands;
  in
    pkgs.symlinkJoin {
      name = "rebuild-alias";
      inherit paths;
    };
}

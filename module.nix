{
  hosts,
  configPath,
  pkgs,
  lib,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    concatMap
    ;
in {
  options.evalModule = mkOption {
    type = with types; package;
    readOnly = true;
  };
  config.evalModule = let
    inherit hosts;

    types = ["switch" "boot"];

    mkCommand = host: type: {
      name =
        if host == "LOCAL"
        then "local-${type}"
        else "${host}-${type}";
      command =
        if host == "LOCAL"
        then "nixos-rebuild ${type} --use-remote-sudo --flake ${configPath}"
        else "nixos-rebuild ${type} --target-host ${host} --use-remote-sudo --flake ${configPath}";
    };

    localCommands = map (type: mkCommand "LOCAL" type) types;

    remoteCommands = concatMap (host: map (type: mkCommand host type) types) hosts;

    commands = localCommands ++ remoteCommands;

    paths = map (x: pkgs.writeShellScriptBin x.name x.command) commands;
  in
    pkgs.symlinkJoin {
      name = "rebuild-alias";
      inherit paths;
    };
}

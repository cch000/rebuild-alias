{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";

    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    localpkgs = pkgs;

    eval = {
      pkgs ? localpkgs,
      subCommands ? null,
      self ? null,
      configPath ? null,
      #deal with "null" values in module.nix
    } @ args:
      nixpkgs.lib.evalModules {
        modules = [
          ./module.nix
        ];
        specialArgs = {
          inherit args;
          inherit pkgs; #args.pkgs
        };
      };
  in {
    lib.evalModule = args: (eval args).config.evalModule;

    devShells.${system}.default = pkgs.mkShell {packages = with pkgs; [nil alejandra];};
  };
}

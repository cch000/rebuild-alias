{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";

    pkgs = nixpkgs.legacyPackages.x86_64-linux;

    eval = {
      self,
      configPath,
    }:
      pkgs.lib.evalModules {
        modules = [
          ./module.nix
        ];
        specialArgs = {
          inherit pkgs configPath;
          hosts = builtins.attrNames self.nixosConfigurations;
        };
      };
  in {
    lib.evalModule = args: (eval args).config.evalModule;

    devShells.${system}.default = pkgs.mkShell {packages = with pkgs; [nil alejandra];};
  };
}

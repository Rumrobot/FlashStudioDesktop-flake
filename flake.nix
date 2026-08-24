{
  description = "Flash Studio Desktop AppImage flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    git-hooks,
    ...
  }: let
    supportedSystems = ["x86_64"];
    linuxSystems = map (arch: "${arch}-linux") supportedSystems;
    sources = builtins.fromJSON (builtins.readFile ./sources.json);
  in
    flake-utils.lib.eachSystem linuxSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.default = pkgs.callPackage ./package.nix {
          source = sources.${system};
        };

        formatter = pkgs.alejandra;

        checks.git-hooks = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };

        devShells.default = pkgs.mkShell {
          inherit (self.checks.${system}.git-hooks) shellHook;
          packages =
            self.checks.${system}.git-hooks.enabledPackages
            ++ (with pkgs; [
              go-task
            ]);
        };
      }
    );
}

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    opam-repository.url = "github:ocaml/opam-repository";
    opam-repository.flake = false;
    opam-nix.url = "github:tweag/opam-nix";
  };
  outputs = { self, flake-utils, opam-nix, nixpkgs, opam-repository }@inputs:
    let package = "irmin_asai_demo";
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        on = opam-nix.lib.${system};
        devPackagesQuery = {
          ocaml-base-compiler = "5.2.0";
          ocaml-lsp-server = "*";
        };
        query = devPackagesQuery // { };
        scope =
          on.buildOpamProject' { repos = [ "${opam-repository}" ]; } ./. query;
        overlay = final: prev: {
          ${package} =
            prev.${package}.overrideAttrs (_: { doNixSupport = false; });
        };
        scope' = scope.overrideScope overlay;
        main = scope'.${package};
        devPackages = builtins.attrValues
          (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope');
      in {
        legacyPackages = scope';
        packages.default = main;
        devShells.default = pkgs.mkShell {
          inputsFrom = [ main ];
          buildInputs = devPackages;
        };
      });
}

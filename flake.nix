{
  description = "A language server (LSP) for the theorem prover, coq";

  outputs = inputs @ {
    self,
    flake-parts,
    treefmt,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      imports = [treefmt.flakeModule];
      flake.self = self;
      perSystem = {
        config,
        pkgs,
        lib,
        ...
      }: let
        coq_8_17 = pkgs.coqPackages_8_17;
        coqPackages = coq_8_17.coqPackages;
        ocamlPackages = coq_8_17.coq.ocamlPackages;
      in {
        packages.default = config.packages.coq-lsp;

        # NOTE(2023-06-02): Nix does not support top-level self submodules (yet)
        packages.coq-lsp = ocamlPackages.buildDunePackage {
          duneVersion = "3";

          pname = "coq-lsp";
          version = "${self.lastModifiedDate}+8.17-rc1";

          src = self.outPath;

          propagatedBuildInputs = let
            serapi =
              (coqPackages.lib.overrideCoqDerivation {
                  defaultVersion = "8.17.0+0.17.0";
                }
                coqPackages.serapi)
              .overrideAttrs (_: {
                src = inputs.coq-serapi;
              });
          in
            builtins.attrValues {
              inherit serapi;
              inherit (ocamlPackages) yojson cmdliner;
            };
        };

        treefmt.config = {
          projectRootFile = "dune-project";

          flakeFormatter = true;

          programs.alejandra.enable = true;
          programs.ocamlformat.enable = true;
          programs.prettier.enable = true;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [config.packages.coq-lsp];

          packages = builtins.attrValues {
            inherit (config.treefmt.build) wrapper;
            inherit (pkgs) nodejs dune_3;
            inherit (ocamlPackages) ocaml ocaml-lsp;
          };
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt.url = "github:numtide/treefmt-nix";

    flake-compat = {
      flake = false;
      url = "github:edolstra/flake-compat";
    };

    coq-serapi = {
      url = "github:ejgallego/coq-serapi/v8.17";
      flake = false;
    };
  };
}

{
  description =
    "Compiling and flashing QMK firmware to a Aurora (ferris) sweep";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable"; };

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      withSystem = f:
        lib.fold lib.recursiveUpdate { } (map f [ "x86_64-linux" ]);
    in withSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        keyboard = "splitkb/aurora/sweep/rev1";
        keymap = "mokasin";
      in {
        packages.${system}.default = pkgs.stdenv.mkDerivation {
          name = "qmk-firmware";
          src = ./.;

          nativeBuildInputs = [ pkgs.qmk pkgs.python3 ];

          NIX_BUILD_CORES = 8;

          buildPhase = ''
            patchShebangs .
            SKIP_GIT=true SKIP_VERSION=true \
              qmk compile -c -e CONVERT_TO=liatris -j $NIX_BUILD_CORES -kb ${keyboard} -km ${keymap}
          '';

          installPhase = ''
            mkdir $out
            cp -r .build/*.uf2 $out/
          '';
        };

        devShells.${system}.default = pkgs.mkShell {
          buildInputs = [ pkgs.qmk ];
          shellHook = ''
            build() {
              BUILD_DIR=''${1:-.build}
              SKIP_GIT=true SKIP_VERSION=true \
                qmk compile -e CONVERT_TO=liatris -j 4 -kb ${keyboard} -km ${keymap}
            }
          '';
        };
      }

    );
}

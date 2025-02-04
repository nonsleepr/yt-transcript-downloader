{
  description = "A flake for the yt script";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }:
    let
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      packages = forAllSystems ({ pkgs }: rec {
        yt = pkgs.stdenvNoCC.mkDerivation {
          pname = "yt";
          version = "1.0";

          src = ./.;

          buildInputs = [ pkgs.makeWrapper ];
          nativeBuildInputs = [ pkgs.python3 ];

          installPhase = ''
            install -Dm755 yt.py $out/bin/yt
            wrapProgram $out/bin/yt --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.yt-dlp ]}
          '';
        };
        default = yt;
      });
    };
}

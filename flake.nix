{
  description = "Zephyr Host Tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = {self, nixpkgs}: 
    let 

      supportedSystems = ["x86_64-linux" "aarch64-linux"];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in {

      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in rec {

          zephyr-hosttools = with pkgs; stdenv.mkDerivation rec {
            pname = "zephyr-hosttools";
            version = "0.15.1";

            platform = {
              aarch64-linux = "linux-aarch64";
              x86_64-linux = "linux-x86_64";
            }.${system} or (throw "Unsupported system: ${system}");

            src = fetchurl {
              url = "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${version}/hosttools_${platform}.tar.gz";
              sha256 = {
                aarch64-linux = "1c9v645kma40s79k5l0akh6f3agbxsarbrl63c53nrqfhym74387";
                x86_64-linux = "10423b0pvzcmck6vn0p73rbzmn4sr0z2plwy19y918pk298a97qf";
              }.${system} or (throw "Unsupported system: ${system}");
            };

            nativeBuildInputs = [
              python38
              which
              # autoPatchelfHook # We can use normal autopatchelf since all the binaries in sysroots are static
            ];

            sourceRoot = ".";

            dontConfigure = true;
            dontBuild = true;
            dontFixup = true;

            installPhase = let hosttype = lib.strings.removePrefix "linux-" platform; in ''
              bash ./zephyr-sdk-${hosttype}-hosttools-standalone-0.9.sh -y -d $out
              mkdir -p $out/bin
              ln -s $out/sysroots/x86_64-pokysdk-linux/usr/bin/* $out/bin/
            '';

            meta = with lib; {
              homepage = "https://www.zephyrproject.org/";
              description = "Zephyr RTOS host tools";
              platforms = [ "x86_64-linux" "aarch64-linux" ];
            };
          };

          default = zephyr-hosttools;

        });

    };

}
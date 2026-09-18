{
  description = "Orla desktop shell for Quickshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    sunghyun-sans = {
      url = "github:anaclumos/sunghyun-sans";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      quickshell,
      sunghyun-sans,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;
        qs = quickshell.packages.${system}.default;
        qt = pkgs.qt6;
        sunghyun = sunghyun-sans.packages.${system}.sunghyun-sans;
        fontconfig = pkgs.makeFontsConf {
          fontDirectories = [ sunghyun ];
        };
        orlaSource = lib.fileset.toSource {
          root = ./.;
          fileset = lib.fileset.unions [
            ./shell.qml
            ./components
            ./icons
            ./services
            ./singletons
            ./surfaces
            ./widgets
          ];
        };
        orla = pkgs.stdenvNoCC.mkDerivation {
          pname = "orla";
          version = "unstable";
          src = orlaSource;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/bin" "$out/share/orla"
            cp -R . "$out/share/orla"

            makeWrapper ${lib.getExe qs} "$out/bin/orla" \
              --set FONTCONFIG_FILE ${fontconfig} \
              --prefix QML_IMPORT_PATH : ${qt.qtdeclarative}/lib/qt-6/qml \
              --prefix QML_IMPORT_PATH : ${qt.qtlottie}/lib/qt-6/qml \
              --prefix QML_IMPORT_PATH : ${qs}/lib/qt-6/qml \
              --add-flags "-n -p $out/share/orla"

            runHook postInstall
          '';

          meta = {
            description = "Desktop shell built with Quickshell for Wayland and Hyprland";
            mainProgram = "orla";
            platforms = lib.platforms.linux;
          };
        };
      in
      {
        packages = {
          inherit orla;
          default = orla;
        };

        apps.default = {
          type = "app";
          program = lib.getExe orla;
          meta.description = "Start the Orla desktop shell";
        };

        devShells.default = pkgs.mkShell {
          name = "orla-dev";

          packages = [
            qs

            qt.qtbase
            qt.qtdeclarative
            qt.qtsvg
            qt.qtimageformats
            qt.qtmultimedia
            qt.qt5compat
            qt.qtlottie

            qt.qtshadertools

            pkgs.fzf
          ];

          FONTCONFIG_FILE = fontconfig;

          shellHook = ''
            export QML_IMPORT_PATH="${qt.qtdeclarative}/lib/qt-6/qml:${qt.qtlottie}/lib/qt-6/qml:${qs}/lib/qt-6/qml''${QML_IMPORT_PATH:+:$QML_IMPORT_PATH}"
          '';
        };
      }
    );
}

{
  description = "Baptiste's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    
    # Reste de vos inputs pour la gestion des taps Homebrew (nécessaires si vous utilisez la syntaxe homebrew = { ... })
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, homebrew-core, homebrew-cask, homebrew-bundle, ...}:
  let
    configuration = { pkgs, config, ... }: {

      nixpkgs.config = {
        allowUnfree = true;
        allowBroken = true;
        allowUnsupportedSystem = true;
      };

      environment.systemPackages =
        [
          pkgs.neovim
          pkgs.mkalias
          pkgs.obsidian
          pkgs.git
          pkgs.spotify
          pkgs.arc-browser
          pkgs.ollama
          pkgs.iosevka
          pkgs.hackgen-font
          pkgs.fzf
          pkgs.fd
          pkgs.ripgrep
          pkgs.python314
          pkgs.go
          pkgs.yarn
          pkgs.iina
          pkgs.zellij
          pkgs.exiftool
          pkgs.baobab
          pkgs.pkgconf
          pkgs.pkg-config
	  pkgs.darwin.apple_sdk.frameworks.Foundation
        ];

      # Configuration Homebrew via le module natif de nix-darwin
      homebrew = {
        enable = true;
        
        # Le préfixe /opt/homebrew (Apple Silicon) est géré automatiquement.
        # Vous n'avez PAS besoin de définir enableRosetta ici.

        brews = [
          "openssl"
          "mas"
          "rust"
          "llvm"
        ];
        casks = [
          "the-unarchiver"
          "raycast"
          "linearmouse"
          "legcord"
          "maccy"
          "tradingview"
          "ghostty"
        ];
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
      ];

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';

      # AnkiConnect for yomitan-anki connection
      system.activationScripts.ankiQtDefaults.text = ''
        ${pkgs.darwin.defaults}/bin/defaults write net.ankiweb.dtop NSAppSleepDisabled -bool true
        ${pkgs.darwin.defaults}/bin/defaults write net.ichi2.anki NSAppSleepDisabled -bool true
        ${pkgs.darwin.defaults}/bin/defaults write org.qt-project.Qt.QtWebEngineCore NSAppSleepDisabled -bool true
      '';

      system.defaults = {
        dock.autohide = true;
        dock.autohide-time-modifier = 0.4;
        dock.autohide-delay = 0.0;
        dock.expose-animation-duration = 0.05;
        dock.persistent-apps = [
          "${pkgs.arc-browser}/Applications/Arc.app"
          "Applications/Proton Mail.app"
          "/System/Applications/Calendar.app"
          "Applications/Ghostty.app"
          "Applications/Visual Studio Code.app"
          "${pkgs.obsidian}/Applications/Obsidian.app"
          "${pkgs.spotify}/Applications/Spotify.app"
          "Applications/WhatsApp.app"
          "Applications/Anki.app"
          "Applications/TradingView.app"
        ];
        finder.FXPreferredViewStyle = "clmv";
        loginwindow.GuestEnabled = false;
        NSGlobalDomain.AppleICUForce24HourTime = true;
        NSGlobalDomain.AppleInterfaceStyle = "Dark";
        NSGlobalDomain.KeyRepeat = 2;
      };

      system.primaryUser = "baptiste";
      security.pam.services.sudo_local.touchIdAuth = true;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";
      
      programs.zsh.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    darwinConfigurations."Baptistes-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
      ];
    };
  };
}

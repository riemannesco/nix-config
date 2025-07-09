{
  description = "Baptiste's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # Optional: Declarative tap management
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

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, homebrew-cask, homebrew-bundle, ...}:
  let
    configuration = { pkgs, config, ... }: {

      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.allowBroken = true;
      nixpkgs.config.allowUnsupportedSystem = true;

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
	  pkgs.openssl
	  pkgs.fzf
	  pkgs.fd
	  pkgs.ripgrep
	  pkgs.python314
	  pkgs.go
	  pkgs.rustup
	  pkgs.yarn
	  pkgs.iina
	  pkgs.zellij
        ];

      homebrew = {
	enable = true;
	brews = [
	  "mas"
	];
	casks = [
	  "the-unarchiver"
	  "raycast"
	  "linearmouse"
	  "legcord"
	  "maccy"
	  "tradingview"
    "anki"
    "ghostty"
	];
	#onActivation.cleanup = "zap";
  #homebrew.global.brewfile = true;
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
	  "Applications/Ghostty.app"
    "/System/Applications/Calendar.app"
	  "${pkgs.obsidian}/Applications/Obsidian.app"
	  "${pkgs.spotify}/Applications/Spotify.app"
	  "Applications/Anki.app"
	]; 
	#systemPowerManagement = {
	#  "AC Power" = {
	#    "System Sleep Timer" = 20;
	#    "Display Sleep Timer" = 15;
	#  };
	#  "Battery Power" = {
	#    "System Sleep Timer" = 15;
	#    "Display Sleep Timer" = 5;
	#  };
	#};
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


      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;
      programs.zsh.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Baptistes-MacBook-Pro
    darwinConfigurations."Baptistes-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration 
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "baptiste";

            # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
              "homebrew/homebrew-bundle" = homebrew-bundle;
            };

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = false;
          };
        }
      ];
    };
  };
}

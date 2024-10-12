{
  description = "Codeurge Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      nixpkgs.config.allowUnfree = true;
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ 
          pkgs.btop # system monitor
          pkgs.devbox # version manager
          pkgs.fzf # fuzzy finder
          pkgs.htop #system monitor
          pkgs.gh # github authenticator
          pkgs.git # git
          pkgs.go # go language
          pkgs.gotop # system monitor
          pkgs.killall # kill a running process
          pkgs.mkalias # for nix to install apps as aliases
          pkgs.neovim # neovim text editor
          pkgs.nodejs # node
          pkgs.ruby # ruby
          pkgs.stow #symlink dotfiles
          pkgs.tig # git ui
          pkgs.tmux # cli mux
          pkgs.yarn-berry
        ];

      homebrew = {
          enable = true;
          casks = [
            "1password"
            "alacritty"
            "android-studio"
            "appcleaner"
            "bitwarden"
            "betterdisplay"
            "caffeine"
            "chatgpt"
            "cursor"
            "iterm2"
            "figma"
            "google-chrome"
            "notion"
            "postman"
            "reactotron"
            "rectangle"
            "screenflow"
            "slack"
            "the-unarchiver"
            "visual-studio-code"
          ];
      };

      fonts.packages = [
        (pkgs.nerdfonts.override { fonts = ["JetBrainsMono"]; })
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
        while read src; do
          app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
            done
      '';

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."totem" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration 
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "derek";
              autoMigrate = true;
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."totem".pkgs;
  };
}

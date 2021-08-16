{ config, pkgs, ... }:


let 
  rootDir = toString ./.;
  phpDir = "${rootDir}/php";
  nginxDir = "${rootDir}/nginx";
  wwwRootDir = "/Volumes/WWW";

  phpConf = (import ./php/phpfpm-nginx.conf.nix) { inherit pkgs phpDir ;};
  nginxConf = (import ./nginx/nginx.conf.nix) {inherit pkgs nginxDir phpDir wwwRootDir; };

  php = pkgs.php74.buildEnv {
    extraConfig = ''
      memory_limit = 2G
      xdebug.mode = debug
      xdebug.start_with_request = yes
    '';
    extensions = { all, enabled, ... }: enabled ++ [ all.imagick all.xdebug ];
  };
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
      ## Core
      pkgs.coreutils
      pkgs.wget
      pkgs.htop
      pkgs.neovim
      pkgs.gnupg
      pkgs.git
      pkgs.oh-my-zsh
      pkgs.gcc
      pkgs.openssl

      pkgs.qemu
      pkgs.libvirt
      # pkgs.virt-manager-qt

      ## Networking
      pkgs.dig

      ## JavaScript Development
      pkgs.nodejs
      # pkgs.nodejs-12_x
      pkgs.yarn
      pkgs.nodePackages.eslint
      pkgs.nodePackages.prettier
      pkgs.nodePackages.create-react-app

      ## PHP Development
      pkgs.mysql
      pkgs.nginx
      pkgs.php74Packages.composer
      php
      # For generating a self signed certificate
      pkgs.mkcert
      pkgs.nss
      pkgs.nssTools

    ];

  environment.shellAliases.php = "php -p ${phpDir}";
  environment.shellAliases."php-fpm" = "php-fpm -p ${phpDir} -y ${phpConf}";
  environment.shellAliases.nginx = "nginx -p ${nginxDir}/tmp -c ${nginxConf}";
  environment.shellAliases.mysqld = "mysqld --datadir=/usr/local/var/mysql/ --socket=/tmp/mysql.sock";

  launchd.user.agents.nginx = {
    command = "${pkgs.nginx}/bin/nginx -p ${nginxDir}/tmp -c ${nginxConf}";
    path = [pkgs.nginx];
    serviceConfig = {
      KeepAlive = true;
    };
  };

  launchd.user.agents.mysqld = {
    command = "mysqld --datadir=/usr/local/var/mysql/ --socket=/tmp/mysql.sock";
    path = [pkgs.mysql];
    serviceConfig = {
      KeepAlive = true;
    };
  };

  launchd.user.agents."php-fpm" = {
    command = "${php}/bin/php-fpm -p ${phpDir} -y ${phpConf}";
    path = [php];
    serviceConfig = {
      KeepAlive = true;
    };
  };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = false;
  # nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}

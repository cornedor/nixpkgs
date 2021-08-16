# My nix-darwin configuration

## Magento

This setup includes basic setup to host multiple Magento 2 instances using
nginx, php-fpm and mysql locally. It still does require starting services by
hand, but they could easily implemented with launchd.

## Install

Install [Nix](https://nixos.org/guides/install-nix.html)

```
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Install [nix-darwin](https://daiderd.com/nix-darwin/)

```
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer
```

Clone this directory in `~/.nixpkgs` and run

```
darwin-rebuild switch
```

Generate new certificates using mkcert

```
cd ~/.nixpkgs/nginx
mkcert "*.mage.test"
```

Start all the services
(TODO: Launch using launchd)
(INFO: The mysql datadir is set to the default homdebrew mysql dir so it works with old databases)

```
mysqld --datadir=/usr/local/var/mysql/ --socket=/tmp/mysql.sock
php-fpm
nginx
```

## Uninstall

```
rm -rf /nix
```

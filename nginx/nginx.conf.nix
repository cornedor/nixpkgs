{pkgs, nginxDir, phpDir, wwwRootDir}:

let
  fastcgiParamsFile = pkgs.writeText "fastcgi_params" (builtins.readFile ./fastcgi_params);
  magentoConf = (import ./magento.conf.nix) {inherit pkgs fastcgiParamsFile; };
in
  pkgs.writeText "nginx.conf" ''
error_log ${nginxDir}/log/error.log;
daemon on;
worker_processes 1;
pid ${nginxDir}/log/nginx.pid;

events {
  worker_connections 1024;
}

http {
  include ${pkgs.writeText "mime.types" (builtins.readFile ./mime.types)};
  include ${pkgs.writeText "fastcgi.conf" (builtins.readFile ./fastcgi.conf)};

  access_log ${nginxDir}/log/access.log;

  sendfile on;
  keepalive_timeout 65;

  upstream fastcgi_backend {
    server unix:${phpDir}/run/phpfpm/nginx;
  }

  server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name  ~^(www\.)?(?<vdomain>.+?).mage.test$;

    ssl_certificate ${nginxDir}/_wildcard.mage.test.pem;
    ssl_certificate_key ${nginxDir}/_wildcard.mage.test-key.pem;
    
    error_page 404 /404.html;
    error_page 403 /403.html;
    access_log "log/access_$vdomain.log";

    set $base "${wwwRootDir}/$vdomain";
    set $MAGE_ROOT $base;

    if (-d "$base/magento/pub") {
      set $MAGE_ROOT "$base/magento";
    }

    if (-d "$base/pub") {
      set $MAGE_ROOT "$base";
    }

    include ${magentoConf};
 
    # root $base;

    # location ~* \.php$ {
    #   fastcgi_pass phpfcgi_backend;
    #   fastcgi_index index.php;
    #   include ${fastcgiParamsFile};
    #   fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    #   fastcgi_param SCRIPT_NAME $fastcgi_script_name;
    # }
  }
}
''
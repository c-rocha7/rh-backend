{ pkgs, config, lib, ... }:

{
  packages = [ pkgs.git ];

  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_22;
    npm.enable = true;
    npm.install.enable = false;
  };

  env = {
    PORT = "4000";
    DB_HOST = "127.0.0.1";
    DB_PORT = toString config.processes.mysql.ports.main.value;
    DB_NAME = "db_rhcolaboradores";
    DB_USER = "rh";
    # Public credentials for the local development database, not production secrets.
    DB_PASSWORD = "rh-local";
  } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  };

  services.mysql = {
    enable = true;
    package = pkgs.mysql84;
    settings.mysqld = {
      bind-address = "127.0.0.1";
      port = 3307;
      mysqlx = 0;
    };
    initialDatabases = [{ name = config.env.DB_NAME; }];
    ensureUsers = [{
      name = config.env.DB_USER;
      host = "localhost";
      password = config.env.DB_PASSWORD;
      ensurePermissions = {
        "${config.env.DB_NAME}.*" = "ALL PRIVILEGES";
      };
    }];
  };

  scripts.setup.exec = ''
    set -euo pipefail
    cd "$DEVENV_ROOT"
    npm ci
  '';

  scripts.rh-db.exec = ''
    set -euo pipefail
    MYSQL_PWD="$DB_PASSWORD" exec mysql \
      --protocol=TCP --host="$DB_HOST" --port="$DB_PORT" \
      --user="$DB_USER" "$DB_NAME" "$@"
  '';

  processes.api = {
    exec = "npm run start:dev";
    after = [ "devenv:mysql:configure" ];
  };

  enterShell = ''
    echo "RH backend: Node $(node --version), npm $(npm --version)"
    echo "Install dependencies: setup"
    echo "Start MySQL and API: devenv up"
  '';

  enterTest = ''
    set -euo pipefail
    node -e 'if (process.versions.node.split(".")[0] !== "22") throw new Error("Expected Node 22")'
    npm run build
    wait_for_port "$PORT" 60
    ${pkgs.curl}/bin/curl --fail --silent --show-error "http://127.0.0.1:$PORT/colaboradores" \
      | node -e 'const data = JSON.parse(require("node:fs").readFileSync(0, "utf8")); if (!Array.isArray(data)) throw new Error("Expected a collaborators array")'
  '';
}

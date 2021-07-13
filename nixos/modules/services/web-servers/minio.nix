{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.minio;

  legacyCredentials = cfg: pkgs.writeText "minio-legacy-credentials" ''
    MINIO_ROOT_USER=${cfg.accessKey}
    MINIO_ROOT_PASSWORD=${cfg.secretKey}
  '';
in
{
  meta.maintainers = [ maintainers.bachp ];

  options.services.minio = {
    enable = mkEnableOption "Minio Object Storage";

    listenAddress = mkOption {
      default = ":9000";
      type = types.str;
      description = "Listen on a specific IP address and port.";
    };

    dataDir = mkOption {
      default = [ "/var/lib/minio/data" ];
      type = types.listOf types.path;
      description = "The list of data directories for storing the objects. Use one path for regular operation and the minimum of 4 endpoints for Erasure Code mode.";
    };

    configDir = mkOption {
      default = "/var/lib/minio/config";
      type = types.path;
      description = "The config directory, for the access keys and other settings.";
    };

    accessKey = mkOption {
      default = "";
      type = types.str;
      description = ''
        Access key of 5 to 20 characters in length that clients use to access the server.
        This overrides the access key that is generated by minio on first startup and stored inside the
        <literal>configDir</literal> directory.
      '';
    };

    secretKey = mkOption {
      default = "";
      type = types.str;
      description = ''
        Specify the Secret key of 8 to 40 characters in length that clients use to access the server.
        This overrides the secret key that is generated by minio on first startup and stored inside the
        <literal>configDir</literal> directory.
      '';
    };

    rootCredentialsFile = mkOption  {
      type = types.nullOr types.path;
      default = null;
      description = ''
        File containing the MINIO_ROOT_USER, default is "minioadmin", and
        MINIO_ROOT_PASSWORD (length >= 8), default is "minioadmin"; in the format of
        an EnvironmentFile=, as described by systemd.exec(5).
      '';
      example = "/etc/nixos/minio-root-credentials";
    };

    region = mkOption {
      default = "us-east-1";
      type = types.str;
      description = ''
        The physical location of the server. By default it is set to us-east-1, which is same as AWS S3's and Minio's default region.
      '';
    };

    browser = mkOption {
      default = true;
      type = types.bool;
      description = "Enable or disable access to web UI.";
    };

    package = mkOption {
      default = pkgs.minio;
      defaultText = "pkgs.minio";
      type = types.package;
      description = "Minio package to use.";
    };
  };

  config = mkIf cfg.enable {
    warnings = optional ((cfg.accessKey != "") || (cfg.secretKey != "")) "services.minio.`accessKey` and services.minio.`secretKey` are deprecated, please use services.minio.`rootCredentialsFile` instead.";

    systemd.tmpfiles.rules = [
      "d '${cfg.configDir}' - minio minio - -"
    ] ++ (map (x:  "d '" + x + "' - minio minio - - ") cfg.dataDir);

    systemd.services.minio = {
      description = "Minio Object Storage";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/minio server --json --address ${cfg.listenAddress} --config-dir=${cfg.configDir} ${toString cfg.dataDir}";
        Type = "simple";
        User = "minio";
        Group = "minio";
        LimitNOFILE = 65536;
        EnvironmentFile = if (cfg.rootCredentialsFile != null) then cfg.rootCredentialsFile
                          else if ((cfg.accessKey != "") || (cfg.secretKey != "")) then (legacyCredentials cfg)
                          else null;
      };
      environment = {
        MINIO_REGION = "${cfg.region}";
        MINIO_BROWSER = "${if cfg.browser then "on" else "off"}";
      };
    };

    users.users.minio = {
      group = "minio";
      uid = config.ids.uids.minio;
    };

    users.groups.minio.gid = config.ids.uids.minio;
  };
}

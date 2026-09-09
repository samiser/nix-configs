{ config, ... }:
{
  age.secrets.valheim-password.file = ../../secrets/valheim-password.age;

  services.valheim = {
    enable = true;
    serverName = "sam's cool server :)";
    worldName = "samworld";
    passwordFile = config.age.secrets.valheim-password.path;
  };
}

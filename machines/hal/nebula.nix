{

  services.nebula.networks.mesh = {
    enable = true;
    cert = "/etc/nebula/hal.crt";
    key = "/etc/nebula/hal.key";
    ca = "/etc/nebula/ca.crt";
    lighthouses = [
      "192.168.98.2"
      "192.168.98.3"
    ];
    staticHostMap = {
      "192.168.98.3" = [ "me.notho.me:4242" ];
      "192.168.98.2" = [ "zebar.de:4242" ];
    };
    firewall = {
      outbound = [
        {
          port = "any";
          proto = "any";
          host = "any";
        }
      ];
      inbound = [
        {
          port = "any";
          proto = "any";
          host = "any";
        }
      ];
    };
    relays = [
      "192.168.98.2"
      "192.168.98.3"
    ];
    settings = {
      punchy = {
        punch = true;
        delay = "1s";
        respond = true;
        respond_delay = "5s";
      };
    };
  };

}

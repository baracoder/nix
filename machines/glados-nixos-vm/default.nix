{

}: {

      system.stateVersion = "22.05";

      # Configure networking
      networking.useDHCP = false;
      networking.interfaces.eth0.useDHCP = true;

      # Create user "test"
      services.getty.autologinUser = "test";
      users.users.test.isNormalUser = true;

      # Enable passwordless ‘sudo’ for the "test" user
      users.users.test.extraGroups = ["wheel"];
      security.sudo.wheelNeedsPassword = false;
}
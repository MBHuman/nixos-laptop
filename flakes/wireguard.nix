# WireGuard VPN Configuration Template
# ==========================================
# Copy this file and fill in your actual values.
# Then import it in configuration.nix:
#   imports = [ ./hardware-configuration.nix ./wireguard.nix ];
#
# IMPORTANT: Never commit real private keys to git!
# Use privateKeyFile pointing to a file on the machine instead.

{ config, pkgs, ... }:

{
  networking.wg-quick.interfaces.wg0 = {
    # Your VPN tunnel IP address
    address = [ "10.0.0.2/24" ];

    # DNS server to use when VPN is active
    dns = [ "1.1.1.1" ];

    # Path to your private key (DO NOT put the key directly here)
    # Generate with: wg genkey | sudo tee /etc/wireguard/wg0.private
    # Set permissions: sudo chmod 600 /etc/wireguard/wg0.private
    privateKeyFile = "/etc/wireguard/wg0.private";

    peers = [
      {
        # Server public key (get from your VPN provider)
        publicKey = "SERVER_PUBLIC_KEY_HERE";

        # Route all traffic through VPN (full tunnel)
        # For split tunnel, specify only certain ranges, e.g.:
        #   allowedIPs = [ "10.0.0.0/24" ]; # only VPN subnet
        allowedIPs = [ "0.0.0.0/0" ];

        # Server endpoint (IP:port)
        endpoint = "VPN.SERVER.IP.ADDRESS:51820";

        # Keep connection alive behind NAT
        persistentKeepalive = 25;
      }
    ];
  };
}
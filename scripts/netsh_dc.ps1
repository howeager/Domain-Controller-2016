# Enables a stateful firewall
netsh adv set all state on

# Disables all firewall rules
netsh adv firewall set rule name=all new enable=no

# Sets the firewall policy to block inbound and allow outbound
netsh adv set allprofiles firewallpolicy "blockinbound, allowoutbound"

# Allows ping requests
netsh adv firewall add rule name="ping"  dir=in action=allow protocol=icmpv4

# Allows DNS requests to the domain controller
netsh adv firewall add rule name="dns" dir=out action=allow remoteport=53 protocol=udp remoteip=192.168.220.25

# Enables logging of dropped connections
netsh advfirewall set allprofiles logging droppedconnections enable

# Allows Active Directory Domain Services
netsh advfirewall firewall set rule group="Active Directory Domain Services" new enable=yes

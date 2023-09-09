#!/bin/bash -xe

# configuring firewall and routing
# firewall-cmd --get-active-zones
#firewall-cmd --get-active-zones
#firewall-cmd --zone=public --add-service openvpn
#firewall-cmd --zone=public --add-service openvpn --permanent
#firewall-cmd --list-services --zone=public
#firewall-cmd --add-masquerade
#firewall-cmd --permanent --add-masquerade
#firewall-cmd --query-masquerade
#SHARK=$(ip route get 8.8.8.8 | awk 'NR==1 {print $(NF-2)}')
#firewall-cmd --permanent --direct --passthrough ipv4 -t nat -A POSTROUTING -s 10.8.0.0/24 -o $SHARK -j MASQUERADE
#firewall-cmd --reload
yum install iptables-services -y
systemctl enable iptables
systemctl start iptables

# Enable NAT forwarding
# https://www.karlrupp.net/en/computer/nat_tutorial
# (I can't think of a reason, 
# why the AWS instance needs to connect with VPN site's
# individual computers, so assuming all remote clients
# are given 192.168.X.X addresses, they are all NAT)
SHARK=$(ip route get 8.8.8.8 | awk 'BEGIN{FS=" "};NR==1 {print $(NF-4)}')
iptables -t nat -A POSTROUTING -s 192.168.0.0/16 -o $SHARK -j MASQUERADE
#iptables in aws amazon linux when installed, only includes port 22
iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 1194 -j ACCEPT
iptables -I INPUT 5 -p udp --dport 1194 -j ACCEPT
service iptables save

# enable packer
printf 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
systemctl restart network.service

# no need to enable service, to manage openvpn process.
#systemctl -f enable openvpn@server.service
#systemctl start openvpn@server.service
#systemctl status openvpn@server.service -l


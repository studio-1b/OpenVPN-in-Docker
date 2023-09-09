#!/bin/bash -xe
# mostly tested in CentOS7, except for amazon specific commands
# and then migrated and tested in amazonlinux:2


# run openvpn config
#yum install epel-release -y
amazon-linux-extras install epel
yum install openvpn easy-rsa wget tar -y
if [ ! -f v3.0.8.tar.gz ]; then wget https://github.com/OpenVPN/easy-rsa/archive/v3.0.8.tar.gz; fi
wget https://github.com/OpenVPN/easy-rsa/archive/v3.0.8.tar.gz
tar -xf v3.0.8.tar.gz
if [ ! -d /etc/openvpn ]; then
  mkdir /etc/openvpn/
fi
if [ ! -d /etc/openvpn/easy-rsa ]; then
  mv easy-rsa-3.0.8 /etc/openvpn/
fi
cd /etc/openvpn/
if [ -d /etc/openvpn/easy-rsa-3.0.8 ]; then
  mv easy-rsa-3.0.8/ easy-rsa
fi

# configuring OpenVPN conf file, required files mention here, created later
cp /usr/share/doc/openvpn-2.4.12/sample/sample-config-files/server.conf /etc/openvpn/
# sed -i 's|;push "redirect-gateway def1 bypass-dhcp"|redirect-gateway def1 bypass-dhcp|g' /etc/openvpn/server.conf
sed -i 's/;push "dhcp-option DNS/push "dhcp-option DNS/g' /etc/openvpn/server.conf
sed -i 's/;user nobody/user nobody/g;s/;group nobody/group nobody/g;' /etc/openvpn/server.conf
sed -i 's/;topology subnet/topology subnet/g'  /etc/openvpn/server.conf
printf '\nremote-cert-eku "TLS Web Client Authentication\n"' >>/etc/openvpn/server.conf
sed -i 's/tls-auth ta.key 0/tls-crypt myvpn.tlsauth/g'  /etc/openvpn/server.conf

# creating new tls key for openvpn's ssl
openvpn --genkey --secret /etc/openvpn/myvpn.tlsauth

# make CA dir in /etc/openvpn/easy-rsa/easyrsa3/pki
# and then make the CA root keys
cd /etc/openvpn/easy-rsa/easyrsa3
cp vars.example vars
# when executed, these at bottom of lines will overwrite the values set in earlier lines
printf '# These are the default values for fields\n' >> ./vars
printf '# which will be placed in the certificate.\n' >> ./vars
printf '# Dont leave any of these fields blank.\n' >> ./vars
printf 'export KEY_COUNTRY="CA"\n'  >> ./vars
printf 'export KEY_PROVINCE="BC"\n'  >> ./vars
printf 'export KEY_CITY="Burnaby"\n'  >> ./vars
printf 'export KEY_ORG="BCIT"\n'  >> ./vars
printf 'export KEY_EMAIL="byuan6@gmail.com"\n'  >> ./vars
printf 'export KEY_EMAIL=byuan6@gmail.com\n'  >> ./vars
printf 'export KEY_CN=openvpn.example.com\n'  >> ./vars
printf 'export KEY_NAME="centosvpnserver"\n'  >> ./vars
printf 'export KEY_OU="Community"\n'  >> ./vars
export EASYRSA_CALLER="me"
source ./vars
printf 'yes\n' | ./easyrsa clean-all
#./easyrsa build-ca
printf 'AWS-CA\n' | ./easyrsa build-ca nopass
./easyrsa build-server-full awsvpnserver1 nopass
./easyrsa gen-dh
cd /etc/openvpn/easy-rsa/easyrsa3/pki
cp /etc/openvpn/easy-rsa/easyrsa3/pki/openssl-easyrsa.cnf /etc/openvpn/easy-rsa/openssl.cnf

# copying the CA and server keys generated, to directory where openvpn/server.conf expects them, in server.conf
cp /etc/openvpn/easy-rsa/easyrsa3/pki/dh.pem /etc/openvpn/dh2048.pem 
cp /etc/openvpn/easy-rsa/easyrsa3/pki/ca.crt /etc/openvpn/ca.crt
cp /etc/openvpn/easy-rsa/easyrsa3/pki/issued/awsvpnserver1.crt /etc/openvpn/server.crt
cp /etc/openvpn/easy-rsa/easyrsa3/pki/private/awsvpnserver1.key /etc/openvpn/server.key

# configuring firewall and routing
# (configuring firewall is useless in a container)
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

# configuring forwarding
# (this too, is likely useless in a container)
#printf 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf

# starting openvpn
# (this too is likely useless in a container, replaced by CMD in dockerfile)
#systemctl restart network.service
#systemctl -f enable openvpn@server.service
#systemctl start openvpn@server.service
#systemctl status openvpn@server.service -l

# generate keys for client:bob
if [ ! -d ~vpnclient ]; then useradd vpnclient; fi
if [ ! -d ~vpnclient/bob ]; then mkdir ~vpnclient/bob; fi
./easyrsa build-client-full awsvpnclientbob nopass
# copy keys for bob and create config for bob's vpn client
BOBS_VPNCLIENT_DIR=~vpnclient/bob
cp /etc/openvpn/ca.crt $BOBS_VPNCLIENT_DIR/
cp /etc/openvpn/easy-rsa/easyrsa3/pki/issued/awsvpnclientbob.crt  $BOBS_VPNCLIENT_DIR/client.crt
cp /etc/openvpn/easy-rsa/easyrsa3/pki/private/awsvpnclientbob.key  $BOBS_VPNCLIENT_DIR/client.key
cp /etc/openvpn/myvpn.tlsauth  $BOBS_VPNCLIENT_DIR/
chmod 600 $BOBS_VPNCLIENT_DIR/awsvpnclientbob.key
chmod 600 $BOBS_VPNCLIENT_DIR/myvpn.tlsauth
cd ~vpnclient
#AMI_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
#VPN_IP=$(aws --region us-east-1 ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=instance-id,Values=i-00914683ababcba7eb1" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text)
VPN_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
#printf 'bob\n'          >> client.ovpn
printf 'tls-client\n'   >> client.ovpn
printf 'ca ca.crt\n'          >> client.ovpn
printf 'cert awsavpclientbob.crt\n'    >> client.ovpn
printf 'key awsvpnclientbob.key\n'     >> client.ovpn
printf 'tls-crypt myvpn.tlsauth\n'        >> client.ovpn
printf 'remote-cert-eku "TLS Web Client Authentication"\n'  >> client.ovpn
printf 'proto udp\n'    >> client.ovpn
printf "remote $VPN_IP 1194 udp\n"  >> client.ovpn
printf 'dev tun\n'      >> client.ovpn
printf 'topology subnet\n'          >> client.ovpn
printf 'pull\n'         >> client.ovpn
printf 'user nobody\n'  >> client.ovpn
printf 'group nogroup\n' >> client.ovpn
printf 'cipher AES-256-CBC\n' >> client.ovpn

mv client.ovpn $BOBS_VPNCLIENT_DIR/client.ovpn

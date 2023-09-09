# OpenVPN-in-Docker
Experiment to see if OpenVPN can be deployed in a container
Intended to be deployed to AWS

Open questions
[ ] Can we use Amazon Linux as base for container ?
    [X] openvpn seems to require epel-release, not available on Amazon Linux 2023
        [ ] Can we use Amazon Linux v2, instead of Amazon Linux 2023
[ ] Is there any problem creating a tun: interface in container?
[ ] can ip forwarding be defined in container?
    [ ] or does it have to be defined in host?
[ ] can NAT be defined on VPN client subnet in container?
    [ ] or does it have to be defined in host?
    

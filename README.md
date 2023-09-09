# OpenVPN-in-Docker
Experiment to see if OpenVPN can be deployed in a container
Intended to be deployed to AWS

Open questions<br>
| [ ] Can we use Amazon Linux as base for container ?<br>
|     [X] openvpn seems to require epel-release, not available on Amazon Linux 2023<br>
|         [ ] Can we use Amazon Linux v2, instead of Amazon Linux 2023?<br>
| [ ] Is there any problem creating a tun: interface in container?<br>
| [ ] can ip forwarding be defined in container?<br>
|     [ ] or does it have to be defined in host?<br>
| [ ] can NAT be defined on VPN client subnet in container?<br>
|     [ ] or does it have to be defined in host?<br>
    

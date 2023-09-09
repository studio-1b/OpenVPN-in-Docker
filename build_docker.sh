#!/bin/bash

if [ "$(whoami)" != "root" ]; then
   echo "This should be run as root.  Use sudo -E"
   echo "or run 'sudo usermod -aG docker $(whoami)'"
   exit
fi

# storage location for keys
if [ ! -d ~vpnclient ]; then 
  useradd vpnclient
  chmod 770 ~vpnclient 
fi

# easyRSA version that I know the instructions for
if [ ! -f v3.0.8.tar.gz ]; then
  wget https://github.com/OpenVPN/easy-rsa/archive/v3.0.8.tar.gz
fi

#Required arguments, check in environment variables first
ENV=""
if [ "$SHELL" == "/bin/bash" ]; then
  ENV=".bashrc"
fi
EC2_FLAG=0
VPN_IP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $(NF)}')
cat /etc/os-release | grep 'Name="Amazon Linux"'
if [ $? -eq 0 ]; then
   #http://169.254.169.254/latest/dynamic/instance-identity/document
   curl http://169.254.169.254/latest/meta-data/public-ipv4 -o ec2.json
   if [ $? -eq 0 ]; then
      VPN_IP=$(<ec2.json)
      EC2_FLAG=1
   fi
fi


# docker build has to be run in project root, bc of relative paths below
# Docker/dockerfile also has relative paths, 
#   from project root, which is the working dir "docker image build" is run
sudo docker image build -t openvpn-for-aws --build-arg VPN_IP=$VPN_IP -f Docker/dockerfile .


if [ $? -eq 0 ]; then
   echo "Image built, assuming you want it uploaded to AWS S3 and ECS"
   source $ENV
   echo "Everything, we ask for, we store in plaintext in [$ENV]"
   if [ "$AWS_ACCESS_KEY_ID" == "" ]; then
      echo "We need your AWS access key ID to upload the image to S3 && ECS:"
      read AWS_ACCESS_KEY_ID
      echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> $ENV
   fi
   if [ "$AWS_SECRET_ACCESS_KEY" == "" ]; then
      echo "We need your AWS SECRET access key to upload the image to S3 && ECS:"
      read AWS_SECRET_ACCESS_KEY
      echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> $ENV
   fi
   if [ "$AWS_DEFAULT_REGION" == "" ]; then
      echo "We need your AWS default region:"
      read AWS_DEFAULT_REGION
      echo "AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> $ENV
   fi

   # awscli is easiest way to upload image to ECS
   yum install awscli -y
   echo aws_access_key_id $AWS_ACCESS_KEY_ID
   echo aws_secret_access_key $AWS_SECRET_ACCESS_KEY
   echo default.region $AWS_DEFAULT_REGION
   aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
   aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
   aws configure set default.region $AWS_DEFAULT_REGION
   # echo -n "\n\n\n\n\n" | aws configure
   aws ecr get-login-password --region $AWS_DEFAULT_REGION

   echo "if this is docker host..."
   echo "please execute config_docker_host.sh"
fi

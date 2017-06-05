#!/bin/bash
ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
echo "Nginx Webpage from custom AMI. Nginx instance ID: $ID" > /usr/share/nginx/html/index.html
aws  ec2 create-tags  --region us-east-1 --resources $ID --tags Key=Name,Value=$ID
/etc/init.d/nginx restart

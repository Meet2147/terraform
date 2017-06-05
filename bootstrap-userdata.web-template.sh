#!/bin/bash
ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
echo "Nginx Webpage from custom AMI. Nginx instance ID: $ID" > /usr/share/nginx/html/index.html
/etc/init.d/nginx restart

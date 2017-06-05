#!/bin/bash
yum -y update
yum -y install mysql-server 
/etc/init.d/mysqld start

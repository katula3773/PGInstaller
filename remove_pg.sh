#!/bin/bash
echo "Remove Postgresql 9.4.1 on CentOS 7.x"

if ps -A | grep postgres
then
    	echo "Stop postgresql process\n"
	systemctl stop postgresql-9.4
fi

systemctl disable postgresql-9.4

if yum list installed | grep postgresql94-server 
then
        echo "Remove postgresql94-server"
        yum -y remove postgresql94-server
fi

if yum list installed | grep postgresql94
then 
        echo "Remove  postgresql94 client"
        yum -y remove postgresql94
fi

if yum list installed	| grep postgresql94-contrib
then
        echo "Remove postgresql94-contrib"
        yum -y remove postgresql94-contrib
fi

if rpm -qa | grep pgdg-centos94-9.4-1 
then
    	echo "Remove pgdg-centos94-9.4-1.noarch.rpm"
	rpm -e pgdg-centos94-9.4-1
fi

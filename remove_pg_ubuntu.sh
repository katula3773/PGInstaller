#!/bin/bash


echo "Remove postgres on ubuntu"

apt-get --purge remove postgresql\*

rm -r /etc/postgresql/

rm -r /etc/postgresql-common/

rm -r /var/lib/postgresql/

userdel -r postgres

echo "--success--"
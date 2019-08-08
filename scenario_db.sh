#!/bin/bash


# Setting variables
DB_ROOT_PWD='bubuntu'
DB_USER_PWD='bubuntu'
setenforce permissive
echo "<<<<<<<<<<<<<<<<<< Update system >>>>>>>>>>>>>>>>>>>>"
#yum update -y
echo "<<<<<<<<<<<<<<<<<< Install Vim >>>>>>>>>>>>>>>>>>>>"
yum install vim -y -q
echo "<<<<<<<<<<<<<<<<<< Install epel >>>>>>>>>>>>>>>>>>>>"
yum install epel-release -y -q
echo "<<<<<<<<<<<<<<<<<< rmp  >>>>>>>>>>>>>>>>>>>>"
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-7.noarch.rpm
echo "<<<<<<<<<<<<<<<<<< Install MySQL >>>>>>>>>>>>>>>>>>>>"
yum install mysql-server -y -q
systemctl enable mysqld.service
systemctl start mysqld.service
echo "***************** Configuring MySQL ******************"
mysql --user=root -D mysql <<_EOF_
UPDATE mysql.user SET Password=PASSWORD('${DB_ROOT_PWD}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
CREATE DATABASE moodle;
CREATE USER 'moodle_devops'@'192.168.0.11'
  IDENTIFIED BY '${DB_ROOT_PWD}';
GRANT ALL
  ON moodle.*
  TO 'moodle_devops'@'192.168.0.11'
  WITH GRANT OPTION;
_EOF_
echo "<<<<<<<<<<<<<<<<<< Add bind-address  >>>>>>>>>>>>>>>>>>>>"
sed -i 's/^\[mysqld\]/\[mysqld\]\nbind-address = '192.168.0.10'/' /etc/my.cnf
systemctl restart mysqld.service
echo "<<<<<<<<<<<<<<<<<< Mysql Fix  >>>>>>>>>>>>>>>>>>>>"
PATH_MYSQL_CONF="/etc/my.cnf"
/bin/cat <<EOM >$PATH_MYSQL_CONF
[client]
default-character-set = utf8mb4

[mysqld]
innodb_file_format = Barracuda
innodb_file_per_table = 1
innodb_large_prefix
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-character-set-client-handshake

[mysql]
default-character-set = utf8mb4
EOM
systemctl restart mysqld.service



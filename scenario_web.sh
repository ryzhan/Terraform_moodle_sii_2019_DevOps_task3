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
echo "<<<<<<<<<<<<<<<<<< Install PHP 7.2 >>>>>>>>>>>>>>>>>>>>"
yum --enablerepo=remi-php72 install php php-mysql php-xml php-soap php-xmlrpc php-mbstring php-json php-gd php-mcrypt -y -q
echo "<<<<<<<<<<<<<<<<<< Opcache php.ini >>>>>>>>>>>>>>>>>>>>"
PATH_PHP_INI="/etc/php.ini"
/bin/cat <<EOM >$PATH_PHP_INI
zend_extension=/opt/remi/php72/root/usr/lib64/php/modules/opcache.so

[opcache]
opcache.enable = 1
opcache.memory_consumption = 128
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 60

opcache.use_cwd = 1
opcache.validate_timestamps = 1
opcache.save_comments = 1
opcache.enable_file_override = 0
EOM
echo "<<<<<<<<<<<<<<<<<< Install and enable Apache >>>>>>>>>>>>>>>>>>>>"
yum --enablerepo=epel,remi install httpd -y -q
systemctl start httpd.service
systemctl enable httpd.service
echo "<<<<<<<<<<<<<<<<<< Install other >>>>>>>>>>>>>>>>>>>>"
yum install php72-php-fpm php72-php-gd php72-php-json php72-php-mbstring php72-php-mysqlnd php72-php-xml php72-php-xmlrpc php72-php-opcache -y -q
yum --enablerepo="base" -y -q install yum-utils
yum-config-manager --enable remi-php72
yum install php-pecl-zip php-intl -y -q
systemctl restart httpd.service
echo "<<<<<<<<<<<<<<<<<<  Install wget  >>>>>>>>>>>>>>>>>>>>"
yum install wget -y -q
echo "<<<<<<<<<<<<<<<<<<  Download Moodle 3.7  >>>>>>>>>>>>>>>>>>>>"
cd
wget https://download.moodle.org/download.php/direct/stable37/moodle-3.7.1.tgz -q
tar -zxf moodle-3.7.1.tgz -C /var/www/html
echo "<<<<<<<<<<<<<<<<<< Make dir  >>>>>>>>>>>>>>>>>>>>"
mkdir /var/www/html/moodledata
echo "<<<<<<<<<<<<<<<<<<  Permisions  >>>>>>>>>>>>>>>>>>>>"
chmod -R 0755 /var/www/html/moodle
chown -R apache.apache /var/www/html/moodle 
chmod -R 777 /var/www/html/moodledata
chown -R apache.apache /var/www/html/moodledata
echo "<<<<<<<<<<<<<<<<<<  Virtual host  >>>>>>>>>>>>>>>>>>>>"
PATH_VIRTUAL_HOST_CONF="/etc/httpd/conf.d/moodle.sii2019devops.com.conf"
/bin/cat <<EOM >$PATH_VIRTUAL_HOST_CONF
<VirtualHost *:80>
 ServerName moodle.local_sii2019devops
 DocumentRoot /var/www/html/moodle
 ErrorLog /var/log/httpd/moodle.local_error_log
 CustomLog /var/log/httpd/moodle.local_access_log combined 
 DirectoryIndex index.html index.htm index.php index.php4 index.php5
<Directory /var/www/html/moodle>
 Options -Indexes +IncludesNOEXEC +SymLinksIfOwnerMatch
 AllowOverride All
 Require all granted
</Directory>
</VirtualHost>
EOM
systemctl restart httpd.service
echo "<<<<<<<<<<<<<<<<<<  CLI Instal Moodle  >>>>>>>>>>>>>>>>>>>>"
/usr/bin/php /var/www/html/moodle/admin/cli/install.php --wwwroot='http://10.0.0.10' --dataroot='/var/www/html/moodledata' --dbtype='mariadb' --dbhost='192.168.0.10' --dbuser='moodle_devops' --dbpass=bubuntu --dbport='3306'  --shortname='moodle.local' --adminuser='admin' --adminpass='bubuntu' --adminemail='admin@yo.lo' --fullname='moodle.local_sii2019devops' --non-interactive --agree-license
sed -i -e "s/10.0.0.10/$WEB_IP_NAT/g" /var/www/html/moodle/config.php
cat /var/www/html/moodle/config.php
chmod o+r /var/www/html/moodle/config.php
systemctl restart httpd.service
echo "<<<<<<<<<<<<<<<<<<  End  >>>>>>>>>>>>>>>>>>>>"


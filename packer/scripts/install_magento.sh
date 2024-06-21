#!/bin/bash

update_os () {
   sudo yum update -y
}

install_nginx () {

sudo amazon-linux-extras install -y nginx1

sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf
sudo rm -rf /tmp/nginx.conf

sudo usermod -g nginx ec2-user

sudo mkdir -p /var/www/html/releases/
sudo chown -R ec2-user:nginx /var/www/html/
sudo -u ec2-user bash -c "ln -s /tmp/ /var/www/html/current"
sudo mkdir -p /mnt/efs
sudo chown -R ec2-user:nginx /mnt/efs

sudo systemctl enable nginx
sudo systemctl restart nginx

}

install_php () {

sudo amazon-linux-extras enable php7.4

sudo yum install -y php php-fpm php-pdo php-mysqlnd php-opcache php-xml php-gd php-devel php-intl php-mbstring php-bcmath php-json php-iconv php-soap php-sodium

sudo cp /tmp/php-fpm.conf /etc/php-fpm.conf 
sudo rm -rf /tmp/php-fpm.conf

sudo sed -i 's/memory_limit = 128M/memory_limit = 1024M/g' /etc/php.ini
sudo sed -i 's/;realpath_cache_size = 4096k/realpath_cache_size = 10M/g' /etc/php.ini
sudo sed -i 's/;realpath_cache_ttl = 120/realpath_cache_ttl = 7200/g' /etc/php.ini

sudo cp /tmp/10-opcache.ini /etc/php.d/10-opcache.ini
sudo rm -rf /tmp/10-opcache.ini

sudo systemctl enable php-fpm
sudo systemctl restart php-fpm

}

install_varnish () {

sudo amazon-linux-extras install -y epel

sudo yum install -y varnish

sudo sed -i 's/6081/80/g' /etc/varnish/varnish.params

sudo cp /tmp/default.vcl /etc/varnish/default.vcl
sudo rm -rf /tmp/default.vcl

sudo systemctl enable varnish
sudo systemctl restart varnish
sudo yum remove -y epel-release
sudo yum clean all

}

configure_ssh_keys () {

cp /tmp/id_ed25519 /home/ec2-user/.ssh/
chmod 400 /home/ec2-user/.ssh/id_ed25519
sudo rm -rf /tmp/id_ed25519

cp /tmp/config /home/ec2-user/.ssh/config
chmod 400 /home/ec2-user/.ssh/config
sudo rm -rf /tmp/config

# aws.internal key for rsync purposes
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOD91LEldCnUQQiwVRV/cgiSz7S41dV3TPXF6+kJ9MsR ec2-user@aws.internal" >> ~/.ssh/authorized_keys
# PHPro Jenkins key
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCt5WwggYM/E6iOBakS2skKVDgk3GI5pkHGyTwCBP3ccVAS8UUCnT8Avs5GWXkia+AbT9SjkhiBrfNcIi2K3EvCHPbcGIHg5T8tMe245GxyfcT/2ZipSJigKMzyC58shIJYjDyBZa9bA/SCRopVTZ/gnyC+ZWqSLy3HXkS0/1FYrgS7hBCp+Y78QTAFhqIJ+EU0dwFERQ/9ALfgOy/BmeMMaaf/q5WLE9oy1RHuLCurp3VtMMTiqvg5nF1GLVVGHHhDmV3xhFLRII2M00ya9GBhHfz1xMyMXUdKIcVlng7tq7V1otsEXp367qikN6fMfREVEX07ub9O0RowK78p9/8Mj47ipyT6v4o7usLiOTw75+fQ1FmB+3LJlASSaiUGlpqJbJ15AZfq641yTykBl2zVoVSHsYq0zFvfUjZ7ONoDPJrKdqv7wPvNDCAo5JSk93Ir1VeRh3QhdIJs8QprqbFa031Zds31GdsWBj3Su1wb+g1k5taW4A4r7cOgMSFZoopBprXXBHIn9Dne8NV0Oamz9lP0hVCT4RxXVrP7V/R8/bG1Yg2mR5ZGK8XbFz49JMX5nxxTqpsyDhnOiswOmIsleTJbJL57Rk/Z2oAw0+bCnPvOSiM2mnjcKEZNHi731CBgCDBeftsrKgPkJ5cv7AWoOm/CKbibrVI4Vmo+zduyqQ== New Jenkins Key" >> ~/.ssh/authorized_keys

}

install_awslogs () {

sudo yum install -y awslogs
sudo cp /tmp/awslogs.conf /etc/awslogs/awslogs.conf 
sudo rm -rf /tmp/awslogs.conf
sudo cp /tmp/awscli.conf /etc/awslogs/awscli.conf
sudo rm -rf /tmp/awscli.conf

}

update_os
install_php
install_nginx
install_varnish
configure_ssh_keys
install_awslogs

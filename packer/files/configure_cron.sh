#!/bin/bash

# Install and configure supervisor
sudo amazon-linux-extras install -y epel
sudo yum install -y supervisor
sudo mv /tmp/magento-salesforce-consumer.ini /etc/supervisord.d/
sudo mv /tmp/supervisord.service /etc/systemd/system/supervisord.service
sudo systemctl enable supervisord.service
sudo systemctl start supervisord.service
sudo yum remove -y epel-release
sudo yum clean all

# Install AMQP dependency/library for PHP
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/librabbitmq-0.8.0-3.el7.x86_64.rpm
wget http://mirror.centos.org/centos/7/os/x86_64/Packages/librabbitmq-devel-0.8.0-3.el7.x86_64.rpm
sudo yum localinstall librabbitmq-devel-0.8.0-3.el7.x86_64.rpm 
sudo yum localinstall librabbitmq-0.8.0-3.el7.x86_64.rpm 
sudo pecl install ampq
sudo touch /etc/php.d/30-ampq.ini
sudo echo "extension=amqp.so" > /etc/php.d/30-amqp.ini

# Configure the Magento cronjob
crontab -l | { cat; echo "* * * * *  ! test -e /var/www/html/current/var/.maintenance.flag && /usr/bin/php /var/www/html/current/bin/magento cron:run 2>&1 | grep -v 'Ran jobs by schedule' >> /var/www/html/current/var/log/magento.cron.log"; } | crontab -

# Setting some required variables
SSH_USER="ec2-user"
RELEASE_ROOT="/var/www/html"

# Set default region to current region
AWS_DEFAULT_REGION=$(curl -s http://instance-data/latest/meta-data/placement/region)
# Determine the environment name using the security group name
ENVIRONMENT_NAME=$(curl -s http://instance-data/latest/meta-data/security-groups | grep MagentoStack | head -n 1 | cut -d'-' -f1)
# Determine internal IP of one of the web servers using the above environment name
WEB1=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:aws:autoscaling:groupName,Values=${ENVIRONMENT_NAME}-Magento*Web* --output text --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --region ${AWS_DEFAULT_REGION} | head -n1)

sudo sed -i "s/__REGION__/${AWS_DEFAULT_REGION}/g" /etc/awslogs/awscli.conf
sudo sed -i "s/__TYPE__/Cron/g" /etc/awslogs/awslogs.conf
sudo sed -i "s/__ENVIRONMENT__/${ENVIRONMENT_NAME}/g" /etc/awslogs/awslogs.conf
sudo systemctl enable awslogsd
sudo systemctl start awslogsd

if [ -z "$WEB1" ]
then
  echo "Stack not yet fully deployed, please ensure the stack has been fully deployed and trigger a deploy on Jenkins"
  exit 0
fi

# Waiting for the WEB1 server to be up and running before proceeding
until printf "" 2>>/dev/null >>/dev/tcp/${WEB1}/22; do sleep 15; done

# Checking the current release link on WEB1, if it set to "/tmp/" it means it is not initialized yet, so we don't sync anything (a deploy on Jenkins needs to be triggered first)
CURRENT_RELEASE_LINK=$(ssh ${SSH_USER}@${WEB1} readlink -f ${RELEASE_ROOT}/current)
if [ "${CURRENT_RELEASE_LINK}" = "/tmp" ]
then
  echo "Trigger a deploy on Jenkins first"
  exit 0
fi

# Pulling the "date" from the current active release from the WEB1 server
DATE=$(ssh ${SSH_USER}@${WEB1} readlink -f ${RELEASE_ROOT}/current | awk -F/ '{print $NF}')
# rsync the active release
rsync -rcl ${SSH_USER}@${WEB1}:${RELEASE_ROOT}/releases/${DATE} ${RELEASE_ROOT}/releases/
# Activate the latest release
unlink ${RELEASE_ROOT}/current && ln -s ${RELEASE_ROOT}/releases/${DATE}/ ${RELEASE_ROOT}/current
# Clear the Magento cache
cd ${RELEASE_ROOT}/releases/${DATE} && bin/magento cache:flush

#!/bin/bash

# Setting some required variables
SSH_USER="ec2-user"
RELEASE_ROOT="/var/www/html"

# Set default region to current region
AWS_DEFAULT_REGION=$(curl -s http://instance-data/latest/meta-data/placement/region)
# Determine the environment name using the security group name
ENVIRONMENT_NAME=$(curl -s http://instance-data/latest/meta-data/security-groups | grep MagentoStack | head -n 1 | cut -d'-' -f1)
# Determine internal IP using the above environment name
CRON=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=tag:aws:autoscaling:groupName,Values=${ENVIRONMENT_NAME}-Magento*Cron* --output text --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --region ${AWS_DEFAULT_REGION})

sudo sed -i "s/__REGION__/${AWS_DEFAULT_REGION}/g" /etc/awslogs/awscli.conf
sudo sed -i "s/__TYPE__/Web/g" /etc/awslogs/awslogs.conf
sudo sed -i "s/__ENVIRONMENT__/${ENVIRONMENT_NAME}/g" /etc/awslogs/awslogs.conf
sudo systemctl enable awslogsd
sudo systemctl start awslogsd

if [ -z "$CRON" ]
then
  echo "Stack not yet fully deployed, please ensure the stack has been fully deployed and trigger a deploy on Jenkins"
  exit 0
fi

# Waiting for the CRON server to be up and running before proceeding
until printf "" 2>>/dev/null >>/dev/tcp/${CRON}/22; do sleep 15; done

# Checking the current release link on CRON, if it set to "/tmp/" it means it is not initialized yet, so we don't sync anything (a deploy on Jenkins needs to be triggered first) 
CURRENT_RELEASE_LINK=$(ssh ${SSH_USER}@${CRON} readlink -f ${RELEASE_ROOT}/current)
if [ "${CURRENT_RELEASE_LINK}" = "/tmp" ]
then
  echo "Trigger a deploy on Jenkins first"
  exit 0
fi

# Pulling the "date" from the current active release from the CRON server
DATE=$(ssh ${SSH_USER}@${CRON} readlink -f ${RELEASE_ROOT}/current | awk -F/ '{print $NF}')
# rsync the active release
rsync -rcl ${SSH_USER}@${CRON}:${RELEASE_ROOT}/releases/${DATE} ${RELEASE_ROOT}/releases/
# Activate the latest release
unlink ${RELEASE_ROOT}/current && ln -s ${RELEASE_ROOT}/releases/${DATE}/ ${RELEASE_ROOT}/current
# Clear the Magento cache
cd ${RELEASE_ROOT}/releases/${DATE} && bin/magento cache:flush

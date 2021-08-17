#!/bin/bash

aws cloudformation create-stack \
	--stack-name "Magento-$RANDOM" \
	--template-url "https://magento-quickstart-mod-c6926dad.s3.eu-west-1.amazonaws.com/github-magento-gluo/templates/magento-master.template.yaml" \
	--capabilities CAPABILITY_IAM \
	--disable-rollback \
	--parameters file://parameters.json

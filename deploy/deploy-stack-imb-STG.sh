#!/bin/bash

aws cloudformation create-stack \
	--stack-name "STG-Magento-$RANDOM" \
	--template-url "https://stg-magento-quickstart-895248839606.s3.us-east-2.amazonaws.com/cloudformation/magento-master.template.yaml" \
	--capabilities CAPABILITY_IAM \
	--disable-rollback \
        --parameters file://../parameters/parameters-imb-STG.json \
        --profile imb-STG

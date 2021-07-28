# Deploy Magento Stack

AWS REGION: eu-central-1

```bash
cd deploy/
./deploy-stack.sh
```

## Template inheritance

```
magento-master.template > magento.template > webserver.temlate
					   > cron.template
```

## S3 Artifacts

bucket **magento-quickstart-mod-c6926dad** contains all necessary files:

- github-magento-gluo/ > repository with cfn templates/scripts
  - make sure you checkout the **submodules** so that you upload those as well
- Magento-CE-...tar.gz > Magento source code

#### When making changes to the cfn templates

1. Make changes locally
2. Delete the old "github-magento-gluo" folder from the S3 bucket
3. Upload the folder again with your changes included
4. Redeploy the CFN stack.



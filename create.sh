#!/bin/bash

DEVOPS_ACCOUNT=545443424250
DEV_ACCOUNT=866218848532
PROD_ACCOUNT=325283546896

function waitForStackCreateComplete() {
	echo "Waiting for stack $1 creation in $2 account...."
	aws cloudformation wait stack-create-complete --stack-name $1 --region eu-west-1 --profile $2

	if [ "$?" != "0" ]; then
		echo "ERROR: Stack $1 failed to create in $2 account"
		exit 1
	fi

	echo "Stack $1 created in $2 account."
}

# (DevOps Account) Create KMS key, an S3 bucket for build artifacts, CodeBuild role and policy, Pipeline role and policy and CodeBuild project
aws cloudformation create-stack --stack-name 'devops-01-prereqs' \
	--template-body file://devops-01-prereqs.yaml --region eu-west-1 \
    --parameters ParameterKey=DevAccount,ParameterValue=$DEV_ACCOUNT \
		ParameterKey=ProductionAccount,ParameterValue=$PROD_ACCOUNT \
	--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
	--profile aws-serverlesspizza-devops
waitForStackCreateComplete 'devops-01-prereqs' 'aws-serverlesspizza-devops'

# (All Accounts) Create CloudFormation roles in all AWS accounts
CMK_ARN=`aws cloudformation list-exports --query "Exports[?Name=='KMSKeyArn'].Value" --output text --profile aws-serverlesspizza-devops`
ARTIFACT_BUCKET=`aws cloudformation list-exports --query "Exports[?Name=='ArtifactBucket'].Value" --output text --profile aws-serverlesspizza-devops`

aws cloudformation create-stack --stack-name 'devops-02-cf-roles' \
	--template-body file://devops-02-cf-roles.yaml --region eu-west-1 \
	--parameters ParameterKey=S3Bucket,ParameterValue=$ARTIFACT_BUCKET \
		ParameterKey=DevOpsAccount,ParameterValue=$DEVOPS_ACCOUNT \
		ParameterKey=CMKARN,ParameterValue=$CMK_ARN \
	--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
	--profile aws-serverlesspizza-devops

aws cloudformation create-stack --stack-name 'devops-02-cf-roles' \
	--template-body file://devops-02-cf-roles.yaml --region eu-west-1 \
	--parameters ParameterKey=S3Bucket,ParameterValue=$ARTIFACT_BUCKET \
		ParameterKey=DevOpsAccount,ParameterValue=$DEVOPS_ACCOUNT \
		ParameterKey=CMKARN,ParameterValue=$CMK_ARN \
	--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
	--profile aws-serverlesspizza-nonprod

aws cloudformation create-stack --stack-name 'devops-02-cf-roles' \
	--template-body file://devops-02-cf-roles.yaml --region eu-west-1 \
	--parameters ParameterKey=S3Bucket,ParameterValue=$ARTIFACT_BUCKET \
		ParameterKey=DevOpsAccount,ParameterValue=$DEVOPS_ACCOUNT \
		ParameterKey=CMKARN,ParameterValue=$CMK_ARN \
	--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
	--profile aws-serverlesspizza-prod

waitForStackCreateComplete 'devops-02-cf-roles' 'aws-serverlesspizza-devops'
waitForStackCreateComplete 'devops-02-cf-roles' 'aws-serverlesspizza-nonprod'
waitForStackCreateComplete 'devops-02-cf-roles' 'aws-serverlesspizza-prod'

# (DevOps Account) Create the AWS artifact policy
aws cloudformation create-stack --stack-name 'devops-03-artifact-bucket-policy' \
	--template-body file://devops-03-artifact-bucket-policy.yaml --region eu-west-1 \
	--parameters ParameterKey=DevAccount,ParameterValue=$DEV_ACCOUNT \
		ParameterKey=ProductionAccount,ParameterValue=$PROD_ACCOUNT \
	--capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
	--profile aws-serverlesspizza-devops
waitForStackCreateComplete 'devops-03-artifact-bucket-policy' 'aws-serverlesspizza-devops'

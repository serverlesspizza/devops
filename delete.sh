#!/bin/bash

ARTIFACT_BUCKET=`aws cloudformation list-exports --query "Exports[?Name=='ArtifactBucket'].Value" --output text --profile aws-serverlesspizza-devops`
aws s3 rb s3://$ARTIFACT_BUCKET --force

function waitForStackDeleteComplete() {
	echo "Waiting for stack $1 deletion in $2 account...."
	aws cloudformation wait stack-delete-complete --stack-name $1 --region eu-west-1 --profile $2

	if [ "$?" != "0" ]; then
		echo "ERROR: Stack $1 failed to delete"
		exit 1
	fi

	echo "Stack $1 deleted in $2 account."
}

function deleteStack() {
    echo "Deleting stack $1 in $2 account"
    aws cloudformation delete-stack --stack-name $1 --region eu-west-1 --profile $2
    waitForStackDeleteComplete $1 $2
}

deleteStack 'devops-03-artifact-bucket-policy' 'aws-serverlesspizza-devops'
deleteStack 'devops-02-cf-roles' 'aws-serverlesspizza-prod'
deleteStack 'devops-02-cf-roles' 'aws-serverlesspizza-nonprod'
deleteStack 'devops-02-cf-roles' 'aws-serverlesspizza-devops'
deleteStack 'devops-01-prereqs' 'aws-serverlesspizza-devops'

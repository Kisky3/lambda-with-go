#!/bin/bash

pwd
export SAM_CLI_TELEMETRY=0

REGION="ap-northeast-1"
S3BUCKET="v6-sd-seminor-room-sandbox"


make
cd sample

aws cloudformation package --force-upload --template-file sam.yaml --s3-bucket $S3BUCKET --output-template sam-export.yaml --region $REGION

aws cloudformation deploy --force-upload --template-file sam-export.yaml --s3-bucket $S3BUCKET \
  --s3-prefix $FUNCTION --stack-name "${TAG}-${STAGE}" --capabilities "CAPABILITY_IAM" --region $REGION \
  --parameter-overrides functionname=$FUNCTION

aws cloudformation describe-stacks --stack-name "${TAG}-${STAGE}" --query 'Stacks[]' --region $REGION

exit 0


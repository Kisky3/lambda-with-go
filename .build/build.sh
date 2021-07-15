#!/bin/bash

env
yum install -y tree
yum install -y curl
yum install -y perl
yum install -y jq

sam --version

tree -d -l .

SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR_SLACK_WEBHOOK"
SLACK_JSON="backend/lambda-with-go/.build/slack_message.json"
GITURL="$CODEBUILD_SOURCE_REPO_URL"
REGION="ap-northeast-1"
#DATETIME=`date -u -d '9 hours' "+%Y/%m/%d-%H:%M:%S"`
DATETIME=`date -d '9 hours' "+%Y/%m/%d-%H:%M:%S"`
SITE_NAME="sd-seminer-backend-go"

sed s@%%BRANCH%%@$CODEBUILD_WEBHOOK_HEAD_REF@ -i $SLACK_JSON
sed s@%%DATETIME%%@$DATETIME@ -i $SLACK_JSON
sed s@%%USER_NAME%%@$SITE_NAME@ -i $SLACK_JSON
sed s@%%COMMIT%%@$GITURL@ -i $SLACK_JSON

if [[ `echo $CODEBUILD_WEBHOOK_HEAD_REF | grep '/tags/'` ]]; then
  echo 'trigger is tags'
else
  exit 1
fi

export TAG=$(echo $CODEBUILD_WEBHOOK_HEAD_REF | cut -d '/' -f 3 | cut -d '.' -f 1)
export STAGE=$(echo $CODEBUILD_WEBHOOK_HEAD_REF | cut -d '/' -f 3 | cut -d '.' -f 2)
export FUNCTION="${TAG}-${STAGE}"

if [[! "$TAG" = 'lambdawithgo'  ]]; then
  MESSAGE="tag名が正しくないのです usage: lambdawithgo-[stage].[version]"
  echo $MESSAGE
  sed s@%%MESSAGE%%@"$MESSAGE"@ -i $SLACK_JSON
  curl -X POST -d @"${SLACK_JSON}" $SLACK_WEBHOOK
  exit 1
fi

cd backend/lambda-with-go/5/
/bin/bash ./build.sh
cd ../../../
ls -l

ENDPOINT=`aws cloudformation describe-stacks --stack-name "${TAG}-${STAGE}" --query 'Stacks[]' --region $REGION | jq '.[0]["Outputs"][0]["OutputValue"]'|sed -e 's/"/ /g'`
MESSAGE="${ENDPOINT}をリリースしました"
echo $MESSAGE
sed s@%%MESSAGE%%@"$MESSAGE"@ -i $SLACK_JSON

curl -X POST -d @"${SLACK_JSON}" $SLACK_WEBHOOK

exit 0

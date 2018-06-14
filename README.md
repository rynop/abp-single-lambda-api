# abp-single-lambda-api

[aws-blueprint](https://github.com/rynop/aws-blueprint) example for an API backed by a single lambda

Each branch of this repo is a different language for the same example app.

##  Single lambda

This example sets up a CI/CD for a single lambda, fronted by CloudFront and API Gateway.   

*  **Resources CloudFormation:** [aws/cloudformation/cf-apig-single-lambda-resources.yaml](./aws/cloudformation/cf-apig-single-lambda-resources.yaml)
*  **CI/CD CloudFormation:** [single-lambda-test-staging-prod.yaml](https://github.com/rynop/aws-blueprint/pipelines/cicd/single-lambda-test-staging-prod.yaml)

## Setup

1. Run the setup script from your local git repo dir: 
    ```
    wget -q https://raw.githubusercontent.com/rynop/abp-single-lambda-api/master/bin/setup.sh; bash setup.sh; rm setup.sh
    ```

    This:
    *  Downloads the branch of of your favorite programming language, and common [aws](./aws) dir out of `master` branch.  
    *  Sets `NestedStacksS3Bucket` and s3 versions of your `nested-stacks` in your [resources CloudFormation](./aws/cloudformation/cf-apig-single-lambda-resources.yaml) file.
1. Create your "resources" (CloudFront, API Gateway etc) stacks using `aws/cloudformation/cf-apig-single-lambda-resources.yaml` in your repo. Stack naming convention is `[stage]--[repo]--[branch]--[eyecatcher]--r`. Ex: `prod--abp-single-lambda-api--master--ResizeImage--r`:
    *  Create a stack for your `test` and `production` stages.  You will have 2 root stacks.  The `prod` stack takes care of both `prod` and `staging` resources.
    *  The `Outputs` tab in the CloudFormation UI for each root stack has commands you will run in the next steps.  Outputs that start with `Run*` you should run from your CLI.
1. Some of the Lambda configuration is stored in [Systems manager parameter store](https://console.aws.amazon.com/systems-manager/parameters) with the convention based prefix `/<stage>/<repoName>/<branch>/<lambdaName>/`.  Ex: `aws ssm put-parameter --name "/prod/abp-single-lambda-api/master/ResizeImage/lambdaExecutionRoleArn" --type "String" --value 'arn:aws:iam::accountId:role/roleName'`.  These keys are required **per** stage:
    * `/<stage>/<repoName>/<branch>/<lambdaName>/lambdaExecutionRoleArn` (don't create for `staging` stage.  `staging` uses the `prod` `lambdaExecutionRoleArn`).  The output of the [Resources CloudFormation stack](./aws/cloudformation/cf-apig-single-lambda-resources.yaml) contains a `SsmSetLambdaExecutionRoleCmd` value that is an aws CLI command that sets this for you.
    * `/<stage>/<repoName>/<branch>/<lambdaName>/lambdaTimeout`
    * `/<stage>/<repoName>/<branch>/<lambdaName>/lambdaMemory`
1.  Setup env vars **per** stage.  All keys in the `lambdaEnvs` namespace are automatically added your your lambda's env.  They can optionally be encrypted in systems manager param store, we handle all the decoding complexity (if you use the default KMS key).
    * `/<stage>/<repoName>/<branch>/<lambdaName>/lambdaEnvs/<env var name>`.  Ex: `/prod/abp-single-lambda-api/master/ResizeImage/lambdaEnvs/MY_VAR`    
    * Run the `SsmSetXFromCdnEnvVarCmd` output value from the [Resources CloudFormation stack](./aws/cloudformation/cf-apig-single-lambda-resources.yaml).  It sets `X_FROM_CDN` (used by the example code in this repo).
    * These env vars get set for your in the lambda configuration: `APP_STAGE`
1.  Create a Github user (acct will just be used to read repos for CI/CD), give it read auth to your github repo.  Create a personal access token for this user at https://github.com/settings/tokens.  This token will be used by the CI/CD to pull code.    
1.  Go through the `README.md` of the **language branch** you copied, language specific setup and for stack parameter values that will be used in CI/CD stack creation (next step).
1.  Create a CloudFormation stack for your CI/CD using [single-lambda-test-staging-prod.yaml](https://github.com/rynop/aws-blueprint/blob/master/pipelines/cicd/single-lambda-test-staging-prod.yaml) with the stack naming convention of `[repo]--[branch]--[eyecatcher]--cicd`.  Ex: `abp-single-lambda-api--master--ResizeImage--cicd`.  
1. Commit your code and the CI/CD CodePipline will automatically run.
1. The domain your app can be reached, is located in the `Outputs` tab of the resources CloudFormation stack at key `CNAME`.
1. Edit your cloudfront > dist settings > change Security policy to `TLSv1.1_2016`.  CloudFormation does not support this parameter yet.
1. Create a DNS entry in route53 for production that consumers will use.  The cloud formation creates one for `prod--` but you do not want to use this as the CloudFormation can be deleted.

## Backup info (if you care about inner workings)

### The Lambda publishing process

The publishing process is multi-stage, with manual approvals, all handled in an automated fashion.  Here are the details:

*  `PublishTest` step: 
    1.  Create Lambda if DNE. Set env vars from [ssm](https://console.aws.amazon.com/systems-manager/parameters) namespace `/test/[repo]/[branch]/[LAMBDA_NAME]/lambdaEnvs`, role from `/test/[repo]/[branch]/[LAMBDA_NAME]/lambdaExecutionRoleArn`, timeout from `/test/[repo]/[branch]/[LAMBDA_NAME]/lambdaTimeout`, memory from `/test/[repo]/[branch]/[LAMBDA_NAME]/lambdaMemory`,
    1.  Create Lambda version & alias `test`
*  When CodePipeline `ApproveTest` approved, `PublishStaging` step: : 
    1.  Update lambda. Set env vars from [ssm](https://console.aws.amazon.com/systems-manager/parameters) namespace `/staging/[repo]/[branch]/[LAMBDA_NAME]/lambdaEnvs`, role from `/prod/[repo]/[branch]/[LAMBDA_NAME]/lambdaExecutionRoleArn`, timeout from `/staging/[repo]/[branch]/[LAMBDA_NAME]/lambdaTimeout`, memory from `/test/[repo]/[branch]/[LAMBDA_NAME]/lambdaMemory`.  
    1.  Copy zip package to `s3://${S3_BUCKET_CONTAINING_PACKAGES}/${S3_PATH_TO_PACKAGES}/${codeSha256}.zip` where `codeSha256` is the just deployed `staging` lambda `CodeSha256` configuration value.  This ensures the code deployed to staging is the code that will be deployed to `prod`.
    1.  Create Lambda version & alias `staging`
*  When CodePipeline `ApproveStaging` approved, `PublishProd` step: : 
    1.  Update lambda using `${codeSha256}.zip`. Set env vars from [ssm](https://console.aws.amazon.com/systems-manager/parameters) namespace `/prod/[repo]/[branch]/[LAMBDA_NAME]/lambdaEnvs`, role from `/prod/[repo]/[branch]/[LAMBDA_NAME]/lambdaExecutionRoleArn`, timeout from `/staging/[repo]/[branch]/[LAMBDA_NAME]/lambdaTimeout`, memory from `/prod/[repo]/[branch]/[LAMBDA_NAME]/lambdaMemory`.  
    1.  Create Lambda version & alias `prod` 

# abp-single-lambda-api

[aws-blueprint](https://github.com/rynop/aws-blueprint) example for an API backed by a single lambda

Each branch of this repo is a different language for the same example app.

##  Single lambda

This example sets up a CI/CD for a single lambda, fronted by CloudFront and API Gateway.   

*  **Resources CloudFormation:** [aws/cloudformation/cf-apig-single-lambda-resources.yaml](./aws/cloudformation/cf-apig-single-lambda-resources.yaml)
*  **CI/CD CloudFormation:** [single-lambda-test-staging-prod.yaml](https://github.com/rynop/aws-blueprint/pipelines/cicd/single-lambda-test-staging-prod.yaml)

## Setup

1. Run the setup script: `curl -L https://git.io/n-install | bash`.  This does:
    *  Downloads the branch of of your favorite programming language, and common [aws](./aws) dir out of `master` branch.  
    *  Figures out and sets the s3 versions of your `nested-stacks` in your [resources CloudFormation](./aws/cloudformation/cf-apig-single-lambda-resources.yaml) file.
1. Create your "resources" (CloudFront, API Gateway etc) stacks using `aws/cloudformation/cf-apig-single-lambda-resources.yaml` in your repo. Stack naming convention is `[stage]--[repo]--[branch]--[eyecatcher]--r`. Ex: `prod--abp-single-lambda-api--master--ResizeImage--r`:
    *  Create a stack for your `test` and `production` stages.  You will have 2 root stacks.  The `prod` stack takes care of both `prod` and `staging` resources.
    *  The `Outputs` tab in the CloudFormation UI for each root stack has commands you will run in the next steps.
1. Some of the Lambda configuration is stored in [Systems manager parameter store](https://console.aws.amazon.com/systems-manager/parameters) with the convention based prefix `/<stage>/<repoName>/<branch>/<lambdaName>/`.  Ex: `aws ssm put-parameter --name "/prod/abp-single-lambda-api/master/ResizeImage/lambdaExecutionRoleArn" --type "String" --value 'arn:aws:iam::accountId:role/roleName'`.  These keys are required **per** stage:
    * `/<stage>/<repoName>/<branch>/<lambdaName>/lambdaExecutionRoleArn` (don't create for `staging` stage.  `staging` uses the `prod` `lambdaExecutionRoleArn`).  The output of the [Resources CloudFormation stack](./aws/cloudformation/cf-apig-single-lambda-resources.yaml) contains a `SsmSetLambdaExecutionRoleCmd` value that is an aws CLI command that sets this for you.
    * `/<stage>/<repoName>/<branch>/<lambdaName>/lambdaTimeout`
    * `/<stage>/<repoName>/<branch>/<lambdaName>/lambdaMemory`
1.  Setup env vars **per** stage.  All keys in the `lambdaEnvs` namespace are automatically added your your lambda's env.  They can optionally be encrypted in systems manager param store, we handle all the decoding complexity (if you use the default KMS key).
    * `/<stage>/<repoName>/<branch>/<lambdaName>/lambdaEnvs/<env var name>`.  Ex: `/prod/abp-single-lambda-api/master/ResizeImage/lambdaEnvs/MY_VAR`    
    * The output of the [Resources CloudFormation stack](./aws/cloudformation/cf-apig-single-lambda-resources.yaml) contains a `SsmSetXFromCdnEnvVarCmd` value that is an aws ssm command that can be run on your CLI to set the `X_FROM_CDN` env var (used by the example code).
    * The following env vars will automatically be set in the lambda configuration: `APP_STAGE`
1.  Create a Github user (acct will just be used to read repos for CI/CD), give it read auth to your github repo.  Create a personal access token for this user at https://github.com/settings/tokens.  This token will be used by the CI/CD to pull code.    
1.  Go through the `README.md` of the **language branch** you copied, language specific setup and for stack parameter values that will be used in CI/CD stack creation (next step).
1.  Create a CloudFormation stack for your CI/CD using [single-lambda-test-staging-prod.yaml](https://github.com/rynop/aws-blueprint/pipelines/cicd/single-lambda-test-staging-prod.yaml) with the stack naming convention of `[repo]--[branch]--[eyecatcher]--cicd`.  Ex: `prod--abp-single-lambda-api--master--ResizeImage--cicd`.  
1.  Commit your code and the CI/CD CodePipline will automatically run.

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

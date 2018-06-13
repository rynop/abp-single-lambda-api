# abp-single-lambda-api

[aws-blueprint](https://github.com/rynop/aws-blueprint) example for an API backed by a single lambda, using **nodejs**

## Setup

Follow [setup steps](https://github.com/rynop/abp-single-lambda-api#setup) that are common across all languages

### CI/CD CloudFormation Parameters:

*  `TestBuildPackageSpecPath`: `aws/codebuild/nodejs-test-package.yaml`
*  `LambdaPublishBuildSpecPath`: `aws/codebuild/lambda-publish.yaml`
*  `HandlerPath`: `src/lambda/handlers/test.handler`

`aws/codebuild/nodejs-test-package.yaml` will create a zip file with the following contents (all relative to the root of your git repo):

*  `node_modules`
*  `lib`
*  `src`
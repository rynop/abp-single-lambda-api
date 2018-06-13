# abp-single-lambda-api

[aws-blueprint](https://github.com/rynop/aws-blueprint) example for an API backed by a single lambda, using **typescript**

## Setup

Follow [setup steps](https://github.com/rynop/abp-single-lambda-api#setup) that are common across all languages

### CI/CD CloudFormation Parameters:

*  `TestBuildPackageSpecPath`: `aws/codebuild/typescript-test-package.yaml`
*  `LambdaPublishBuildSpecPath`: `aws/codebuild/lambda-publish.yaml`
*  `HandlerPath`: `dist/lambda/index.handler`

`aws/codebuild/typescript-test-package.yaml` will create a zip file with the following contents (all relative to the root of your git repo):

*  `node_modules`
*  `dist`
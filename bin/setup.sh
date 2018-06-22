#!/usr/bin/env bash

abort() {
    printf "\n  \033[31mError: $@\033[0m\n\n" && exit 1
}

log() {
    printf "  \033[36m%10s\033[0m : \e[2m%s\e[22m\033[0m\n" "$1" "$2"
}

chkreqs() {
    WGET_PARAMS=("--no-check-certificate" "-q" "-O-")
    command -v wget > /dev/null && GET="wget ${WGET_PARAMS[@]}"
    test -z "$GET" && abort "wget required"
    
    command -v aws > /dev/null
    test $? -ne 0 && abort "aws cli required"

    sed -v 2>&1 | grep -i "gnu sed" >/dev/null
    test $? -ne 0 && abort "GNU sed required to run this quickstart script. See https://github.com/rynop/aws-blueprint#gnu-tools"
}

chkreqs

while [[ -z "$favLang" ]]; do
    read -p "What lang (nodejs,golang,typescript): " favLang
done

while [[ -z "$nestedStacksS3Bucket" ]]; do
    read -p "S3 bucket name storing your nested-stacks: " nestedStacksS3Bucket
done

repoPath=$(basename `git rev-parse --show-toplevel 2>/dev/null` 2>/dev/null)
while [[ -z "$githubRepoName" ]]; do
    read -p "Github repo name (dont include org) [${repoPath}]: " githubRepoName
    githubRepoName=${nestedStacksS3BucketRegion:-$repoPath}
done

while [[ -z "$gitBranch" ]]; do
    read -p "Git branch CI/CD will monitor: " gitBranch
done

read -p "S3 nested-stacks bucket region [us-east-1]: " nestedStacksS3BucketRegion
nestedStacksS3BucketRegion=${nestedStacksS3BucketRegion:-us-east-1}

read -p "aws cli profile [default]: " awsCliProfile
awsCliProfile=${awsCliProfile:-default}

while [[ -z "$lambdaName" ]]; do
    read -p "Lambda name: " lambdaName
done

read -p "Lambda timeout (3-300) [3]: " lambdaTimeout
lambdaTimeout=${lambdaTimeout:-3}

read -p "Lambda memory (128-3008) [128]: " lambdaMemory
lambdaMemory=${lambdaMemory:-128}

declare -a arr=("master" "${favLang}")
awsCliParams="--region ${nestedStacksS3BucketRegion} --profile ${awsCliProfile}"

for branch in "${arr[@]}"; do
    url="https://github.com/rynop/abp-single-lambda-api/archive/${branch}.zip"
    wget -qO- "${url}" | bsdtar -xf-
    if [ $? -ne 0 ] ; then
        abort "Error downloading ${url}"
    fi
    
    if  [ "$branch" == "master" ]; then
        mv ./abp-single-lambda-api-${branch}/aws .
    else
        mv ./abp-single-lambda-api-${branch}/* .
    fi
    rm -r abp-single-lambda-api-${branch}
done

log 'Download code' 'done'

declare -a stackPaths=("apig/single-lambda-proxy-with-CORS.yaml" "cloudfront/single-apig-custom-domain.yaml")

for stackPath in "${stackPaths[@]}"; do
    S3VER=$(aws ${awsCliParams} s3api list-object-versions --bucket ${nestedStacksS3Bucket} --prefix nested-stacks/${stackPath} --query 'Versions[?IsLatest].[VersionId]' --output text)
    test -z "${S3VER}" && abort "Unable to find nested stack version at s3://${nestedStacksS3Bucket}/nested-stacks/${stackPath} See https://github.com/rynop/aws-blueprint/tree/master/nested-stacks"
    sed -i "s|${stackPath}?versionid=YourS3VersionId|${stackPath}?versionid=$S3VER|" aws/cloudformation/cf-apig-single-lambda-resources.yaml
done

sed -i "s|us-east-1--aws-blueprint.yourdomain.com|$nestedStacksS3Bucket|" aws/cloudformation/cf-apig-single-lambda-resources.yaml
sed -i "s|YourLambdaNameHere|$lambdaName|" aws/cloudformation/cf-apig-single-lambda-resources.yaml
log 'Set params in resources yaml' 'done'

grep YourS3VersionId aws/cloudformation/cf-apig-single-lambda-resources.yaml
test $? -eq 0 && abort "Unable to set your nested-stack template S3 versions"

cat <<TheMsg

Now run the following:

aws ssm put-parameter --name '/test/$githubRepoName/$gitBranch/$lambdaName/lambdaTimeout' --type 'String' --value '$lambdaTimeout'
aws ssm put-parameter --name '/staging/$githubRepoName/$gitBranch/$lambdaName/lambdaTimeout' --type 'String' --value '$lambdaTimeout'
aws ssm put-parameter --name '/prod/$githubRepoName/$gitBranch/$lambdaName/lambdaTimeout' --type 'String' --value '$lambdaTimeout'

aws ssm put-parameter --name '/test/$githubRepoName/$gitBranch/$lambdaName/lambdaMemory' --type 'String' --value '$lambdaMemory'
aws ssm put-parameter --name '/staging/$githubRepoName/$gitBranch/$lambdaName/lambdaMemory' --type 'String' --value '$lambdaMemory'
aws ssm put-parameter --name '/prod/$githubRepoName/$gitBranch/$lambdaName/lambdaMemory' --type 'String' --value '$lambdaMemory'

Create resources CloudFormation stacks with the names:

test--$githubRepoName--$gitBranch--[eyecatcher]--r
prod--$githubRepoName--$gitBranch--[eyecatcher]--r

CI/CD CloudFormation stack name will be:

$githubRepoName--$gitBranch--[eyecatcher]--cicd
LambdaName Parameter: $lambdaName
S3BucketForLambdaPackageZips: $nestedStacksS3Bucket

See https://github.com/rynop/abp-single-lambda-api/tree/$favLang for language specific CI/CD parameters

TheMsg

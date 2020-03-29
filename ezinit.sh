#!/bin/bash
# POC Build Agent provisioning

export AWS_DEFAULT_REGION="us-west-1"

### download build dependencies
mkdir custom
pwd="$(pwd)"
custom="${pwd}/custom"
export PATH="${PATH}:${custom}"

aws s3 cp $1 $custom
chmod 755 $custom/terraform

aws s3 cp $2 $custom
chmod 755 $custom/nomad

# Amazon Linux 2 AMI 2.0.20200304.0 x86_64 HVM
sudo yum -y install jq

### get config item from dynamodb
aws dynamodb get-item \
--table-name "$3" \
--key '{"full_name":{"S":"'$4'"}, "branch":{"S":"'$5'"}}' > item.json

### .tfvars to .json
jq '.Item' item.json > configs.json

keys=()
while IFS='' read -r line; do
   keys+=("$line")
done < <(jq 'keys[]' configs.json)

touch configs.tfvars
for a in ${keys[@]}
do
    key="$(echo ${a:1} | sed 's/.$//')"
    value="$(jq ".${key}.S" configs.json)"
    line="${key} = ${value}"
    echo $line >> configs.tfvars
done

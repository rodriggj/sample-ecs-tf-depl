# Sample Terraform ECS Deployment

## Resources Created

## Architectures

## Procedure

### 1. Setting up the AWS Account 

1. We need to create an IAM user that will have Policies and Permissions to enable resources via TF. 

> ### Questions for Client
> Organizations typically vary in the procedures and scope boundries with extending permissions to a User or Group of users. You need to: 
> - [ ] Meet with the appropriate Engineering / DevOps / IT department and understand what are the procedural rqmts for obtaining IAM roles
> - [ ] Will the role provisioned also include API Secrets/Keys to configure CLI access to enable AWS CLI
> - [ ] What is the OS that you will be utilizing to configure interaction with CLI as procedures are different (e.g. Windows, Linux, etc.)

---------

### 2. Installation of Terrform & AWS CLI onto Dev IDE
1. The TF commands will be initiated from the CLI which will require an download of the installation binaries, and CLI configuration. 

> ### Questions for Client
> Organizations typically vary in the procedures and scope boundries with extending permissions to a User or Group of users. You need to: 
> - [ ] Meet with the appropriate Engineering / DevOps / IT department and understand what are the procedural rqmts for obtaining IAM roles
> - [ ] Will the role provisioned also include API Secrets/Keys to configure CLI access to enable AWS CLI
> - [ ] What is the OS that you will be utilizing to configure interaction with CLI as procedures are different (e.g. Windows, Linux, etc.)

--------

### 3. Create TF State Backend
3.1. This procedure can be automated but if doing for the first time its just as easy to do manual with no clear advantage to automate. If you automate this step in your TF code you will have to comment out the code if running for anytime `NOT` the first time. 

3.2. Go to AWS console > S3 service

3.3. Create a unique bucket name that indicates the bucket is for the purpose of maintaining TF state file. Configure the bucket to the desired region. 
> See image _imgs/create-bucket.png_

Bucket configuration is as follows:
- [ ] Bucket Type: General Purpose
- [ ] Bucket Name: sample-ecs-tf-config-gjr
- [ ] Object Ownership: ACLs disabled (recommended)
- [ ] Block all public access: true
- [ ] Bucket Versioning: Disable
- [ ] Tags: Optional
- [ ] Encryption type: Server-side encryption with Amazon S3 managed keys (SSE-S3)
- [ ] Bucket Key: Enable
- [ ] Advanced Settings: Disable

3.4. A successful creation notification should be displayed on the console.
> See image _imgs/created-bucket.png_


> ### Questions for the client: 
> - [ ] Is there an existiing location to store a TF State manifest folder / bucket?
> - [ ] If not, and one needs to be created is there a region that the bucket must be created? 
> - [ ] Is there a particular configuration required to create an S3 bucket? (e.g naming convention, versioning enabled, etc.) 

----------

### 4. Create initial VPC and Subnet resources 
1. Create a dir called `01-Infrastructure`
2. Create a file within this dir called `infrastructure-prod.config`
3. Within the file input the following config: 
```s
key="PROD/infrastructure.tfstate"
bucket="sample-ecs-tf-state-config-gjr"
region="us-east-1"
```
4. Create another file called `vpc.tf`. In this file input the following:
```s
provider "aws" {
    region="${var.region}"
}

terraform {
  backend "s3" {}
}
```
5. The _provider_ block is using a _variable_ reference to _reigon_ so we need to ensure this reference is defined in our `variables.tf` file. 
```s
variable "region" {
    default      ="us-east-1"
    description  ="This is the default region"
}
```
6. Now we can continue to build our _vpc_ resources within our `vpc.tf` file. Input the remaining code below: 
```s
resource "aws_vpc" "production_vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags = {
    Name = "Production-VPC"
  }
}
```
7. You can now create public and private subnets amongst the `vpc.tf` and the `variables.tf` manifests. See the files to understand how these were added as it is just copy/paste and modification to the naming conventions. 

> ### Questions for Client 
> Is there a default region we will be directed to input as our default region?
> What is the CIDR range that will be allocated to our Prod, Dev, etc. VPCs? 
> Will we be able to enable to `enable-dns-hostnames=true` or will this be an IP address for our EC2 hosts? 
> Are there specific tagging requirements levied by the organziation or FinOps for AWS resources? 
> What is the requirement for AZ deployment with a region? Will it be 2, 3, ??? (See example with public and private subnets)

---------

### 5. Create intial Route Tables 
1. Within the `vpc.tf` file input the sections assocaiated with public and private route tables & route table associations

> ### Questions for Client 
> How many AZs will be needed and in what region, this will determine the number of Route Tables and Route Table associations to the CIDR blocks
> Note there is a default `main` route table and no configuration was applied, is there any config needed for the `main` rtb?

----------

### 6. Create the NAT & Internet Gateway 
1. Within the `vpc.tf` file we will need to ensure that there is a NAT to traverse traffic btwn the public and private subnets. 
2. The NAT Gateway IP address will change for each CIDR deployment so we may want to utilize an EIP to retain a static IP at the NAT gwy.
3. A route needs to be configured via the private subnet to ensure that the traffic bound for the private subnet is routable.
4. Finally, because the traffic will leave the env to the intenal client network (albiet a VPN or other secure tunnel), an Internet Gateway will need to be configured.

> ### Questions for Client 
> How many AZs will be needed and in what region, this will determine the number of Route Tables and Route Table associations to the CIDR blocks
> Note there is a default `main` route table and no configuration was applied, is there any config needed for the `main` rtb?
> For the intental NAT gateway, what routes will be allowed to be configured in the RTB. Can we utilize 0.0.0.0/0? Or does it have to be a specific subset of routes? 
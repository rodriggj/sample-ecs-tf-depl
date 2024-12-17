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
> - [ ] Is there a default region we will be directed to input as our default region?
> - [ ] What is the CIDR range that will be allocated to our Prod, Dev, etc. VPCs? 
> - [ ] Will we be able to enable to `enable-dns-hostnames=true` or will this be an IP address for our EC2 hosts? 
> - [ ] Are there specific tagging requirements levied by the organziation or FinOps for AWS resources? 
> - [ ] What is the requirement for AZ deployment with a region? Will it be 2, 3, ??? (See example with public and private subnets)

---------

### 5. Create intial Route Tables 
1. Within the `vpc.tf` file input the sections assocaiated with public and private route tables & route table associations

> ### Questions for Client 
> - [ ] How many AZs will be needed and in what region, this will determine the number of Route Tables and Route Table associations to the CIDR blocks
> - [ ] Note there is a default `main` route table and no configuration was applied, is there any config needed for the `main` rtb?

----------

### 6. Create the NAT & Internet Gateway 
1. Within the `vpc.tf` file we will need to ensure that there is a NAT to traverse traffic btwn the public and private subnets. 
2. The NAT Gateway IP address will change for each CIDR deployment so we may want to utilize an EIP to retain a static IP at the NAT gwy.
3. A route needs to be configured via the private subnet to ensure that the traffic bound for the private subnet is routable.
4. Finally, because the traffic will leave the env to the intenal client network (albiet a VPN or other secure tunnel), an Internet Gateway will need to be configured.

> ### Questions for Client 
> - [ ] How many AZs will be needed and in what region, this will determine the number of Route Tables and Route Table associations to the CIDR blocks
> - [ ] Note there is a default `main` route table and no configuration was applied, is there any config needed for the `main` rtb?
> - [ ] For the intental NAT gateway, what routes will be allowed to be configured in the RTB. Can we utilize 0.0.0.0/0? Or does it have to be a specific subset of routes? 

-----------

### 7. Create Output files
1. With the `01-infrastructure` folder create a file called `production.tfvars` and populate it with input variables.
2. Create a file called `outputs.tf` and update the output you would like to see from the TF execution

> ### Questions for Client 
> - [ ] Is there guidance on use of variable files for runtime input?
> - [ ] Where / what output is needed or guidance we need to follow to display to operations teams? 

-----------

### 8. Dryrun the configuration 
1. `cd` to the `01-infrastructure` dir and run the following commnad:
```s
terraform init -backend-config="infrastructure-prod.config"
```
> See image _imgs/dryrun-tfinit.png_

2. If you make a change to any of the files, run the following command to see what TF will `plan`

```s
terraform plan -var-file="production.tfvars"
```
> Note: The `production.tfvars` are a series of input variables you are providing the the TF configuration. If you were to run the `terraform plan` command without specifying the file containing the input vars you would be prompted at the console for the input fields that are in the `.tfvar` file.

> See image _imgs/tfplan.png_

3. If the plan displays without error in the console, you are ready to `apply` the config and deploy to AWS. The TF provider block specifies `aws`, which means that the TF API will invoke a Cloud Formation Template on AWS and deploy the Cloud Formation Stack which you can check in the console. To _dryrun_ this process, enter the following command: 

```
terraform apply -var-file="production.tfvars"
```
> Note: With the command above you will be prompted in the console to `Approve`, by entering `y` or `yes`. You can bypass this by adding `-auto-approve` flag to the end of the above command.

> See image _imgs/tfapply.png_

> See image _imgs/aws_console.png_

4. Once you verify the resources build as expected, we need to `turn the lights off`, and delete the environment. 
```
terraform destroy -var-file="production.tfvars" -auto-approve
```

5. Ensure that you create a .gitignore file to avoid size limitations to the repository and add any of the Terraform init created files or delete them completely. You can always re-initate the TF block files with the `terraform init` command. 

Ensure the following are in "grayed" out by the .gitignore file
- [ ] .terraform/providers

The `terraform.tfstate` file is what is stored in the S3 bucket (aka TF State Backend) to ensure that there are no conflicts of TF state across multiple teams providing input to TF files. 

> ### Questions for Client 
> - [ ] We will want to organize our TF manifests to be environment specific, we need to know what envs we will be provisioned to align this structure
> - [ ] This example demonstrates the need to have multiple IAM roles, policies, and permissions to ensure that the required services can execute API interactions without an error. Need to identify the appropriate IAM permissions. Find an example for a analogous project. 

------------

### 9. Configure DNS, ECS Fargate cluster, and ALB

1. If we need to create a DNS record on AWS, then the first part of this process is manual. 
2. Go to Route 53 on AWS console and register an AWS domain. (e.g. `ipaas-exmaple.com)

> You will have to wait till this domain is validated and assigned to you.

3. Lets configure the backend TF state -> Create a new dir called `02-platform` within the dir create a file called `platform-prod.config` and input the following the content show in the repo.

4. Configure the _ecs fargate_ cluster. Create a file called `ecs.tf` and update the config as contained in the repo. This will configure the state file as well as create the ecs cluster. You will need to create a `variables.tf` file, and update it to provide references to this file. See file in repo. 

5. Update the `ecs.tf` file to include the build for the Application Load Balancer. This will include a few more variables as well as a new file to configure the _security groups_ for the ALB resource. Create a new file called `security-groups.tf` to configure this resource. 







> See images _imgs/route53-domain.png_

> ### Questions for Client 
> - [ ] What service will be utilzed to register DNS? Who will be registering the DNS? 
> - [ ] Our design will require an Application Load Balancer, is there an existing ALB or NLB that we will be utilizing for middleware services? if so what is this LB?
> - [ ] What is required for the LB configuration (e.g. Health Checks, a particular routing scheme (geolocation, round-robin, etc.)
> - [ ] Are there a series of Security Groups that are currently configured for various environments or resources that we will reuse? Are there specific guidance / compliance rules needed for SG configurations. 


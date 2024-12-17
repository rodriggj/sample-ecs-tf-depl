variable "region" {
    default      ="us-east-1"
    description  ="This is the default region"
}

variable "vpc_cidr" {
    default     ="10.0.0.0/16"
    description = "Default Prod VPC CIDR block"
}

variable "public_subnet_1_cidr" {
    description= "t-ws Public Subnet 1 CIDR"
}

variable "public_subnet_2_cidr" {
    description= "t-ws Public Subnet 2 CIDR"
}

variable "public_subnet_3_cidr" {
    description= "t-ws Public Subnet 3 CIDR"
}

variable "private_subnet_1_cidr" {
    description= "t-ws Private Subnet 1 CIDR"
}

variable "private_subnet_2_cidr" {
    description= "t-ws Private Subnet 2 CIDR"
}

variable "private_subnet_3_cidr" {
    description= "t-ws Private Subnet 3 CIDR"
}
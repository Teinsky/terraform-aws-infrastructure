terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for state file (uncomment to use S3 backend)
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "dev/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = true
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = var.vpc_cidr
  project_name     = var.project_name
  environment      = var.environment
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"

  project_name              = var.project_name
  environment               = var.environment
  instance_type             = var.instance_type
  key_name                  = var.key_name
  public_subnet_id          = module.vpc.public_subnet_ids[0]
  private_subnet_id         = module.vpc.private_subnet_ids[0]
  public_security_group_id  = module.security_groups.public_ec2_sg_id
  private_security_group_id = module.security_groups.private_ec2_sg_id
}

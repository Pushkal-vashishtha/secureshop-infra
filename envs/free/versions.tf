terraform {
  required_version = ">= 1.10"
  backend "s3" {
    bucket       = "secureshop-tfstate-212598081822"
    key          = "free/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = "ap-south-1"
  default_tags {
    tags = { Project = "secureshop-lite", Owner = "pushkal" }
  }
}

data "aws_caller_identity" "current" {}

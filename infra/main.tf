terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

// Hardcoded account id and region per user request
locals {
  aws_account_id = "211125751164"
}

output "aws_account_id" {
  description = "Hardcoded AWS account id"
  value       = local.aws_account_id
}

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # For team use, add a remote backend so state is shared and locked.
  # backend "s3" {}
}

variable "aws_region" {
  description = "AWS region for the container registry"
  type        = string
  default     = "us-east-1"
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "devops-lab-api"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._/-]*$", var.repository_name))
    error_message = "Use lowercase letters, numbers, and . _ / - only."
  }
}

variable "force_delete" {
  description = "Allow Terraform to delete the repository even when it contains images"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to every supported resource"
  type        = map(string)
  default = {
    Project   = "devops-lab"
    ManagedBy = "terraform"
  }
}

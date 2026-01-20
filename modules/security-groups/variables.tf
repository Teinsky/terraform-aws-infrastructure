variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into public EC2"
  type        = string
  default     = "0.0.0.0/0" # Nên thay bằng IP cụ thể của bạn
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

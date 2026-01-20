variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of public subnet for public EC2"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of private subnet for private EC2"
  type        = string
}

variable "public_security_group_id" {
  description = "Security group ID for public EC2"
  type        = string
}

variable "private_security_group_id" {
  description = "Security group ID for private EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of SSH key pair"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "" # Will use data source if empty
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring for EC2"
  type        = bool
  default     = true
}

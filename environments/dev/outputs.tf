# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# Security Group Outputs
output "public_ec2_sg_id" {
  description = "Public EC2 Security Group ID"
  value       = module.security_groups.public_ec2_sg_id
}

output "private_ec2_sg_id" {
  description = "Private EC2 Security Group ID"
  value       = module.security_groups.private_ec2_sg_id
}

# EC2 Outputs
output "public_ec2_public_ip" {
  description = "Public IP of Public EC2 Instance"
  value       = module.ec2.public_instance_public_ip
}

output "public_ec2_private_ip" {
  description = "Private IP of Public EC2 Instance"
  value       = module.ec2.public_instance_private_ip
}

output "private_ec2_private_ip" {
  description = "Private IP of Private EC2 Instance"
  value       = module.ec2.private_instance_private_ip
}

# Connection Information
output "ssh_command_public" {
  description = "SSH command to connect to public EC2"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.ec2.public_instance_public_ip}"
}

output "ssh_command_private_via_public" {
  description = "SSH command to connect to private EC2 via public EC2"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem -J ec2-user@${module.ec2.public_instance_public_ip} ec2-user@${module.ec2.private_instance_private_ip}"
}

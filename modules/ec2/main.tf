# File: modules/ec2/main.tf

# Data source to get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Public EC2 Instance (Bastion Host)
resource "aws_instance" "public" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.public_security_group_id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # Enable public IP
  associate_public_ip_address = true

  # Checkov: CKV_AWS_8 - Enable EBS encryption
  # Checkov: CKV_AWS_135 - Ensure EC2 instance is using IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforce IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Root volume configuration with encryption
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true # Checkov: CKV_AWS_8

    tags = {
      Name = "${var.project_name}-${var.environment}-public-root-volume"
    }
  }

  # Monitoring
  monitoring = var.enable_detailed_monitoring

  # Checkov: CKV_AWS_126 - Ensure EC2 instance has detailed monitoring enabled
  # Checkov: CKV_AWS_46 - Ensure EBS optimization is enabled

  # User data script
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Public EC2 - Bastion Host</h1>" > /var/www/html/index.html
              echo "<p>Hostname: $(hostname)</p>" >> /var/www/html/index.html
              echo "<p>Instance ID: $(ec2-metadata --instance-id | cut -d ' ' -f 2)</p>" >> /var/www/html/index.html
              EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-ec2"
    Environment = var.environment
    Type        = "Public"
    Role        = "Bastion"
  }

  # Prevent accidental termination in production
  lifecycle {
    ignore_changes = [ami]
  }
}

# Private EC2 Instance
resource "aws_instance" "private" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.private_security_group_id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name # ← ADD THIS

  # No public IP for private instance
  associate_public_ip_address = false

  # Enable IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Root volume configuration with encryption
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-${var.environment}-private-root-volume"
    }
  }

  # Monitoring
  monitoring = var.enable_detailed_monitoring

  # User data script
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y mysql postgresql
              echo "Private EC2 Instance" > /home/ec2-user/info.txt
              echo "Hostname: $(hostname)" >> /home/ec2-user/info.txt
              EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-ec2"
    Environment = var.environment
    Type        = "Private"
    Role        = "Application"
  }

  # Prevent accidental termination in production
  lifecycle {
    ignore_changes = [ami]
  }
}

# Elastic IP for Public EC2 (optional but recommended)
resource "aws_eip" "public_ec2" {
  instance = aws_instance.public.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-ec2-eip"
    Environment = var.environment
  }

  depends_on = [aws_instance.public]
}

# Security Group for Public EC2 Instance (Bastion Host)
resource "aws_security_group" "public_ec2" {
  name        = "${var.project_name}-${var.environment}-public-ec2-sg"
  description = "Security group for public EC2 instance (Bastion Host)"
  vpc_id      = var.vpc_id

  # SSH access from specified CIDR
  ingress {
    description = "SSH from allowed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # HTTP access (optional, for web server)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access (optional, for web server)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-ec2-sg"
    Environment = var.environment
    Type        = "Public"
  }
}

# Security Group for Private EC2 Instance
resource "aws_security_group" "private_ec2" {
  name        = "${var.project_name}-${var.environment}-private-ec2-sg"
  description = "Security group for private EC2 instance"
  vpc_id      = var.vpc_id

  # SSH access only from Public EC2 Security Group
  ingress {
    description     = "SSH from Public EC2"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
  }

  # Allow ICMP (ping) from VPC
  ingress {
    description = "ICMP from VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow MySQL/MariaDB access from VPC (optional)
  ingress {
    description = "MySQL from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow PostgreSQL access from VPC (optional)
  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-ec2-sg"
    Environment = var.environment
    Type        = "Private"
  }
}

# Additional Security Group for Database (optional)
resource "aws_security_group" "database" {
  name        = "${var.project_name}-${var.environment}-database-sg"
  description = "Security group for database servers"
  vpc_id      = var.vpc_id

  # MySQL/Aurora access from private EC2
  ingress {
    description     = "MySQL from Private EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.private_ec2.id]
  }

  # PostgreSQL access from private EC2
  ingress {
    description     = "PostgreSQL from Private EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.private_ec2.id]
  }

  # Allow outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-database-sg"
    Environment = var.environment
    Type        = "Database"
  }
}

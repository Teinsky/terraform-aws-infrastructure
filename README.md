# AWS Infrastructure Deployment with Terraform

Dự án này triển khai hạ tầng AWS bao gồm VPC, Subnets, Security Groups, và EC2 instances sử dụng Terraform với cấu trúc module.

## 📋 Mục lục

- [Kiến trúc](#kiến-trúc)
- [Yêu cầu](#yêu-cầu)
- [Cài đặt](#cài-đặt)
- [Sử dụng](#sử-dụng)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Modules](#modules)
- [Testing](#testing)
- [Xóa tài nguyên](#xóa-tài-nguyên)

## 🏗️ Kiến trúc

Hạ tầng được triển khai bao gồm:

```
VPC (10.0.0.0/16)
│
├── Public Subnet (10.0.1.0/24, 10.0.2.0/24)
│   ├── Internet Gateway
│   ├── Public Route Table
│   └── Public EC2 (Bastion Host)
│       └── Elastic IP
│
└── Private Subnet (10.0.10.0/24, 10.0.11.0/24)
    ├── NAT Gateway
    ├── Private Route Table
    └── Private EC2 (Application Server)
```

### Thành phần chính:

1. **VPC**: Virtual Private Cloud với CIDR 10.0.0.0/16
2. **Public Subnets**: 2 subnets với Internet Gateway
3. **Private Subnets**: 2 subnets với NAT Gateway
4. **Public EC2**: Bastion host có thể truy cập từ Internet
5. **Private EC2**: Application server chỉ truy cập từ Public EC2
6. **Security Groups**: Kiểm soát lưu lượng vào/ra

## ✅ Yêu cầu

- Terraform >= 1.0
- AWS CLI đã được cấu hình
- AWS Account với quyền tạo VPC, EC2, Security Groups
- SSH key pair đã tạo trên AWS

## 🚀 Cài đặt

### 1. Clone repository

```bash
git clone <your-repo-url>
cd terraform-aws-infrastructure
```

### 2. Tạo SSH Key trên AWS

```bash
aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > ~/.ssh/my-key.pem
chmod 400 ~/.ssh/my-key.pem
```

### 3. Cấu hình variables

Chỉnh sửa file `environments/dev/terraform.tfvars`:

```hcl
project_name     = "your-project-name"
key_name         = "my-key"  # Tên SSH key bạn vừa tạo
allowed_ssh_cidr = "YOUR_IP/32"  # IP của bạn để SSH
```

Để lấy IP của bạn:
```bash
curl ifconfig.me
```

## 💻 Sử dụng

### 1. Di chuyển vào thư mục environment

```bash
cd environments/dev
```

### 2. Khởi tạo Terraform

```bash
terraform init
```

### 3. Xem plan

```bash
terraform plan
```

### 4. Apply infrastructure

```bash
terraform apply
```

Nhập `yes` để xác nhận triển khai.

### 5. Xem outputs

```bash
terraform output
```

Bạn sẽ thấy các thông tin như:
- Public IP của EC2 instances
- SSH commands để kết nối
- VPC và Subnet IDs

## 🔐 Kết nối đến EC2 Instances

### Kết nối đến Public EC2 (Bastion)

```bash
ssh -i ~/.ssh/my-key.pem ec2-user@<PUBLIC_IP>
```

### Kết nối đến Private EC2 qua Public EC2

Có 2 cách:

**Cách 1: SSH Jump Host**
```bash
ssh -i ~/.ssh/my-key.pem -J ec2-user@<PUBLIC_IP> ec2-user@<PRIVATE_IP>
```

**Cách 2: SSH Agent Forwarding**
```bash
# Trên máy local
ssh-add ~/.ssh/my-key.pem

# SSH vào public EC2 với agent forwarding
ssh -A ec2-user@<PUBLIC_IP>

# Từ public EC2, SSH vào private EC2
ssh ec2-user@<PRIVATE_IP>
```

## 📁 Cấu trúc thư mục

```
terraform-aws-infrastructure/
├── modules/
│   ├── vpc/                    # Module VPC
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security-groups/        # Module Security Groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2/                    # Module EC2
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   └── dev/                    # Development environment
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── tests/                      # Test files
├── .gitignore
└── README.md
```

## 🔧 Modules

### VPC Module
- Tạo VPC với CIDR tùy chỉnh
- Tạo Public và Private Subnets
- Tạo Internet Gateway
- Tạo NAT Gateway
- Cấu hình Route Tables

### Security Groups Module
- Public EC2 Security Group: SSH từ IP cụ thể
- Private EC2 Security Group: SSH từ Public EC2
- Database Security Group: Cho RDS/Database

### EC2 Module
- Public EC2 với Elastic IP
- Private EC2 không có Public IP
- User data để cài đặt packages
- Encrypted EBS volumes

## 🧪 Testing

### Test kết nối Internet từ Public EC2

```bash
ssh -i ~/.ssh/my-key.pem ec2-user@<PUBLIC_IP>
curl -I https://google.com
# Kết quả: HTTP/1.1 200 OK
```

### Test kết nối từ Public EC2 đến Private EC2

```bash
ssh -i ~/.ssh/my-key.pem ec2-user@<PUBLIC_IP>
ping <PRIVATE_IP>
# Kết quả: packets transmitted successfully
```

### Test Internet từ Private EC2 qua NAT Gateway

```bash
# SSH vào private EC2
curl -I https://google.com
# Kết quả: HTTP/1.1 200 OK (qua NAT Gateway)
```

### Verify Security Groups

```bash
# Test SSH từ IP không cho phép (phải fail)
ssh -i ~/.ssh/my-key.pem ec2-user@<PUBLIC_IP>
# Từ IP khác: Connection timeout

# Test SSH trực tiếp vào Private EC2 (phải fail)
ssh -i ~/.ssh/my-key.pem ec2-user@<PRIVATE_IP>
# Kết quả: Connection timeout
```

## 🔍 Kiểm tra Resources

### Kiểm tra VPC

```bash
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=your-project-name"
```

### Kiểm tra Subnets

```bash
aws ec2 describe-subnets --filters "Name=tag:Project,Values=your-project-name"
```

### Kiểm tra EC2 Instances

```bash
aws ec2 describe-instances --filters "Name=tag:Project,Values=your-project-name"
```

### Kiểm tra Security Groups

```bash
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=your-project-name"
```

## 🗑️ Xóa tài nguyên

**CHÚ Ý**: Lệnh này sẽ xóa TẤT CẢ tài nguyên được tạo!

```bash
cd environments/dev
terraform destroy
```

Nhập `yes` để xác nhận xóa.

## 📊 Chi phí ước tính

Với cấu hình mặc định (t2.micro):
- EC2 t2.micro (2 instances): ~$0.0116/hour x 2 = $0.0232/hour
- NAT Gateway: ~$0.045/hour + data transfer
- Elastic IP: Miễn phí khi attached
- **Tổng**: ~$0.07/hour hoặc ~$50/tháng

## 🔒 Best Practices

1. **Không commit sensitive data**: 
   - Sử dụng `.gitignore` cho `*.tfvars`
   - Không commit SSH keys

2. **Sử dụng specific IP cho SSH**:
   ```hcl
   allowed_ssh_cidr = "YOUR_IP/32"
   ```

3. **Enable encryption cho EBS volumes**:
   ```hcl
   encrypted = true
   ```

4. **Sử dụng Terraform Backend (S3)**:
   ```hcl
   backend "s3" {
     bucket = "your-terraform-state"
     key    = "dev/terraform.tfstate"
     region = "ap-southeast-1"
   }
   ```

5. **Tag resources đầy đủ**:
   ```hcl
   tags = {
     Project     = var.project_name
     Environment = var.environment
     ManagedBy   = "Terraform"
   }
   ```

## 🐛 Troubleshooting

### Lỗi: "Error creating VPC"
- Kiểm tra AWS credentials: `aws sts get-caller-identity`
- Kiểm tra region: `aws configure get region`

### Lỗi: "InvalidKeyPair.NotFound"
- Tạo key pair: `aws ec2 create-key-pair --key-name my-key`
- Hoặc upload existing key

### Không SSH được vào EC2
- Kiểm tra Security Group rules
- Kiểm tra SSH key permissions: `chmod 400 key.pem`
- Kiểm tra IP trong `allowed_ssh_cidr`

### Private EC2 không có Internet
- Kiểm tra NAT Gateway đã được tạo
- Kiểm tra Route Table của Private Subnet
- Verify Elastic IP attached to NAT Gateway

## 📚 Tài liệu tham khảo

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform Modules](https://www.terraform.io/docs/language/modules/)

## 👥 Đóng góp

Mọi đóng góp đều được chào đón! Vui lòng tạo Pull Request hoặc Issues.

## 📄 License

MIT License

---

**Lưu ý**: Đây là project học tập. Trong môi trường production, cần thêm nhiều biện pháp bảo mật và monitoring.
#   t r i g g e r   w o r k f l o w  
 
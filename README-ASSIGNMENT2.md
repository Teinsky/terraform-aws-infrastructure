# Bài 2: CI/CD với GitHub Actions và Checkov

## 📋 Tổng quan

Bài tập này mở rộng Bài 1 bằng cách thêm:
- ✅ GitHub Actions workflows để tự động hóa Terraform
- ✅ Checkov security scanning
- ✅ Automated testing và validation
- ✅ Branch protection và manual approval gates

## 🏗️ Architecture

```
Developer → Git Push → GitHub Actions → AWS
    │
    ├─ Pull Request → Terraform Plan + Checkov Scan
    ├─ Code Review → Manual Approval
    └─ Merge to Main → Terraform Apply → Deployed Infrastructure
```

## 📁 Cấu trúc Project

```
terraform-aws-infrastructure/
├── .github/
│   ├── workflows/
│   │   ├── terraform-plan.yml      # PR workflow
│   │   ├── terraform-apply.yml     # Deploy workflow
│   │   └── terraform-destroy.yml   # Destroy workflow
│   └── pull_request_template.md
├── modules/                         # Từ Bài 1
├── environments/                    # Từ Bài 1
├── docs/
│   ├── CI_CD_GUIDE.md
│   └── BRANCH_PROTECTION.md
├── .checkov.yml                    # Checkov config
├── test-cicd.ps1                   # Pre-flight tests
└── README-ASSIGNMENT2.md           # File này
```

## 🚀 Hướng dẫn Triển khai

### Bước 1: Setup GitHub Repository

```powershell
# Initialize git nếu chưa có
git init

# Add all files
git add .

# Initial commit
git commit -m "feat: add CI/CD with GitHub Actions and Checkov"

# Create GitHub repo và push
git remote add origin https://github.com/YOUR_USERNAME/terraform-aws-infrastructure.git
git branch -M main
git push -u origin main
```

### Bước 2: Configure GitHub Secrets

1. Vào **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Thêm 3 secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | `AKIAXXXXXXXXXXXXXXXX` | AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` | AWS Secret Key |
| `AWS_REGION` | `ap-southeast-1` | AWS Region |

### Bước 3: Setup Branch Protection

Làm theo hướng dẫn trong `docs/BRANCH_PROTECTION.md`

**Tóm tắt:**
1. Settings → Branches → Add rule
2. Branch name: `main`
3. ✅ Require pull request before merging
4. ✅ Require status checks: Terraform Plan, Checkov Scan
5. ✅ Require conversation resolution
6. Save changes

### Bước 4: Create Production Environment

1. Settings → **Environments** → **New environment**
2. Name: `production`
3. ✅ Required reviewers → Add yourself
4. Deployment branches: `main` only
5. Save

### Bước 5: Test Workflow

```powershell
# Create feature branch
git checkout -b feature/test-cicd

# Make a small change
echo "# Testing CI/CD" >> test.md

# Run pre-flight checks
.\test-cicd.ps1

# Commit and push
git add .
git commit -m "test: verify CI/CD pipeline"
git push origin feature/test-cicd
```

6. Vào GitHub → Create Pull Request
7. Xem workflow chạy trong Actions tab
8. Review Terraform plan trong PR comments
9. Review Checkov results
10. Merge PR sau khi approve
11. Workflow apply sẽ chạy, chờ manual approval
12. Approve deployment trong Environments

## 🔄 Workflow Details

### Terraform Plan Workflow

**Trigger:** Pull Request to main/develop

**Jobs:**
1. **terraform-plan**
   - Format check
   - Init và Validate
   - Generate plan
   - Comment plan on PR
   - Upload plan artifact

2. **checkov-scan**
   - Security scanning
   - Compliance checking
   - Comment results on PR
   - Upload report artifact

### Terraform Apply Workflow

**Trigger:** Push to main branch

**Jobs:**
1. **terraform-apply**
   - Generate plan
   - ⏸️ Wait for manual approval
   - Apply infrastructure
   - Get outputs
   - Create GitHub issue with details

2. **post-deployment-tests**
   - Verify VPC
   - Check EC2 instances
   - Test connectivity
   - Test HTTP service

### Terraform Destroy Workflow

**Trigger:** Manual workflow dispatch only

**Requirements:**
- Type "destroy" to confirm
- Select environment
- Manual approval required

## 🔒 Security Features

### 1. Checkov Security Scanning

Kiểm tra:
- ✅ EBS encryption
- ✅ IMDSv2 enabled
- ✅ VPC flow logs
- ✅ Security group rules
- ✅ IAM policies
- ✅ Network configurations

### 2. Compliance Checks

- AWS CIS benchmarks
- Industry best practices
- Company policies

### 3. Secret Protection

- ❌ No credentials in code
- ✅ GitHub Secrets only
- ✅ Secret scanning enabled

### 4. Branch Protection

- ✅ No direct commits to main
- ✅ Required reviews
- ✅ Status checks must pass
- ✅ Manual approval gates

## 🧪 Testing

### Local Pre-flight Checks

```powershell
# Run all checks
.\test-cicd.ps1

# Skip Checkov (if not installed)
.\test-cicd.ps1 -SkipCheckov

# Verbose output
.\test-cicd.ps1 -Verbose
```

**Tests performed:**
1. Git status check
2. Terraform format
3. Terraform validate
4. Secret detection
5. .gitignore verification
6. Checkov scan
7. Workflow YAML validation
8. Branch check
9. Remote repository check
10. Large file detection

### Automated Tests (GitHub Actions)

**On Pull Request:**
- Terraform format, init, validate, plan
- Checkov security scan
- Comment results on PR

**On Merge:**
- Infrastructure deployment
- Post-deployment connectivity tests
- HTTP service verification

## 📊 Monitoring and Artifacts

### GitHub Actions Artifacts

| Artifact | Retention | Description |
|----------|-----------|-------------|
| terraform-plan | 5 days | Plan output for review |
| checkov-report | 30 days | Security scan results |
| terraform-outputs | 30 days | Infrastructure outputs |
| destroy-plan | 30 days | Destruction plan |

### GitHub Issues

Auto-created issues for:
- ✅ Successful deployments (with outputs)
- ❌ Failed deployments (with error details)
- 🗑️ Infrastructure destruction (with audit trail)

## 📖 Usage Examples

### Example 1: Add New Security Group Rule

```powershell
# 1. Create feature branch
git checkout -b feature/add-database-sg

# 2. Edit security group
code modules/security-groups/main.tf

# Add new rule for database
resource "aws_security_group_rule" "database_mysql" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.private_ec2.id
  source_security_group_id = aws_security_group.public_ec2.id
  description       = "Allow MySQL from public EC2"
}

# 3. Test locally
.\test-cicd.ps1

# 4. Commit and push
git add .
git commit -m "feat: add MySQL security group rule"
git push origin feature/add-database-sg

# 5. Create PR on GitHub
# 6. Review automated checks
# 7. Merge after approval
# 8. Approve deployment
```

### Example 2: Update Instance Type

```powershell
# 1. Create branch
git checkout -b feature/upgrade-instance

# 2. Edit terraform.tfvars
code environments/dev/terraform.tfvars

# Change: instance_type = "t3.small"

# 3. Test
.\test-cicd.ps1

# 4. Commit and create PR
git add environments/dev/terraform.tfvars
git commit -m "feat: upgrade EC2 to t3.small for better performance"
git push origin feature/upgrade-instance

# PR will show plan with instance replacement
# Review carefully before approving
```

### Example 3: Emergency Destroy

```powershell
# On GitHub Web UI:
# 1. Go to Actions tab
# 2. Select "Terraform Destroy"
# 3. Click "Run workflow"
# 4. Environment: dev
# 5. Confirmation: destroy
# 6. Click "Run workflow"
# 7. Approve in Environments section
# 8. Monitor destruction
```

## 🐛 Troubleshooting

### Issue: Workflow fails with AWS credentials error

```
Error: No valid credential sources found
```

**Solution:**
1. Check Secrets are set: Settings → Secrets → Actions
2. Verify IAM user has permissions
3. Check secret names are exact: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`

### Issue: Checkov fails on valid configuration

```
Check: CKV_AWS_XXX: "Some check description"
FAILED for resource: aws_instance.public
```

**Solution:**
1. Review the specific check documentation
2. If justified, add to `.checkov.yml` skip list:
```yaml
skip-check:
  - CKV_AWS_XXX  # Justification: reason why this is okay
```
3. Commit the updated `.checkov.yml`

### Issue: Can't merge PR - checks not passing

**Solution:**
1. Click "Details" on failed check
2. Review logs in Actions tab
3. Fix issues locally
4. Push new commit
5. Checks re-run automatically

### Issue: Terraform state lock

```
Error: Error acquiring the state lock
```

**Solution:**
```powershell
# If you're sure no other operation is running:
cd environments/dev
terraform force-unlock LOCK_ID
```

### Issue: Need to bypass branch protection

**Emergency only:**
1. Settings → Branches
2. Edit branch protection rule for `main`
3. Temporarily disable required status checks
4. Make emergency commit
5. **Immediately re-enable protections**
6. Document in incident report

## ✅ Checklist hoàn thành Bài 2

### Setup (10%)
- [ ] GitHub repository created
- [ ] GitHub Secrets configured
- [ ] Branch protection rules set
- [ ] Environments configured (production, destruction)

### Workflows (40%)
- [ ] Terraform Plan workflow created and working
- [ ] Terraform Apply workflow created and working
- [ ] Terraform Destroy workflow created and working
- [ ] Workflows trigger correctly

### Checkov Integration (30%)
- [ ] Checkov configuration file created
- [ ] Checkov runs on PRs
- [ ] Security issues identified
- [ ] Justified skips documented
- [ ] Code passes Checkov scan

### Testing (10%)
- [ ] Local pre-flight script works
- [ ] PR workflow tested
- [ ] Apply workflow tested
- [ ] Post-deployment tests pass

### Documentation (10%)
- [ ] CI/CD guide written
- [ ] Branch protection guide written
- [ ] README updated
- [ ] PR template created
- [ ] Workflows documented

## 📈 Grading Criteria

| Criteria | Points | Description |
|----------|--------|-------------|
| **Terraform Automation** | 1.0 | Workflows correctly run Terraform commands |
| **Checkov Integration** | 1.0 | Security scanning implemented and passing |
| **GitHub Actions Setup** | 0.5 | Workflows properly configured |
| **Branch Protection** | 0.3 | Protection rules enforced |
| **Documentation** | 0.2 | Clear documentation provided |
| **Total** | 3.0 | |

## 🎯 Best Practices Applied

1. ✅ **Infrastructure as Code** - All infrastructure in version control
2. ✅ **Automated Testing** - Every change validated automatically
3. ✅ **Security First** - Checkov scanning on every PR
4. ✅ **Manual Approval** - Human review before production deployment
5. ✅ **Audit Trail** - All changes tracked in Git history
6. ✅ **Fail Fast** - Issues caught before merge
7. ✅ **Documentation** - Clear guides for all processes

## 📚 References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Checkov Documentation](https://www.checkov.io/)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS Actions](https://github.com/aws-actions/configure-aws-credentials)

## 🎓 Learning Outcomes

Sau khi hoàn thành bài này, bạn đã học được:

1. ✅ Thiết lập CI/CD pipeline với GitHub Actions
2. ✅ Tích hợp security scanning vào workflow
3. ✅ Tự động hóa Terraform deployment
4. ✅ Implement approval gates và branch protection
5. ✅ Write automated tests cho infrastructure
6. ✅ Document CI/CD processes
7. ✅ Troubleshoot common pipeline issues

---

**Lưu ý:** Đây là bài tập thực hành. Trong production environment, cần thêm nhiều biện pháp bảo mật và monitoring khác.

**Good luck!** 🚀

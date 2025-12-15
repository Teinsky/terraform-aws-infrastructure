# CI/CD Pipeline Guide

## 📖 Tổng quan

Pipeline CI/CD tự động hóa việc triển khai AWS infrastructure với Terraform thông qua GitHub Actions.

## 🔄 Workflow Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Developer                             │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
            ┌─────────────────────────┐
            │  Feature Branch Created  │
            └─────────────────────────┘
                          │
                          ▼
            ┌─────────────────────────┐
            │   Push to GitHub         │
            └─────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              Pull Request Workflow                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ Terraform│  │ Terraform│  │ Checkov  │             │
│  │   Init   │─▶│   Plan   │─▶│  Scan    │             │
│  └──────────┘  └──────────┘  └──────────┘             │
│                      │                                   │
│                      ▼                                   │
│              ┌──────────────┐                           │
│              │ Comment on PR │                           │
│              └──────────────┘                           │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
            ┌─────────────────────────┐
            │   Code Review Process    │
            │   (Manual Approval)      │
            └─────────────────────────┘
                          │
                          ▼
            ┌─────────────────────────┐
            │   Merge to Main Branch   │
            └─────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              Apply Workflow (Main Branch)                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │ Terraform│  │ Terraform│  │ Terraform│             │
│  │   Init   │─▶│   Plan   │─▶│  Apply   │             │
│  └──────────┘  └──────────┘  └──────────┘             │
│                                     │                    │
│                                     ▼                    │
│                          ┌────────────────┐             │
│                          │ Post-Deploy    │             │
│                          │ Tests          │             │
│                          └────────────────┘             │
│                                     │                    │
│                                     ▼                    │
│                          ┌────────────────┐             │
│                          │ Create Issue   │             │
│                          │ with Outputs   │             │
│                          └────────────────┘             │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Workflows

### 1. Terraform Plan (Pull Request)

**Trigger:** Pull request to `main` or `develop`

**Steps:**
1. Checkout code
2. Setup Terraform
3. Configure AWS credentials
4. Terraform format check
5. Terraform init
6. Terraform validate
7. Terraform plan
8. Upload plan as artifact
9. Comment plan on PR
10. Run Checkov security scan
11. Comment Checkov results on PR

**Outputs:**
- Terraform plan details in PR comments
- Security scan results
- Artifacts for review

### 2. Terraform Apply (Main Branch)

**Trigger:** Push to `main` branch

**Steps:**
1. Checkout code
2. Setup Terraform
3. Configure AWS credentials
4. Terraform init
5. Terraform plan
6. **Manual approval required** (Environment: production)
7. Terraform apply
8. Get outputs
9. Run post-deployment tests
10. Create GitHub issue with deployment info

**Outputs:**
- Deployed infrastructure
- Terraform outputs
- GitHub issue with details

### 3. Terraform Destroy (Manual)

**Trigger:** Manual workflow dispatch only

**Inputs:**
- Confirmation text (must type "destroy")
- Environment selection

**Steps:**
1. Validate confirmation
2. Setup Terraform
3. Configure AWS credentials
4. Terraform init
5. Terraform destroy plan
6. **Manual approval required** (Environment: destruction)
7. Final confirmation wait
8. Terraform destroy
9. Document destruction in GitHub issue

## 🔐 Security Features

### Checkov Integration

Checkov automatically scans Terraform code for security and compliance issues.

**Categories checked:**
- AWS security best practices
- Encryption requirements
- Network security
- IAM policies
- Logging and monitoring
- Resource configurations

**Severity levels:**
- 🔴 CRITICAL: Must fix immediately
- 🟠 HIGH: Should fix before merge
- 🟡 MEDIUM: Fix in near future
- 🟢 LOW: Nice to fix

### AWS Credentials Management

**Never commit credentials!**

Credentials are stored as GitHub Secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

## 📝 Usage Guide

### Creating a New Feature

```powershell
# 1. Create feature branch
git checkout -b feature/add-new-subnet

# 2. Make changes
code modules/vpc/main.tf

# 3. Test locally (optional)
cd environments/dev
terraform init
terraform plan

# 4. Commit and push
git add .
git commit -m "feat: add new subnet for database tier"
git push origin feature/add-new-subnet

# 5. Create Pull Request on GitHub
# - Add description
# - Wait for automated checks
# - Request review
```

### Reviewing a Pull Request

1. **Check automated checks:**
   - ✅ Terraform Plan successful
   - ✅ Checkov scan passed (or justified failures)
   - ✅ No formatting issues

2. **Review Terraform plan:**
   - Read plan output in PR comments
   - Verify expected resources
   - Check for unintended changes

3. **Review Checkov results:**
   - Check security findings
   - Verify skipped checks are justified
   - Ensure no critical issues

4. **Code review:**
   - Review actual code changes
   - Check for best practices
   - Verify documentation updated

5. **Approve and merge:**
   - Click "Approve" if satisfied
   - Merge PR (squash and merge recommended)

### Deploying to Production

After merging to `main`:

1. **Automatic workflow starts**
2. **Review required:**
   - Go to Actions tab
   - Find "Terraform Apply" workflow
   - Click "Review deployments"
   - Select "production" environment
   - Click "Approve and deploy"

3. **Monitor deployment:**
   - Watch workflow logs
   - Check for errors
   - Wait for completion

4. **Verify deployment:**
   - Check created GitHub issue
   - Review Terraform outputs
   - Test infrastructure

### Destroying Infrastructure

⚠️ **DANGER ZONE** ⚠️

```powershell
# On GitHub:
# 1. Go to Actions tab
# 2. Select "Terraform Destroy" workflow
# 3. Click "Run workflow"
# 4. Select environment (dev/staging)
# 5. Type "destroy" in confirmation
# 6. Click "Run workflow"
# 7. Wait for approval requirement
# 8. Review and approve in Environments
# 9. Confirm destruction
```

## 🧪 Testing

### Local Testing Before PR

```powershell
# Format check
terraform fmt -check -recursive

# Validate
cd environments/dev
terraform init
terraform validate

# Plan
terraform plan

# Run Checkov locally
pip install checkov
checkov -d . --framework terraform
```

### Automated Testing

Tests run automatically on every PR and merge:

**Pre-deployment tests:**
- Terraform format
- Terraform validate
- Terraform plan
- Checkov security scan

**Post-deployment tests:**
- VPC verification
- EC2 instance checks
- Network connectivity
- HTTP service availability

## 📊 Monitoring and Notifications

### GitHub Issues

Automated issues are created for:
- ✅ Successful deployments
- ❌ Failed deployments
- 🗑️ Infrastructure destruction

Issues include:
- Timestamp
- Triggering user
- Terraform outputs
- Next steps checklist

### Artifacts

Workflow artifacts are retained for:
- Terraform plans: 5 days
- Checkov reports: 30 days
- Destroy plans: 30 days
- Terraform outputs: 30 days

Access artifacts:
1. Go to Actions tab
2. Click on workflow run
3. Scroll to "Artifacts" section
4. Download desired artifact

## 🔧 Troubleshooting

### Workflow Fails: AWS Credentials Error

**Symptoms:**
```
Error: No valid credential sources found
```

**Solution:**
1. Check GitHub Secrets are set correctly
2. Verify IAM user has required permissions
3. Check AWS region is correct

### Workflow Fails: Terraform State Lock

**Symptoms:**
```
Error: Error acquiring the state lock
```

**Solution:**
```powershell
# Force unlock (use with caution)
cd environments/dev
terraform force-unlock <LOCK_ID>
```

### Checkov Fails on Valid Configuration

**Solution:**
1. Review the specific check failure
2. If justified, add to `.checkov.yml` skip list
3. Document justification in comments
4. Update PR description

### Merge Blocked: Checks Not Passing

**Solution:**
1. Click "Details" on failed check
2. Review error logs
3. Fix issues locally
4. Push new commit
5. Checks will re-run automatically

## 🎯 Best Practices

### 1. Small, Incremental Changes
- Make small, focused PRs
- Easier to review and safer to deploy
- Faster feedback loop

### 2. Always Use Feature Branches
```powershell
# Good
git checkout -b feature/add-monitoring

# Bad
git checkout main
# make changes directly on main
```

### 3. Write Descriptive Commit Messages
```powershell
# Good
git commit -m "feat: add CloudWatch alarms for EC2 instances

- Add CPU utilization alarm
- Add status check alarm
- Configure SNS notifications"

# Bad
git commit -m "updates"
```

### 4. Test Locally First
```powershell
# Always run before pushing
terraform fmt -recursive
terraform validate
terraform plan
checkov -d .
```

### 5. Review Terraform Plans Carefully
- Check resources being created
- Check resources being modified
- Check resources being destroyed
- Verify no unintended changes

### 6. Handle Secrets Properly
```powershell
# Never commit secrets
echo "*.pem" >> .gitignore
echo "*.key" >> .gitignore
echo "secrets.tfvars" >> .gitignore
```

### 7. Use Meaningful Tags
```hcl
tags = {
  Name        = "${var.project_name}-${var.environment}-resource"
  Environment = var.environment
  Project     = var.project_name
  ManagedBy   = "Terraform"
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
}
```

### 8. Document Infrastructure Changes
- Update README when adding features
- Add comments in Terraform code
- Document decisions in PR descriptions
- Keep architecture diagrams updated

## 📈 Metrics and Reporting

Track these metrics:

**Deployment Frequency:**
- How often you deploy to production
- Goal: Multiple times per day

**Lead Time:**
- Time from commit to production
- Goal: < 1 hour

**Change Failure Rate:**
- Percentage of changes causing incidents
- Goal: < 15%

**Mean Time to Recovery:**
- Time to recover from incidents
- Goal: < 1 hour

## 🔮 Future Improvements

Potential enhancements:

1. **Multi-environment support**
   - Separate workflows for dev/staging/prod
   - Environment-specific configurations

2. **Slack notifications**
   - Deployment success/failure alerts
   - PR review reminders

3. **Cost estimation**
   - Infracost integration
   - PR comments with cost impact

4. **Drift detection**
   - Scheduled runs to detect manual changes
   - Auto-remediation options

5. **Integration tests**
   - Terratest for infrastructure testing
   - End-to-end test scenarios

6. **Enhanced security**
   - SAST scanning (Semgrep, etc.)
   - Container scanning
   - Dependency vulnerability scanning

## 📚 Additional Resources

- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Checkov Documentation](https://www.checkov.io/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)

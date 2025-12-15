# Branch Protection Setup Guide

## GitHub Branch Protection Rules

Để đảm bảo code quality và security, cần thiết lập Branch Protection cho `main` branch.

### Bước 1: Truy cập Repository Settings

1. Vào repository trên GitHub
2. Click **Settings** tab
3. Trong sidebar, click **Branches**
4. Click **Add branch protection rule**

### Bước 2: Cấu hình Branch Protection

#### Branch name pattern
```
main
```

#### Protection Settings

**Require a pull request before merging:**
- ✅ Enable
- Required approvals: `1`
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require review from Code Owners (optional)

**Require status checks to pass before merging:**
- ✅ Enable
- ✅ Require branches to be up to date before merging
- Required status checks:
  - `Terraform Plan`
  - `Terraform Validate`
  - `Checkov Security Scan`

**Require conversation resolution before merging:**
- ✅ Enable

**Require signed commits:**
- ⬜ Optional (recommended for production)

**Require linear history:**
- ✅ Enable (prevents merge commits)

**Do not allow bypassing the above settings:**
- ✅ Enable (even for admins)

**Allow force pushes:**
- ⬜ Disable

**Allow deletions:**
- ⬜ Disable

### Bước 3: Environment Protection (Production)

1. Settings → **Environments** → **New environment**
2. Name: `production`
3. Configure protection rules:

**Required reviewers:**
- Add yourself or team members
- Number of required approvals: `1`

**Wait timer:**
- ⬜ Optional: Set wait time before deployment (e.g., 5 minutes)

**Deployment branches:**
- Selected branches only
- Add: `main`

### Bước 4: Environment Protection (Destruction)

1. Create another environment: `destruction`
2. Configure protection rules:

**Required reviewers:**
- Add senior team members only
- Number of required approvals: `2` (higher for destructive actions)

**Deployment branches:**
- All branches (for emergency cleanup)

## Testing Branch Protection

### Test 1: Direct Push to Main (Should Fail)

```powershell
# This should be blocked
git checkout main
git commit --allow-empty -m "test direct push"
git push origin main
# Expected: ❌ Error - protected branch
```

### Test 2: Pull Request Workflow (Should Succeed)

```powershell
# Create feature branch
git checkout -b feature/test-protection
git commit --allow-empty -m "test PR workflow"
git push origin feature/test-protection

# Create PR on GitHub
# Wait for checks to pass
# Request review
# Merge after approval
```

### Test 3: Failed Checks (Should Block Merge)

```powershell
# Create branch with invalid Terraform
git checkout -b feature/invalid-terraform
echo "invalid terraform" > environments/dev/invalid.tf
git add .
git commit -m "add invalid terraform"
git push origin feature/invalid-terraform

# Create PR
# Checks will fail
# Merge button will be disabled
```

## CODEOWNERS File

Create `.github/CODEOWNERS` to automatically request reviews:

```
# Infrastructure changes require DevOps team review
/modules/**          @your-username @devops-team
/environments/**     @your-username @devops-team
/.github/workflows/** @your-username @devops-lead

# Security-sensitive files require security team
*.pem                @security-team
*.key                @security-team
```

## Troubleshooting

### Issue: Can't merge despite passing checks
**Solution:** Ensure branch is up-to-date with main
```powershell
git checkout feature/your-branch
git merge main
git push
```

### Issue: Checks never complete
**Solution:** Check GitHub Actions tab for errors
- Verify AWS credentials in Secrets
- Check workflow YAML syntax
- Review workflow logs

### Issue: Need to bypass protection (Emergency)
**Solution:** 
1. Temporarily disable branch protection
2. Make emergency fix
3. Re-enable protection immediately
4. Document in incident report

## Best Practices

1. **Always use feature branches** - Never work directly on main
2. **Small, focused PRs** - Easier to review and safer to merge
3. **Write descriptive PR descriptions** - Help reviewers understand changes
4. **Wait for all checks** - Don't bypass even if "looks fine"
5. **Address review comments** - Security and quality feedback is valuable
6. **Keep branches up-to-date** - Regularly merge main into feature branches

# GitHub Actions Workflows for Entra ID SSO Applications

This directory contains GitHub Actions workflows for automating Terraform operations for Entra ID SSO application management.

## Workflows Overview

### 1. trigger-terraform-orchestration.yml
**Entry point workflow** that triggers on code changes and orchestrates Terraform operations across environments.

**Triggers:**
- Push to non-main branches → Deploys to **dev**
- Pull requests to main → Deploys to **test**
- Push to main branch → Deploys to **prod**

**Paths monitored:**
- `*.tf` - Root Terraform files
- `modules/**/*.tf` - Module files
- `env/**/*.tfvars` - Variable files
- `env/**/*.tfbackend` - Backend configurations

### 2. terraform-orchestration.yml
**Reusable workflow** that orchestrates the analyze/plan and apply steps.

Calls two child workflows in sequence:
1. `terraform-analyze-and-plan.yml` - Always runs
2. `terraform-apply.yml` - Runs conditionally if `run_tf_apply` is true

### 3. terraform-analyze-and-plan.yml
**Performs Terraform validation, formatting, and planning.**

Steps:
- Checkout repository
- Setup Terraform
- Initialize with backend configuration
- Validate configurations
- Check formatting
- Generate execution plan
- Upload plan artifacts (7-day retention)
- Post plan to PR (if triggered by PR)

### 4. terraform-apply.yml
**Applies the Terraform plan to create/update Entra ID applications.**

Steps:
- Checkout repository
- Setup Terraform
- Initialize with backend configuration
- Download plan artifact
- Apply plan (with environment protection)

### 5. ci-module-test.yml
**Tests the sso-application module on code changes.**

**Triggers:**
- Changes to `modules/sso-application/**`
- Manual workflow dispatch

**Test Process:**
1. Creates temporary test application
2. Applies configuration
3. Verifies application exists in Entra ID
4. Posts results to PR
5. Destroys test resources

## Prerequisites

### 1. Azure Service Principal with Federated Credentials

Create a service principal with workload identity federation:

```bash
# Create Azure AD application
APP_NAME="github-actions-entra-apps"
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)

# Create service principal
az ad sp create --id $APP_ID

# Get object IDs
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Add Entra ID permissions
# Application.ReadWrite.All
az ad app permission add --id $APP_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions 1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9=Role

# AppRoleAssignment.ReadWrite.All (for admin consent)
az ad app permission add --id $APP_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions 06b708a9-e830-4db3-a914-8e69da51d44f=Role

# Grant admin consent
az ad app permission admin-consent --id $APP_ID

# Create federated credential for GitHub Actions
REPO_OWNER="your-github-username"
REPO_NAME="terraform-entra-applications"

az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Add federated credentials for other branches/environments
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$REPO_OWNER'/'$REPO_NAME':pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 2. Azure Storage Account for Terraform State

```bash
RESOURCE_GROUP="terraform-state-rg"
STORAGE_ACCOUNT="tfstate$(openssl rand -hex 4)"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name tfstate \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login

# Grant service principal access
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"

echo "Storage Account: $STORAGE_ACCOUNT"
```

### 3. GitHub Secrets Configuration

Configure these secrets in your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AZURE_CLIENT_ID` | Service principal application (client) ID | From step 1 |
| `AZURE_TENANT_ID` | Your Entra ID tenant ID | From step 1 |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | For backend storage |
| `TF_LOG_LEVEL` | `INFO` or `DEBUG` (optional) | Terraform logging level |

### 4. GitHub Environments

Create three environments with protection rules:

**Settings → Environments → New environment**

1. **dev**
   - No protection rules (auto-deploy)
   - Add secrets if environment-specific

2. **test**
   - Required reviewers: 1+
   - Deployment branches: Pull requests to main

3. **prod**
   - Required reviewers: 2+
   - Deployment branches: main only
   - Optional: Deployment delay (e.g., 5 minutes)

### 5. Backend Configuration Files

Create backend configuration for each environment:

```bash
# Copy example files
cp env/dev/dev.tfbackend.example env/dev/dev.tfbackend
cp env/test/test.tfbackend.example env/test/test.tfbackend
cp env/prod/prod.tfbackend.example env/prod/prod.tfbackend

# Update each file with your storage account details
```

**DO NOT commit the .tfbackend files** - they are ignored by .gitignore

## Workflow Execution Flow

### Development Workflow
```
Push to feature branch
  ↓
trigger-terraform-orchestration.yml (dev job)
  ↓
terraform-orchestration.yml
  ↓
terraform-analyze-and-plan.yml
  ├─ Validate
  ├─ Format check
  └─ Generate plan → Upload artifact
  ↓
terraform-apply.yml
  ├─ Download plan
  └─ Apply (creates/updates Entra ID apps)
```

### Test Workflow (Pull Request)
```
Create PR to main
  ↓
trigger-terraform-orchestration.yml (test job)
  ↓
terraform-orchestration.yml
  ↓
terraform-analyze-and-plan.yml
  ├─ Validate
  ├─ Format check
  ├─ Generate plan
  └─ Post plan to PR comment
  ↓
terraform-apply.yml
  ├─ Wait for manual approval (test environment)
  ├─ Download plan
  └─ Apply
```

### Production Workflow
```
Merge PR to main
  ↓
trigger-terraform-orchestration.yml (prod job)
  ↓
terraform-orchestration.yml
  ↓
terraform-analyze-and-plan.yml
  ├─ Validate
  ├─ Format check
  ├─ Security analysis
  └─ Generate plan
  ↓
terraform-apply.yml
  ├─ Wait for manual approval (prod environment)
  ├─ Download plan
  └─ Apply to production
```

## CI Module Testing

The `ci-module-test.yml` workflow automatically tests module changes:

```
Push changes to modules/sso-application/
  ↓
ci-module-test.yml
  ├─ Create test configuration
  ├─ Apply → Create test app in dev
  ├─ Verify app exists in Entra ID
  ├─ Post results to PR
  └─ Destroy test app
```

## Security Considerations

1. **OIDC Authentication**: Uses OpenID Connect instead of long-lived credentials
2. **Federated Credentials**: No secrets stored in GitHub
3. **Environment Protection**: Manual approvals for test/prod
4. **Plan Artifacts**: Encrypted at rest by GitHub (7-day retention)
5. **Least Privilege**: Service principal has only required Entra ID permissions
6. **Backend Encryption**: Terraform state encrypted in Azure Storage

## Troubleshooting

### Workflow Fails with "Failed to login to Azure"
- Verify federated credentials are configured correctly
- Check subject matches: `repo:OWNER/REPO:ref:refs/heads/BRANCH`
- Ensure service principal has correct permissions

### "Error acquiring the state lock"
- Another workflow is running for the same environment
- Concurrency groups prevent parallel runs
- Wait for current workflow to complete

### "Insufficient privileges" error
- Service principal lacks required Entra ID permissions
- Grant and consent to: `Application.ReadWrite.All`, `AppRoleAssignment.ReadWrite.All`

### Plan artifacts not found
- Ensure `terraform-analyze-and-plan.yml` completed successfully
- Check artifact retention (7 days)
- Verify artifact name matches between workflows

## Customization

### Changing Terraform Version
Update in workflows:
```yaml
terraform_version: "1.9"  # Change to desired version
```

### Disabling Security Analysis
In `trigger-terraform-orchestration.yml`:
```yaml
enable_security_analysis: false  # Set to false
```

### Changing Concurrency Groups
```yaml
concurrency: my_custom_group  # Prevents parallel runs
```

### Adding New Environments
1. Create `env/staging/` directory
2. Add `staging.tfvars` and `staging.tfbackend`
3. Create GitHub environment
4. Add job to `trigger-terraform-orchestration.yml`:

```yaml
staging:
  if: github.ref == 'refs/heads/staging'
  uses: ./.github/workflows/terraform-orchestration.yml
  secrets: inherit
  concurrency: staging_entra_apps
  with:
    environment: "staging"
    working_directory: .
    tfbackend_filepath: ./env/staging/staging.tfbackend
    tfvars_filepath: ./env/staging/staging.tfvars
```

## Monitoring

View workflow runs:
- **Actions tab** in GitHub repository
- Filter by workflow name
- Download artifacts from completed runs
- Review plan outputs in PR comments

## Best Practices

1. **Always review plans** before approving applies
2. **Test in dev** before creating PRs
3. **Use descriptive commit messages** (appears in workflow logs)
4. **Monitor Entra ID audit logs** for application changes
5. **Rotate federated credentials** periodically
6. **Review and update permissions** as needed
7. **Keep Terraform version current** for security patches

## Additional Resources

- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Terraform AzureAD Provider](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
- [Azure Workload Identity](https://learn.microsoft.com/en-us/azure/active-directory/workload-identities/workload-identity-federation)

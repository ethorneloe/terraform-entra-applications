# Contributing to terraform-entra-applications

Thank you for your interest in contributing to this Terraform module for managing Microsoft Entra ID SSO applications!

## Development Setup

### Prerequisites

Before you begin, ensure you have the following tools installed:

- **Terraform** >= 1.9.0 - [Install Terraform](https://www.terraform.io/downloads)
- **Azure CLI** >= 2.50.0 - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **pre-commit** - [Install pre-commit](https://pre-commit.com/#install)
- **TFLint** - [Install TFLint](https://github.com/terraform-linters/tflint)

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ethorneloe/terraform-entra-applications.git
   cd terraform-entra-applications
   ```

2. **Install pre-commit hooks:**
   ```bash
   pre-commit install
   ```

3. **Authenticate with Azure:**
   ```bash
   az login --tenant YOUR_TENANT_ID
   ```

4. **Set your Azure subscription (if needed):**
   ```bash
   az account set --subscription YOUR_SUBSCRIPTION_ID
   ```

## Development Workflow

### Testing Changes Locally

1. **Copy and modify example tfvars:**
   ```bash
   cp env/dev/dev.tfvars env/dev/dev.tfvars.local
   # Edit dev.tfvars.local with your test values
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Run validation:**
   ```bash
   terraform validate
   ```

4. **Check formatting:**
   ```bash
   terraform fmt -check -recursive
   ```

5. **Run TFLint:**
   ```bash
   tflint --recursive
   ```

6. **Generate a plan:**
   ```bash
   terraform plan -var-file=env/dev/dev.tfvars.local
   ```

7. **Apply changes (if testing in a dev environment):**
   ```bash
   terraform apply -var-file=env/dev/dev.tfvars.local
   ```

## Code Standards

### Terraform Best Practices

- **Run `terraform fmt -recursive` before committing** to ensure consistent formatting
- **All variables must have descriptions** - Variables without descriptions will be rejected
- **All outputs must have descriptions** - Outputs without descriptions will be rejected
- **Use meaningful resource names** - Resource names should be descriptive and follow the pattern `resource_type.descriptive_name`
- **Add validation to variables** where appropriate to catch configuration errors early
- **Use `dynamic` blocks** for optional nested blocks instead of conditionals

### Security Guidelines

**IMPORTANT:** This module intentionally does NOT manage client secrets or certificates in Terraform.

- **Never add client secret or certificate management** - These should be managed outside Terraform
- **Use Workload Identity Federation** whenever possible to eliminate secrets entirely
- **Validate sensitive inputs** - Ensure proper validation for security-sensitive variables
- **Follow principle of least privilege** - API permissions should be minimal and necessary

### Documentation

- Update the README.md if you change module behavior or add new features
- Document all variables with clear descriptions
- Document all outputs with clear descriptions
- Add code comments for complex logic or non-obvious implementations
- Update examples in the `env/` directories if needed

## Submitting Changes

### Pull Request Process

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the code standards above

3. **Run pre-commit checks:**
   ```bash
   pre-commit run --all-files
   ```

4. **Commit your changes:**
   ```bash
   git add .
   git commit -m "Description of your changes"
   ```

5. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request** on GitHub with:
   - Clear description of changes
   - Any related issue numbers
   - Screenshots/examples if applicable
   - Test results

### Pull Request Guidelines

- Keep changes focused and atomic
- Write clear commit messages
- Ensure all CI checks pass
- Add tests if applicable
- Update documentation as needed

## Module Structure

```
terraform-entra-applications/
├── modules/
│   └── sso-application/        # Reusable SSO application module
│       ├── main.tf             # Main resource definitions
│       ├── variables.tf        # Input variables
│       ├── outputs.tf          # Output values
│       └── README.md           # Module documentation
├── env/                        # Environment-specific configurations
│   ├── dev/
│   ├── test/
│   └── prod/
├── main.tf                     # Root module configuration
├── variables.tf                # Root variables
├── outputs.tf                  # Root outputs
├── providers.tf                # Provider configuration
├── .pre-commit-config.yaml     # Pre-commit hooks
├── .tflint.hcl                 # TFLint configuration
└── .github/
    └── workflows/
        └── terraform.yml       # CI/CD pipeline

```

## Testing

### Manual Testing

Before submitting a PR, test your changes in a development environment:

1. Use the dev environment configuration
2. Run `terraform plan` and review the output
3. Apply changes in a non-production environment
4. Verify the application is created correctly in the Entra admin center
5. Test authentication flows if applicable
6. Clean up test resources when done

### Automated Testing

The CI/CD pipeline will automatically:
- Run `terraform fmt -check`
- Run `terraform validate`
- Run TFLint
- Generate a plan for review (on PRs)

## Credential Management

### Creating Test Applications

When testing, you may need to create client secrets:

1. **Create the application with Terraform:**
   ```bash
   terraform apply -var-file=env/dev/dev.tfvars.local
   ```

2. **Add a secret manually:**
   ```bash
   az ad app credential reset --id <application-id> --append
   ```

3. **Store the secret securely:**
   - For production: Use Azure Key Vault
   - For testing: Use environment variables or a local `.env` file (never commit!)

### Workload Identity Federation (Recommended)

For GitHub Actions and other supported platforms, use federated credentials instead of secrets:

```hcl
federated_identity_credentials = [
  {
    display_name = "GitHub Actions"
    description  = "For CI/CD pipeline"
    audiences    = ["api://AzureADTokenExchange"]
    issuer       = "https://token.actions.githubusercontent.com"
    subject      = "repo:owner/repo:ref:refs/heads/main"
  }
]
```

## Getting Help

- **Questions?** Open a [GitHub Discussion](https://github.com/ethorneloe/terraform-entra-applications/discussions)
- **Bug reports?** Open a [GitHub Issue](https://github.com/ethorneloe/terraform-entra-applications/issues)
- **Security concerns?** See SECURITY.md (if available) or open a private security advisory

## License

By contributing, you agree that your contributions will be licensed under the same license as this project (see LICENSE file).

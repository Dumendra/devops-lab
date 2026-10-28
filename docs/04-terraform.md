# Lesson 4: Infrastructure as Code with Terraform

## Learning goals

By the end of this lesson you can:

- Explain why infrastructure should be versioned and reviewed like code.
- Describe Terraform state and why it must not be committed.
- Initialize, format, validate, plan, apply, and destroy a real AWS resource.
- Read an ECR repository with immutable tags, scanning, and a lifecycle policy.
- Describe how CI should authenticate to AWS without long-lived keys.

## Why infrastructure as code

Manual console changes are undocumented, hard to reproduce, and easy to drift.
Terraform records desired state in configuration files and actual state in a
state file. A plan shows the difference before anything changes.

Rules for this lesson:

- Always run `plan` and read it before `apply`.
- Never commit `.tfstate` or `.terraform/`.
- Use a sandbox AWS account with a budget alert.
- Run `terraform destroy` when finished.

## Files in this module

- [`versions.tf`](../terraform/versions.tf): Terraform and provider versions.
- [`variables.tf`](../terraform/variables.tf): region, repository name, tags.
- [`main.tf`](../terraform/main.tf): provider plus ECR repository and lifecycle
  policy.
- [`outputs.tf`](../terraform/outputs.tf): repository URL and ARN.
- [`terraform.tfvars.example`](../terraform/terraform.tfvars.example): sample
  values. Copy it to `terraform.tfvars`, which is gitignored.

The ECR repository uses:

- `image_tag_mutability = "IMMUTABLE"`: an existing tag cannot be overwritten.
  This makes deployments auditable.
- `scan_on_push = true`: AWS scans images for known vulnerabilities.
- A lifecycle policy that keeps the ten most recent `sha-` images and expires
  untagged images after seven days. Registries grow forever without this.

## Commands

```powershell
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars

terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
terraform output repository_url
```

Destroy when done:

```powershell
terraform destroy
```

Useful additions:

```powershell
terraform show
terraform state list
terraform plan -refresh-only
```

## Authenticate to AWS

Any standard method works, for example:

```powershell
aws configure
# or
aws sso login --profile devops-lab
$env:AWS_PROFILE = "devops-lab"
```

Prefer SSO or short-lived credentials. Do not paste access keys into source
files, shell history, or GitHub secrets when OIDC is available.

## Push an image to ECR

```powershell
$REPO = terraform output -raw repository_url
$TAG = "sha-$(git rev-parse --short HEAD)"

aws ecr get-login-password --region us-east-1 |
  docker login --username AWS --password-stdin $REPO

docker tag devops-lab-api:local "${REPO}:${TAG}"
docker push "${REPO}:${TAG}"
```

Because tags are immutable, pushing the same tag again fails. Build a new commit
or choose a different tag. That failure is the feature, not a bug.

## Remote state

Local state is fine for a single learner. Teams need a shared, locked backend.
Example S3 backend (Terraform 1.10+ supports native S3 locking with
`use_lockfile`):

```hcl
terraform {
  backend "s3" {
    bucket       = "my-org-terraform-state"
    key          = "devops-lab/ecr/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

Update `required_version` to `>= 1.10.0` if you use this. The bucket must exist
and have versioning enabled. State can contain sensitive values, so restrict
access to it.

## CI with Terraform

A safe pipeline runs:

1. `terraform fmt -check`
2. `terraform init -backend=false` for validation on pull requests
3. `terraform validate`
4. `terraform plan` and posts the plan for review
5. `terraform apply` only on `main`, after approval

Use GitHub OIDC with an AWS IAM role instead of storing access keys. The
workflow requests a short-lived token, and AWS trusts that token only for your
repository and branch.

## Exercises

### Exercise 4.1: Read the plan

Before applying, identify which resource attributes are known after apply and
explain why. Then apply and compare the output with the plan.

### Exercise 4.2: Immutable tags

Push the same image tag twice. Record the error. Explain how immutability
prevents a common cause of unreproducible deployments.

### Exercise 4.3: Lifecycle tuning

Change the policy to keep 30 tagged images. Run `plan` and explain why the
change updates the policy in place.

### Exercise 4.4: Environments with variables

Create two tfvars files (`dev.tfvars`, `prod.tfvars`) with different repository
names. Plan both with `-var-file`. Do not apply production without approval.

### Exercise 4.5: Extract a module

Move the ECR resources into `modules/ecr/` and call the module from the root.
Add inputs and outputs. Verify that the plan is unchanged.

### Exercise 4.6: Remote state

Create an S3 bucket with versioning and encryption, configure the backend, and
migrate state with `terraform init -migrate-state`. Confirm that the local state
file no longer exists.

### Exercise 4.7: Plan in CI

Add a workflow that plans on pull requests using OIDC. Post the plan as a
comment. Never apply from a pull request.

### Exercise 4.8: Cleanup discipline

Run `terraform destroy`, then `terraform plan` and confirm that no resources
remain. Add a budget alert in the AWS account before starting optional EKS
exercises.

## Checkpoint

You are done when you can:

- Explain state, plan, and apply without notes.
- Apply the module and push an immutable image to ECR.
- Explain why state and credentials never belong in Git.
- Describe how a team shares and locks state.

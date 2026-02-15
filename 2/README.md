# Day 2 – S3 + Auth Revisited

Today was straightforward: wiring Terraform to AWS properly and creating a clean S3 bucket from code.

Nothing conceptually new — but I treated this as a fundamentals reset. Authentication discipline and S3 hygiene matter more than people admit.

---

## Focus Today

- Revisit AWS authentication flow for Terraform
- Validate credential resolution order
- Create an S3 bucket with proper naming discipline
- Run through full Terraform lifecycle
- Clean up cleanly

---

# AWS Authentication (Terraform Perspective)

Terraform does not “log in.”
It relies on AWS SDK credential resolution.

Before creating anything, credentials must be resolvable.

Common methods I reviewed:

### 1. AWS CLI Config

```bash
aws configure
```

Stored in:

```
~/.aws/credentials
~/.aws/config
```

### 2. Environment Variables

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

Useful for CI/CD pipelines.

### 3. IAM Roles

Best practice in production:

- EC2 instance profile
- ECS task role
- EKS IRSA

No static credentials.

### 4. Named Profiles

```bash
AWS_PROFILE=dev terraform plan
```

Essential when juggling multiple accounts.

---

# Credential Resolution Order (Mental Note)

Terraform (via AWS SDK) checks roughly in this order:

1. Environment variables
2. Shared credentials file
3. IAM role (if running on AWS infra)

If authentication fails, it's almost always misconfigured profile or region drift.

---

# S3 Bucket Creation (Baseline)

This wasn’t about complex configuration — just validating the pipeline.

Basic structure:

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "my-unique-bucket-name-12345"
}
```

Reminder:

> S3 bucket names are globally unique across AWS.

Collision errors are normal — just pick something globally distinct.

---

# Terraform Workflow (Run Through Again)

Executed the full loop:

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform show
terraform destroy
```

Still the cleanest infrastructure lifecycle model in the industry.

---

# Observations

- Region mismatch is the most common silent issue.
- Bucket naming rules are strict (lowercase, no underscores).
- Terraform will not auto-fix naming violations.
- Always confirm region via:

```bash
aws configure list
```

---

# Cost & Cleanup Discipline

Even in free tier:

- S3 storage accumulates
- Versioning multiplies cost
- Incomplete multipart uploads linger

Always destroy after practice:

```bash
terraform destroy
```

Infrastructure experiments should not become background billing noise.

---

# Troubleshooting Reminders

If something breaks:

- Confirm credentials
- Confirm region
- Confirm bucket uniqueness
- Run with debug if needed:

```bash
TF_LOG=DEBUG terraform plan
```

For deeper issues:

- CloudTrail logs never lie

---

# Takeaways

- Authentication setup is foundational.
- Static credentials are acceptable locally, not in production.
- Terraform lifecycle remains predictable.
- Cleanup is part of professional discipline.

---

Next:
State management and remote backends (S3 + DynamoDB).
That’s where things become production-grade.

```




```

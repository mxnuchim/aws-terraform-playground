# AWS IAM User Provisioning — Terraform

Automated, CSV-driven IAM user provisioning on AWS. One `terraform apply` creates users, enables console login, and sorts every user into the correct permission group based on their department and job title — no console clicking required.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
  - [Variables](#variables)
  - [CSV Schema](#csv-schema)
- [Resources Provisioned](#resources-provisioned)
- [How It Works](#how-it-works)
  - [Data Flow](#data-flow)
  - [Username Generation](#username-generation)
  - [Dynamic Group Assignment](#dynamic-group-assignment)
  - [Lifecycle Management](#lifecycle-management)
- [Tagging Strategy](#tagging-strategy)
- [Security Considerations](#security-considerations)
- [Production Readiness Checklist](#production-readiness-checklist)
- [Extending This Project](#extending-this-project)
- [Known Limitations](#known-limitations)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

Managing IAM users manually through the AWS console doesn't scale. It's error-prone, inconsistent, unauditable, and painful at anything beyond a handful of users.

This project solves that by treating your user roster as code. HR updates a CSV, an engineer runs a plan, gets approval, and applies. The result is deterministic, version-controlled, and fully reproducible IAM state — with zero console clickops.

**Core capabilities:**

- Bulk user creation from a CSV file
- Automatic console login profile generation with forced password reset
- Dynamic, tag-based group assignment (no hardcoded user lists)
- Consistent resource tagging across all provisioned infrastructure
- Declarative lifecycle management that avoids drift-induced churn

---

## Architecture

```

┌─────────────────────────────────────────────────────────────┐
│ users.csv │
│ (Source of Truth — version controlled) │
└─────────────────────────┬───────────────────────────────────┘
│ csvdecode()
▼
┌─────────────────────────────────────────────────────────────┐
│ locals.users │
│ Parsed list of user objects │
└──────────┬──────────────────────────────┬───────────────────┘
│ for_each │ for_each
▼ ▼
┌─────────────────────┐ ┌────────────────────────────────┐
│ aws_iam_user │ │ aws_iam_user_login_profile │
│ (one per row) │─────▶│ (console access + temp pwd) │
└─────────────────────┘ └────────────────────────────────┘
│
│ tags.Department / tags.JobTitle
▼
┌─────────────────────────────────────────────────────────────┐
│ aws_iam_group_membership │
│ Education │ Managers │ Engineers (filtered by tags) │
└─────────────────────────────────────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│ aws_iam_group │
│ Education │ Managers │ Engineers │
│ [Attach permission policies here] │
└─────────────────────────────────────────────────────────────┘

```

---

## Project Structure

```

.
├── main.tf # Provider configuration
├── locals.tf # Computed locals (CSV parsing, common tags)
├── users.tf # IAM user + login profile resources
├── groups.tf # IAM groups and group memberships
├── variables.tf # Input variable declarations
├── outputs.tf # Output values (usernames, group names)
├── terraform.tfvars # Your environment-specific values (gitignored)
├── terraform.tfvars.example # Safe template to commit
├── users.csv # User roster — the source of truth
└── README.md

```

---

## Prerequisites

| Tool                                                             | Version   | Purpose                         |
| ---------------------------------------------------------------- | --------- | ------------------------------- |
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | >= 1.5.0  | Infrastructure provisioning     |
| [AWS CLI](https://aws.amazon.com/cli/)                           | >= 2.x    | Authentication                  |
| AWS Account                                                      | —         | Target environment              |
| IAM permissions                                                  | See below | Ability to create IAM resources |

**Required IAM permissions for the operator running Terraform:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateUser",
        "iam:DeleteUser",
        "iam:GetUser",
        "iam:ListUsers",
        "iam:TagUser",
        "iam:CreateLoginProfile",
        "iam:DeleteLoginProfile",
        "iam:GetLoginProfile",
        "iam:UpdateLoginProfile",
        "iam:CreateGroup",
        "iam:DeleteGroup",
        "iam:GetGroup",
        "iam:AddUserToGroup",
        "iam:RemoveUserFromGroup"
      ],
      "Resource": "*"
    }
  ]
}
```

## Configuration

### Variables

| Variable      | Type     | Required | Description                                      |
| ------------- | -------- | -------- | ------------------------------------------------ |
| `environment` | `string` | Yes      | Deployment environment (`staging`, `production`) |
| `company`     | `string` | Yes      | Company name — applied to all resource tags      |

### CSV Schema

`users.csv` must contain the following columns:

| Column       | Required | Example           | Notes                            |
| ------------ | -------- | ----------------- | -------------------------------- |
| `first_name` | Yes      | `Jane`            | Used in username generation      |
| `last_name`  | Yes      | `Doe`             | Used in username generation      |
| `department` | Yes      | `Education`       | Drives group assignment          |
| `job_title`  | Yes      | `Senior Engineer` | Drives Managers group assignment |

**Example `users.csv`:**

```csv
first_name,last_name,department,job_title
Jane,Doe,Education,Head of Curriculum
John,Smith,Engineering,Senior Engineer
Alice,Johnson,Education,Teacher
Bob,Williams,Engineering,DevOps Engineer
Carol,Davis,Operations,Engineering Manager
Eve,Martinez,Operations,CEO
```

> **Important:** Column headers are case-sensitive and must match exactly.

---

## Resources Provisioned

| Resource                     | Count         | Description                                  |
| ---------------------------- | ------------- | -------------------------------------------- |
| `aws_iam_user`               | 1 per CSV row | IAM user with standardised username and tags |
| `aws_iam_user_login_profile` | 1 per user    | Console login with temporary password        |
| `aws_iam_group`              | 3             | Education, Managers, Engineers               |
| `aws_iam_group_membership`   | 3             | Dynamic group assignments based on tags      |

---

## How It Works

### Data Flow

Terraform reads `users.csv` at plan time using `file()` and `csvdecode()`. This produces a list of objects that feeds every downstream resource. The CSV is the single source of truth — change the CSV, run `apply`, and infrastructure reflects it.

### Username Generation

Usernames follow the pattern `{first_initial}_{last_name}` in lowercase, placed under the `/users/` IAM path.

```
Jane Doe      →  j_doe
John Smith    →  j_smith
Alice Johnson →  a_johnson
```

### Dynamic Group Assignment

Group membership is derived from user tags — not from hardcoded lists. This is the key architectural decision that makes the system maintainable.

| Group         | Assignment Rule                            |
| ------------- | ------------------------------------------ |
| **Education** | `tags.Department == "Education"`           |
| **Managers**  | `tags.JobTitle` matches `Manager` or `CEO` |
| **Engineers** | `tags.Department == "Engineering"`         |

When you change someone's department in the CSV and re-apply, Terraform automatically removes them from the old group and adds them to the new one.

### Lifecycle Management

The `aws_iam_user_login_profile` resource uses a `lifecycle` block to ignore changes to `password_reset_required` and `password_length` after initial creation:

```hcl
lifecycle {
  ignore_changes = [password_reset_required, password_length]
}
```

**Why this matters:** After a user logs in for the first time, AWS sets `password_reset_required` to `false`. Without `ignore_changes`, Terraform would detect this as drift and attempt to re-force password resets on every subsequent plan. This lifecycle rule tells Terraform: _you created it, AWS owns it now._

---

## Tagging Strategy

All resources receive a baseline set of tags via `local.common_tags`, merged with resource-specific tags where applicable.

**Common tags (all resources):**

| Tag           | Value             | Purpose                                  |
| ------------- | ----------------- | ---------------------------------------- |
| `Environment` | `var.environment` | Cost allocation by environment           |
| `ManagedBy`   | `"Terraform"`     | Signals this resource is IaC-managed     |
| `Company`     | `var.company`     | Multi-tenant or multi-org identification |

**User-specific tags:**

| Tag           | Value                  | Purpose                            |
| ------------- | ---------------------- | ---------------------------------- |
| `DisplayName` | `"Jane Doe"`           | Human-readable name in the console |
| `Department`  | `"Education"`          | Drives group assignment logic      |
| `JobTitle`    | `"Head of Curriculum"` | Drives Managers group filter       |

Tags are used as the mechanism for group assignment — this is intentional. It means the same data that makes resources readable in the console also drives automation logic, with no duplication.

---

## Security Considerations

- **Forced password reset** — All users must set their own password on first login. Temporary passwords generated by Terraform never persist.
- **No inline policies** — Permissions are attached at the group level, never directly to users. This enforces policy consistency and simplifies auditing.
- **Path-based organisation** — Users are created under `/users/` and groups under `/groups/`, enabling IAM path-based access control at the operator level.
- **Tagging for auditability** — The `ManagedBy: Terraform` tag makes it immediately clear which resources are under IaC control and should not be modified manually.

> ⚠️ **Note:** This project does not enforce MFA. For production deployments, attach an MFA enforcement policy to each group. See [Extending This Project](#extending-this-project).

---

## Production Readiness Checklist

This project is a solid foundation. Before promoting to production, consider the following:

### State Management

- [ ] Migrate state to a remote backend (S3 + DynamoDB for locking)
- [ ] Enable server-side encryption on the state bucket
- [ ] Restrict state bucket access via bucket policy

### Security Hardening

- [ ] Attach permission policies to each IAM group
- [ ] Add an MFA enforcement policy to all groups
- [ ] Configure an account-level IAM password policy (`aws_iam_account_password_policy`)
- [ ] Enable AWS CloudTrail for IAM event auditing

### Resilience

- [ ] Handle username collision (e.g., two users with the same first initial + last name)
- [ ] Use email address as the `for_each` key instead of `first_name` to guarantee uniqueness
- [ ] Add input validation to catch malformed CSV rows before they reach AWS

### Operations

- [ ] Add CI/CD pipeline with `terraform plan` on PR and `terraform apply` on merge
- [ ] Post plan output as a PR comment for peer review before any apply
- [ ] Add a `terraform validate` and `tflint` step to the pipeline
- [ ] Store `users.csv` in a separate, access-controlled repository if it contains sensitive HR data

### Observability

- [ ] Define meaningful `outputs.tf` values (created usernames, group ARNs)
- [ ] Enable AWS Config rules to detect out-of-band IAM changes

---

## Extending This Project

**Add MFA enforcement:**

```hcl
resource "aws_iam_policy" "require_mfa" {
  name   = "RequireMFA"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Deny"
      Action   = "*"
      Resource = "*"
      Condition = {
        BoolIfExists = {
          "aws:MultiFactorAuthPresent" = "false"
        }
      }
    }]
  })
}
```

**Add remote state backend:**

```hcl
terraform {
  backend "s3" {
    bucket         = "your-company-terraform-state"
    key            = "iam/users/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

**Attach a policy to a group:**

```hcl
resource "aws_iam_group_policy_attachment" "engineers_readonly" {
  group      = aws_iam_group.engineers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
```

---

## Known Limitations

| Limitation                          | Impact                                                                | Recommended Fix                                          |
| ----------------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------- |
| `first_name` used as `for_each` key | Duplicate first names cause a plan error                              | Use `email` as the unique key                            |
| No collision handling on usernames  | Two users can generate identical usernames                            | Append a unique suffix (e.g., employee ID)               |
| No group policies attached          | Groups exist but grant no permissions                                 | Add `aws_iam_group_policy_attachment` resources          |
| CSV is read at plan time            | Requires local file access; not pipeline-friendly without extra steps | Consider S3 data source or Terraform Cloud variable sets |
| No MFA enforcement                  | Users can operate without MFA                                         | Add deny policy on `!MultiFactorAuthPresent`             |

---

## Contributing

Pull requests are welcome. For significant changes, open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/mfa-enforcement`)
3. Commit your changes (`git commit -m 'Add MFA enforcement policy'`)
4. Push to the branch (`git push origin feature/mfa-enforcement`)
5. Open a pull request

Please run `terraform fmt` and `terraform validate` before submitting.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

<div align="center">
  <sub>Built with Terraform · Deployed on AWS · No clickops were harmed in the making of this project</sub>
</div>

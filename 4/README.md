# Terraform Variables Demo (Keeping It Simple)

# 🎯 Goal

Demonstrate the **three types of Terraform variables** using a single S3 bucket:

- Input variables
- Local variables
- Output variables

Nothing more.

One resource. Clean structure. Clear behavior.

---

# 🧠 The Mental Model

Think of Terraform like a function:

- **Input variables** → parameters
- **Locals** → internal computed values
- **Resources** → execution
- **Outputs** → return values

That’s it.

---

# 📥 1. Input Variables (variables.tf)

These are external configuration values.

They allow customization without editing resource code.

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "bucket_name" {
  description = "Base S3 bucket name"
  type        = string
  default     = "my-terraform-bucket"
}
```

### How They’re Used

```hcl
resource "aws_s3_bucket" "demo" {
  bucket = var.bucket_name

  tags = {
    Environment = var.environment
  }
}
```

Important reminder:

Always reference input variables using:

```
var.<variable_name>
```

Never hardcode values inside resources.

---

# 🏗 2. Local Variables (locals.tf)

Locals are internal computed values.

They are not meant to be overridden.

They help centralize logic and reduce repetition.

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = "Terraform-Demo"
  }

  full_bucket_name = "${var.environment}-${var.bucket_name}-${random_string.suffix.result}"
}
```

Then used like this:

```hcl
resource "aws_s3_bucket" "demo" {
  bucket = local.full_bucket_name
  tags   = local.common_tags
}
```

Note:

Input variables define what changes.
Locals define how values are constructed.

That separation keeps modules clean.

---

# 📤 3. Output Variables (output.tf)

Outputs expose useful values after deployment.

They act like return values.

```hcl
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.demo.arn
}

output "environment" {
  description = "Environment used"
  value       = var.environment
}

output "tags" {
  description = "Computed tags"
  value       = local.common_tags
}
```

After `terraform apply`, you can run:

```
terraform output
terraform output bucket_name
terraform output -json
```

Outputs are stored in state — no need to re-apply.

---

# 📂 Clean File Structure

```
├── main.tf
├── variables.tf
├── locals.tf
├── output.tf
├── provider.tf
├── terraform.tfvars
└── README.md
```

This structure mirrors real-world Terraform module layout.

---

# 🔁 Variable Precedence (Practical Version)

From lowest to highest precedence:

1. Default values (inside `variables.tf`)
2. Environment variables (`TF_VAR_`)
3. `terraform.tfvars`
4. `-var-file`
5. `-var` (command line)

Highest wins.

---

# 🧪 Practical Testing

## 1️⃣ Default Only

Temporarily hide `terraform.tfvars`:

```
mv terraform.tfvars terraform.tfvars.backup
terraform plan
```

Uses:

```
environment = "staging"
```

Restore file:

```
mv terraform.tfvars.backup terraform.tfvars
```

---

## 2️⃣ Using terraform.tfvars

Example `terraform.tfvars`:

```hcl
environment = "demo"
bucket_name = "terraform-demo-bucket"
```

Run:

```
terraform plan
```

Uses values from tfvars automatically.

---

## 3️⃣ Command Line Override

```
terraform plan -var="environment=production"
```

Overrides everything else.

---

## 4️⃣ Environment Variables

```
export TF_VAR_environment="from-env"
terraform plan
```

Works — but command line still wins.

Clean up:

```
unset TF_VAR_environment
```

---

## 5️⃣ Using Different tfvars Files

```
terraform plan -var-file="dev.tfvars"
terraform plan -var-file="production.tfvars"
```

This is how real environments are typically handled.

Explicit > implicit.

---

# 🚀 What This Demo Actually Creates

One S3 bucket.

But it demonstrates:

- Parameterization (input variables)
- Computation (locals)
- Exposure (outputs)
- Precedence behavior

That’s enough to understand 80% of Terraform variable usage.

---

# 🔧 Try These Commands

```
terraform init
terraform plan
terraform apply
terraform output
terraform destroy
```

Keep it simple. Observe behavior. Change inputs. Re-run.

---

# 💡 Key Takeaways

- Input variables → configure behavior
- Locals → compute reusable values
- Outputs → expose results
- Precedence matters
- Keep logic centralized
- Avoid hardcoding environment values

```

```

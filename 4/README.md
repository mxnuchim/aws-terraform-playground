# Day 4 – Terraform Variables

Variables are not just a Terraform feature — they’re an architectural hygiene tool aimed at removing chaos from configuration.

---

# Why Variables Matter (Beyond “Don’t Repeat Yourself”)

At surface level:

> Variables prevent repeating the same values everywhere.

But in reality, they:

- Enforce consistency across resources
- Reduce human error
- Enable multi-environment deployments
- Make infrastructure reusable
- Improve change safety

Hardcoding `dev` in 15 places is not just messy — it’s operational risk.

One typo (`staging` vs `stage`) and now your tagging strategy is inconsistent.

That’s how drift begins.

<img width="1071" height="487" alt="Screenshot 2026-02-15 at 17 24 32" src="https://github.com/user-attachments/assets/0a289b40-9c1d-4a64-a134-2ec58f03420f" />


---

# The Core Pattern

Instead of this:

```hcl
tags = {
  Environment = "dev"
}
```

We define:

```hcl
variable "environment" {
  default = "dev"
  type    = string
}
```

Then reference:

```hcl
tags = {
  Environment = var.environment
}
```

The important detail:

We reference using **the local variable name**, not the value.

`var.environment`
NOT
`var.dev`

This is subtle but foundational.

---

# String Interpolation – Important Reminder

When concatenating strings:

```hcl
"${var.environment}-vpc"
```

Terraform must resolve the variable first, then concatenate.

Senior engineer takeaway:
Know when you need interpolation syntax and when direct reference is enough.

---

# Types – More Important Than They Look

Terraform variables are categorized by **type constraints**.

## Primitive Types

- `string`
- `number`
- `bool`

These are straightforward.

But the real power starts with:

## Complex Types

- `list`
- `set`
- `map`
- `object`
- `tuple`

And special types:

- `null`
- `any`

Key reminder:

If you omit `type`, Terraform assumes `any`.

That’s flexible.
But flexibility without constraints can create ambiguity.

In mature systems, I should prefer explicit typing.

Strong typing = fewer surprises.

---

# Input Variables vs Locals vs Outputs

Today clarified the distinction cleanly.

## 1. Input Variables (`variable`)

Purpose:
External configuration.

These are meant to be overridden.

They define what _can change_.

Think of them as:
The interface of the module.

---

## 2. Locals (`locals`)

Purpose:
Internal computation.

They are not meant to be overridden.

Example:

```hcl
locals {
  bucket_name = "${var.channel}-bucket-${var.environment}"
}
```

Then used as:

```hcl
bucket = local.bucket_name
```

This is powerful.

Variables define input.
Locals derive computed values.

This separation improves readability and avoids repeating logic everywhere.

As systems grow, locals become critical for:

- Naming conventions
- Tag maps
- Derived IDs
- Cross-resource computed strings

This is architectural clarity, not just syntactic sugar.

---

## 3. Output Variables (`output`)

Purpose:
Expose values after apply.

Example:

```hcl
output "vpc_id" {
  value = aws_vpc.sample.id
}
```

Outputs:

- Print values to console
- Allow cross-module communication
- Surface important infrastructure identifiers

Reminder:
Outputs only resolve after `apply`.

And:
`terraform output` retrieves stored output values from state.

That’s useful when chaining modules or debugging.

---

# Variable Precedence (This Is Operationally Critical)

Terraform loads variables in a specific order.

From lowest to highest precedence:

1. Default inside `variable` block
2. Environment variables (`TF_VAR_environment`)
3. `terraform.tfvars`
4. `*.auto.tfvars`
5. `-var`
6. `-var-file`

The highest one wins.

Example:

If default is `"dev"`,
but I export:

```bash
export TF_VAR_environment=stage
```

Terraform will use `"stage"`.

If I then define:

```hcl
# terraform.tfvars
environment = "preprod"
```

Now `"preprod"` wins.

If I run:

```bash
terraform plan -var="environment=prod"
```

Now `"prod"` wins over everything.

This is not academic.

This is how environments get accidentally misconfigured.

Senior engineer takeaway:
Be intentional about where variables are defined.
Avoid accidental overrides in CI/CD pipelines.

---

# Preferred Patterns (From Experience)

### For teams:

Use `terraform.tfvars` for environment-specific values.

### For CI:

Use `-var-file` with explicit environment files.

Example:

```
terraform apply -var-file=prod.tfvars
```

Explicit > implicit.

### For secrets:

Do NOT rely on tfvars committed to Git.
Use secret managers or environment injection.

And remember:
Environment variables are stored in shell history.

---

# A Subtle but Important Lesson Today

Using variables is not just about convenience.

It’s about:

- Reducing configuration drift
- Making modules reusable
- Enabling clean environment promotion
- Improving change safety
- Separating configuration from logic

Variables define what changes.
Locals define how values are constructed.
Outputs define what is exposed.

That’s a clean mental model.

---

# Debugging Reality Check

Two reminders from today’s demo:

1. Resource names change across provider versions.
   Never blindly trust autocomplete.
   Always verify against documentation.

2. `terraform plan` cannot detect runtime AWS API errors.
   Invalid AMI IDs only fail at `apply`.

Plan ≠ guarantee of success.

---

# Mental Model Upgrade

Earlier Terraform mindset:

> “Variables help avoid repetition.”

Now:

> “Variables define the external contract of infrastructure.”

That shift matters.

When writing modules:

- Variables = interface
- Locals = implementation logic
- Resources = execution
- Outputs = exported API

That’s clean software engineering applied to infrastructure.

# Day 7 – Terraform Type Constraints (Personal Notes)

Today was all about **type constraints** in Terraform — basically defining what kind of data a variable can hold. This keeps configs predictable and prevents weird runtime errors.

Terraform variables can be grouped two ways:

- **By purpose** → input, output, locals
- **By value type (type constraints)** → primitive & complex

This README focuses on **type constraints**.

---

# 1. Primitive Types

Simple, single values.

## 1.1 String

Always wrapped in double quotes.

```hcl
variable "region" {
  type    = string
  default = "us-east-1"
}
```

Usage:

```hcl
provider "aws" {
  region = var.region
}
```

---

## 1.2 Number

Used for numeric values like counts or ports.

```hcl
variable "instance_count" {
  type    = number
  default = 1
}
```

Usage:

```hcl
resource "aws_instance" "example" {
  count = var.instance_count
}
```

---

## 1.3 Boolean (bool)

Only `true` or `false`.

```hcl
variable "monitoring_enabled" {
  type    = bool
  default = true
}
```

Usage:

```hcl
resource "aws_instance" "example" {
  monitoring = var.monitoring_enabled
}
```

---

# 2. Complex Types

Store multiple values.

---

## 2.1 List

Ordered collection.

- Can have duplicates
- Accessed by index
- Starts at index `0`

```hcl
variable "allowed_vm_types" {
  type = list(string)
  default = [
    "t2.micro",
    "t2.small",
    "t3.micro"
  ]
}
```

Usage:

```hcl
resource "aws_instance" "example" {
  instance_type = var.allowed_vm_types[1] # t2.small
}
```

Important:

- Order matters
- Duplicates allowed

---

## 2.2 Set

Unordered collection.

- No duplicates
- Cannot access by index
- Must convert to list if indexing is needed

```hcl
variable "allowed_regions" {
  type = set(string)
  default = [
    "us-east-1",
    "us-west-1",
    "us-east-1" # duplicate removed automatically
  ]
}
```

❌ This won’t work:

```hcl
var.allowed_regions[0]
```

✅ Convert first:

```hcl
tolist(var.allowed_regions)[0]
```

Key difference:

- **List = ordered**
- **Set = unordered + unique**

---

## 2.3 Map

Key-value pairs.
All values must be same type.

```hcl
variable "tags" {
  type = map(string)

  default = {
    environment = "dev"
    created_by  = "terraform"
  }
}
```

Usage:

```hcl
resource "aws_instance" "example" {
  tags = var.tags
}
```

Great for:

- Tags
- Metadata
- Reusable configs

---

## 2.4 Tuple

Like a list, but:

- Can contain multiple data types
- Order and type must match exactly

```hcl
variable "ingress_values" {
  type = tuple([number, string, number])

  default = [443, "tcp", 443]
}
```

Usage:

```hcl
resource "aws_vpc_security_group_ingress_rule" "tls" {
  from_port   = var.ingress_values[0]
  ip_protocol = var.ingress_values[1]
  to_port     = var.ingress_values[2]
}
```

Rules:

- Position matters
- Data type must match declared type

---

## 2.5 Object

Structured key-value collection
Each field has its own type.

```hcl
variable "config" {
  type = object({
    region         = string
    monitoring     = bool
    instance_count = number
  })

  default = {
    region         = "us-east-1"
    monitoring     = true
    instance_count = 1
  }
}
```

Usage:

```hcl
provider "aws" {
  region = var.config.region
}
```

Difference from map:

- Map → all values same type
- Object → each field can have different type

---

# 3. Null & Any

## Null

Represents empty value.

```hcl
variable "optional_value" {
  type    = string
  default = null
}
```

Useful for optional configs.

---

## Any (Default Behavior)

If no type is specified:

```hcl
variable "dynamic_var" {}
```

Terraform automatically infers the type.
Not recommended for production — always define types explicitly.

---

# Quick Comparison

| Type   | Ordered | Duplicates | Multiple Data Types | Access Method |
| ------ | ------- | ---------- | ------------------- | ------------- |
| string | N/A     | N/A        | ❌                  | direct        |
| number | N/A     | N/A        | ❌                  | direct        |
| bool   | N/A     | N/A        | ❌                  | direct        |
| list   | ✅      | ✅         | ❌                  | index `[0]`   |
| set    | ❌      | ❌         | ❌                  | convert first |
| map    | ❌      | keys only  | ❌                  | key lookup    |
| tuple  | ✅      | ✅         | ✅                  | index         |
| object | ❌      | keys only  | ✅                  | key lookup    |

---

# Key Takeaways

- Always define `type` for safety.
- Use:

  - **list** when order matters
  - **set** when uniqueness matters
  - **map** for simple key-value
  - **object** for structured configs
  - **tuple** when order + mixed types matter

- Lists use index.
- Maps/Objects use keys.
- Sets require conversion for indexing.

---

# Final Thought

Type constraints make Terraform:

- Predictable
- Safer
- Easier to maintain

If you don’t practice this hands-on, you’ll forget it.
Use them in real configs and break things on purpose — that’s how it sticks.

```

```

````markdown
# Production-Grade EKS Cluster with Terraform Custom Modules

This project provisions a **production-ready AWS EKS (Elastic Kubernetes Service) cluster** using **Terraform custom modules**. It demonstrates how to structure scalable infrastructure code by encapsulating complexity into reusable modules.

---

## 🚀 Overview

This implementation focuses on:

- Building a complete AWS infrastructure using Terraform
- Designing and using **custom Terraform modules**
- Provisioning:
  - VPC with networking components
  - IAM roles and policies
  - EKS cluster
  - Secrets management
- Establishing clean **module communication via variables and outputs**
- Following patterns used in **real-world production environments**

---

## 🧱 Architecture

The infrastructure includes:

- **VPC**

  - Public & private subnets
  - Internet Gateway
  - NAT Gateway
  - Route tables

- **IAM**

  - Roles for EKS control plane
  - Node group roles
  - Policy attachments

- **EKS**

  - Managed Kubernetes cluster
  - Node groups

- **Secrets Manager**
  - Secure storage for credentials (DB, API keys, etc.)

---

## 📁 Project Structure

```bash
.
├── code/                     # Root module
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── data.tf
│   └── modules/              # Custom modules
│       ├── vpc/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── iam/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── eks/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── secrets-manager/
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
```
````

---

## 🧠 Key Concepts

### 1. Root Module

The `code/` directory acts as the **root module** — the entry point for Terraform execution.

It is responsible for:

- Defining providers
- Declaring variables
- Sourcing custom modules
- Orchestrating dependencies between modules

---

### 2. Custom Modules

Each subdirectory inside `modules/` represents a **custom module**.

A module encapsulates:

- Resources
- Variables
- Outputs

This allows:

- Reusability
- Abstraction of complexity
- Better organization of infrastructure code

---

### 3. Module Usage

Modules are referenced in the root module using:

```hcl
module "vpc" {
  source = "./modules/vpc"

  cidr_block = var.vpc_cidr
  azs        = data.aws_availability_zones.available.names
}
```

---

### 4. Variable Flow

- Root module defines values
- Values are passed into modules via input variables
- Modules expose outputs
- Outputs are consumed by other modules via the root module

---

### 5. Module Communication Pattern

Modules **do not directly communicate** with each other.

Instead:

```
Module A → Output → Root Module → Input → Module B
```

Example:

```hcl
module "eks" {
  source = "./modules/eks"

  vpc_id = module.vpc.vpc_id
}
```

---

### 6. Data Sources

Dynamic values such as availability zones are fetched using Terraform data sources:

```hcl
data "aws_availability_zones" "available" {}
```

---

### 7. Custom Module Benefits

- Reusable infrastructure components
- Version control via Git
- Encapsulation of logic
- Reduced duplication
- Full control (unlike public modules)

---

## ⚙️ How It Works

1. Root module initializes Terraform
2. Modules are sourced via relative paths
3. Variables are passed into modules
4. Resources are created inside modules
5. Outputs are returned to root module
6. Dependencies are resolved implicitly

---

## 🛠️ Setup & Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Preview Changes

```bash
terraform plan
```

### 3. Apply Infrastructure

```bash
terraform apply
```

---

## 🔐 Secrets Management

Sensitive data such as:

- Database credentials
- API keys

Are stored securely using **AWS Secrets Manager**.

---

## 🧪 Recommended Learning Path

To fully understand this setup:

1. Start with a simple module:

   - Create a VPC module with:

     - VPC
     - Subnets
     - Internet Gateway

2. Practice:

   - Passing variables from root → module
   - Returning outputs from module → root

3. Expand:

   - Add IAM
   - Add EKS
   - Add Secrets Manager

---

## 📌 Notes

- This project follows **production-grade patterns**
- Modules are designed to be reusable and extensible
- You can easily plug this into CI/CD pipelines
- Supports versioning if modules are published to Git

---

## 📈 Future Improvements

- Remote backend (S3 + DynamoDB)
- CI/CD pipeline integration
- Helm deployments on EKS
- Monitoring (Prometheus, Grafana)
- Autoscaling configurations

---

## 🤝 Contributing

Feel free to fork and extend this project:

- Add more modules
- Improve abstraction
- Introduce testing (e.g., Terratest)

---

## 🧾 License

MIT License

---

## ✨ Final Thoughts

This project is not just about provisioning infrastructure — it’s about **thinking in systems**, designing for **scale**, and writing Terraform the way it’s used in **real engineering teams**.

```

```

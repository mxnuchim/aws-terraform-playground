# 🌍 Portfolio Deployment on AWS with Terraform

### S3 + CloudFront + Secure Caching Architecture

<img width="1167" height="440" alt="Screenshot 2026-02-25 at 21 24 08" src="https://github.com/user-attachments/assets/5a50b876-6913-4d0a-a385-b5daefd1cefd" />

This project provisions and deploys my personal portfolio to AWS using Terraform, implementing a secure, globally distributed, and cache-optimized architecture.

The objective was to treat a personal website as production infrastructure — fully reproducible, secure by default, and designed with performance in mind.

---

## 🏗 Architecture Overview

**Core Stack**

- **Amazon S3** – Private static site origin
- **Amazon CloudFront** – Global CDN distribution
- **Terraform** – Infrastructure as Code
- **IAM** – Least-privilege access control
- **Origin Access Control (OAC)** – Secure S3 access from CloudFront

### Request Flow

1. User makes request to CloudFront.
2. CloudFront checks edge cache.
3. If cache miss → request forwarded to S3 origin.
4. Response cached according to behavior rules.
5. Subsequent global requests served from nearest edge location.

---

## 🔐 Security Design

Security was implemented intentionally:

- S3 bucket is **not publicly accessible**
- Access restricted to CloudFront via Origin Access Control
- IAM policies follow least privilege principle
- HTTPS enforced at distribution level
- Direct origin access blocked

Even though this is a portfolio project, the architecture follows production-grade security standards.

---

## ⚡ Caching Strategy

Multiple cache behaviors were configured to demonstrate fine-grained control:

| Path Pattern     | Caching Strategy | Purpose                      |
| ---------------- | ---------------- | ---------------------------- |
| `/assets/*`      | Long TTL         | Static assets rarely change  |
| `/*.html`        | Short TTL        | Controlled content freshness |
| Default Behavior | Balanced TTL     | Optimized general caching    |

This ensures:

- Faster global delivery
- Reduced origin load
- Cost efficiency
- Controlled invalidation strategy

---

## 📦 Infrastructure as Code

All infrastructure is provisioned using Terraform.

### Structure

```

.
├── provider.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
└── locals.tf

```

Design principles applied:

- Idempotent provisioning
- Parameterized configuration
- Minimal hardcoding
- Environment flexibility
- Clear separation of concerns

---

## 🚀 Deployment Workflow

### 1️⃣ Initialize Terraform

```bash
terraform init
```

### 2️⃣ Review Execution Plan

```bash
terraform plan
```

### 3️⃣ Apply Infrastructure

```bash
terraform apply
```

### 4️⃣ Upload Portfolio Build

Upload static build files to the provisioned S3 bucket.

### 5️⃣ Access via CloudFront

Access the deployed portfolio through the generated CloudFront domain.

---

## 🎯 Project Goals

This project focused on:

- Understanding CDN behavior deeply
- Designing caching intentionally
- Practicing secure infrastructure design
- Applying Infrastructure as Code discipline
- Moving from “deploying apps” to “designing systems”

---

## 📈 Future Improvements

- Custom domain with ACM certificate
- CI/CD pipeline integration
- Automated cache invalidation
- CloudWatch monitoring and alerting
- Multi-environment setup (dev/staging/prod)

---

## 🧠 Key Takeaways

- CDN configuration is a performance multiplier when done correctly.
- Infrastructure should be reproducible, not manual.
- Security should be deliberate from the start.
- Even small systems benefit from architectural thinking.

---

## 📌 Outcome

A globally distributed, secure, and cache-optimized portfolio deployment powered entirely by Terraform and AWS.

This project represents a shift toward infrastructure ownership and production-level cloud design.

```

```

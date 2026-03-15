# Terraform AWS Lambda Image Processor

A serverless image processing pipeline built with **AWS Lambda, S3, and Terraform**.

This project automatically processes images uploaded to an S3 bucket and generates multiple optimized variants using a Lambda function. Everything — from infrastructure to permissions — is provisioned using **Infrastructure as Code (Terraform)**.

I built this project as part of my **build-in-public cloud engineering journey**, focusing on practical AWS automation patterns and serverless architecture.

---

# 🚀 Project Overview

This project implements an **event-driven serverless pipeline**:

1. A user uploads an image to an **S3 upload bucket**
2. The upload triggers an **S3 event**
3. The event invokes an **AWS Lambda function**
4. The Lambda function processes the image using **Pillow**
5. Five optimized image variants are generated
6. The processed images are saved in a **destination S3 bucket**
7. Execution logs are written to **CloudWatch Logs**

All AWS resources are provisioned and managed using **Terraform**.

---

# 🏗 Architecture

```

```

         Upload Image
              │
              ▼
    ┌──────────────────┐
    │  S3 Upload Bucket │
    └─────────┬────────┘
              │
    S3:ObjectCreated Event
              │
              ▼
    ┌──────────────────┐
    │  AWS Lambda       │
    │  Image Processor  │
    │  (Python + Pillow)│
    └─────────┬────────┘
              │
    Generates 5 Variants
              │
              ▼
    ┌──────────────────┐
    │ S3 Process Bucket │
    │ Optimized Images  │
    └──────────────────┘
              │
              ▼
        CloudWatch Logs

```

```

---

# 📦 Infrastructure Components

This stack provisions the following AWS resources:

### Storage

- **Upload S3 Bucket**

  - Stores original uploaded images
  - Triggers Lambda execution
  - Versioning enabled
  - Private bucket with blocked public access
  - Server-side encryption enabled

- **Processed S3 Bucket**
  - Stores optimized image variants
  - Versioning enabled
  - Encrypted and private

---

### Compute

**AWS Lambda Function**

- Runtime: Python
- Processes uploaded images
- Generates multiple variants
- Uses the Pillow image processing library
- Executes only when triggered by S3 events

---

### Lambda Layer

To keep the Lambda package lightweight, **Pillow** is included as a **Lambda Layer**.

The layer is built during deployment using Docker to ensure compatibility with the AWS Lambda Linux runtime.

---

### IAM Security

Lambda uses an **IAM Role with least privilege permissions**:

Allowed actions include:

**Source bucket permissions**

```

s3:GetObject
s3:GetObjectVersion

```

**Destination bucket permissions**

```

s3:PutObject
s3:PutObjectAcl

```

**Logging**

```

logs:CreateLogGroup
logs:CreateLogStream
logs:PutLogEvents

```

No unnecessary permissions are granted.

---

### Monitoring

**Amazon CloudWatch Logs**

Each Lambda invocation creates a log stream containing:

- Execution duration
- Memory usage
- Processed image metadata
- Errors (if any)

---

# 🖼 Generated Image Variants

When an image is uploaded, the Lambda function automatically generates:

| Variant          | Description                    |
| ---------------- | ------------------------------ |
| Compressed JPEG  | 85% quality optimized version  |
| Low Quality JPEG | 60% quality small file size    |
| WebP             | Modern high compression format |
| PNG              | Lossless image version         |
| Thumbnail        | 200x200 preview image          |

Example output:

```

original-photo.jpg

├── photo_compressed_abc123.jpg
├── photo_low_abc123.jpg
├── photo_webp_abc123.webp
├── photo_png_abc123.png
└── photo_thumbnail_abc123.jpg

```

---

# ⚙️ Terraform Resources

The infrastructure is managed with Terraform and provisions roughly **16 AWS resources**, including:

- S3 Buckets
- S3 Bucket Policies
- Bucket Versioning
- Server-side Encryption
- IAM Roles
- IAM Policies
- Lambda Function
- Lambda Layer
- Lambda Permissions
- CloudWatch Log Group
- S3 Event Notifications
- Random ID generator (for unique bucket names)

---

# 🧠 Key Concepts Demonstrated

This project touches several important cloud engineering concepts:

- **Infrastructure as Code (Terraform)**
- **Event-driven architecture**
- **Serverless compute with AWS Lambda**
- **S3 event triggers**
- **IAM least privilege design**
- **Lambda layers for dependency management**
- **CloudWatch monitoring**
- **Docker-based dependency packaging**
- **Handling environment compatibility ("works on my machine" problem)**

---

# 📁 Repository Structure

```

terraform-lambda-image-processor
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│
├── lambda/
│   └── lambda_function.py
│
├── scripts/
│   ├── deploy.sh
│   ├── destroy.sh
│   └── build_layer.sh
│
├── layer/
│   └── pillow_layer.zip
│
└── README.md

```

---

# 🚀 Deployment

### Prerequisites

- AWS CLI configured
- Terraform installed
- Docker installed
- Python 3.x
- An AWS account with appropriate permissions

---

### Step 1 — Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

cd YOUR_REPO_NAME
```

---

### Step 2 — Configure Terraform Variables

Rename the example variables file:

```
terraform.tfvars.example → terraform.tfvars
```

Example configuration:

```
aws_region = "us-east-1"
environment = "dev"
project_name = "image-processor"
lambda_timeout = 60
lambda_memory_size = 1024
```

---

### Step 3 — Deploy Infrastructure

Run the deployment script:

```bash
./scripts/deploy.sh
```

The script will:

1. Build the Lambda Pillow layer
2. Package dependencies
3. Run Terraform initialization
4. Execute `terraform plan`
5. Apply the infrastructure

Once complete, Terraform will output the generated bucket names.

---

# 📸 Usage

Upload an image using AWS CLI:

```bash
aws s3 cp photo.jpg s3://YOUR-UPLOAD-BUCKET/
```

The Lambda function will trigger automatically.

After a few seconds, processed images will appear in the destination bucket.

---

### List Processed Images

```bash
aws s3 ls s3://YOUR-PROCESSED-BUCKET/
```

---

### Download a Processed Image

```bash
aws s3 cp s3://YOUR-PROCESSED-BUCKET/photo_webp_abc123.webp .
```

---

# 📊 Observability

View Lambda logs:

```bash
aws logs tail /aws/lambda/YOUR-LAMBDA-FUNCTION --follow
```

Inspect CloudWatch metrics:

- Invocations
- Duration
- Memory usage
- Errors

---

# 🧹 Cleanup

Destroy all infrastructure:

```bash
./scripts/destroy.sh
```

Make sure the S3 buckets are empty before running destroy.

---

# 💰 Cost Considerations

Typical AWS pricing for this setup:

| Service         | Cost                       |
| --------------- | -------------------------- |
| S3 Storage      | ~$0.023 / GB               |
| Lambda Requests | First 1M free              |
| Lambda Compute  | First 400k GB-seconds free |
| S3 Requests     | ~$0.0004 per 1k requests   |

Processing **1,000 images per month** would typically cost **well under $2/month**.

---

# 🔐 Security Practices

Security considerations implemented in this project:

- Private S3 buckets
- Public access blocked
- Server-side encryption enabled
- Bucket versioning enabled
- IAM least privilege permissions
- No hardcoded credentials
- Terraform-managed infrastructure

---

# ⚡ Performance Notes

Typical Lambda performance observed during testing:

| Metric                   | Value        |
| ------------------------ | ------------ |
| Cold Start               | ~400–500 ms  |
| Execution Time           | ~2–3 seconds |
| Memory Used              | ~110 MB      |
| Lambda Memory Allocation | 1024 MB      |

---

# 🛠 Possible Extensions

Ideas to extend this project:

- Add **API Gateway** for image uploads
- Add **S3 lifecycle policies**
- Integrate **CloudFront CDN**
- Add **Step Functions** for complex pipelines
- Implement **image moderation using Rekognition**
- Add **CI/CD deployment pipeline**

---

# 👨‍💻 Why I Built This

I'm currently exploring deeper patterns in **cloud infrastructure and serverless architecture**.

This project was a good opportunity to combine:

- Terraform automation
- AWS Lambda
- Event-driven design
- Image processing workloads

While following a learning series, I rebuilt the project myself, debugged environment issues, and automated the deployment process to better reflect how I'd implement it in a real workflow.

More experiments like this will continue as I build and document cloud projects publicly.

---

# 📜 License

MIT License

---

# 🤝 Connect

If you're also exploring cloud infrastructure, DevOps, or Terraform workflows, feel free to connect or share feedback.

Always happy to exchange ideas with other builders in the cloud space.

```

```

# Terraform Provisioners — Practical Deep Dive (AWS EC2)

This project demonstrates how to use **Terraform provisioners** to bridge the gap between infrastructure provisioning and instance-level configuration.

Rather than treating provisioners as a default tool, this project explores them the way they are used in real-world systems: **intentionally, sparingly, and with clear trade-offs**.

---

## 🚀 What This Project Covers

- Provisioning an EC2 instance using Terraform
- Secure SSH access via key pairs
- Using **local-exec**, **remote-exec**, and **file** provisioners
- Understanding Terraform’s execution model (and its limitations)
- Forcing resource recreation to re-trigger provisioners

---

## 🧠 Mental Model

Terraform is **declarative** — it describes _what infrastructure should exist_, not _how to configure it step-by-step_.

Provisioners break that model slightly by introducing **imperative execution**.

Think of them as:

> “Escape hatches when infrastructure alone isn’t enough.”

---

## 🔧 Provisioners Explained

### 1. `local-exec` — Runs on Your Machine

Executes commands **on the machine running Terraform**.

**Use cases:**

- Logging or debugging
- Triggering external systems (webhooks, CI steps)
- Generating local artifacts

```hcl
provisioner "local-exec" {
  command = "echo Instance ${self.id} created with IP ${self.public_ip}"
}
```

📌 Key insight:

- No SSH required
- Runs **after resource creation**, but **locally**

---

### 2. `remote-exec` — Runs on the Instance

Executes commands **on the provisioned resource via SSH**.

**Use cases:**

- Bootstrapping servers
- Installing packages
- Running initialization scripts

```hcl
provisioner "remote-exec" {
  inline = [
    "sudo apt-get update -y",
    "echo 'hello from remote exec' | sudo tee /tmp/remote.txt"
  ]
}
```

📌 Key insight:

- Requires a **connection block**
- Runs **once during creation**
- Not suitable for long-term configuration management

---

### 3. `file` — Copies Files to the Instance

Transfers files from local machine → remote instance.

```hcl
provisioner "file" {
  source      = "${path.module}/scripts/welcome.sh"
  destination = "/tmp/welcome.sh"
}
```

📌 Often paired with `remote-exec`:

```hcl
provisioner "remote-exec" {
  inline = [
    "chmod +x /tmp/welcome.sh",
    "/tmp/welcome.sh"
  ]
}
```

---

## 🔐 Connection Configuration

Remote provisioners require SSH access:

```hcl
connection {
  type        = "ssh"
  user        = var.ssh_user
  private_key = file(var.private_key_path)
  host        = self.public_ip
}
```

---

## 🏗️ Infrastructure Overview

This project provisions:

- **EC2 Instance** (Ubuntu AMI via data source)
- **Security Group**

  - Ingress: SSH (port 22)
  - Egress: Open outbound access

- **SSH Key Pair** (provided externally)

---

## ⚙️ Variables

| Variable           | Description                           |
| ------------------ | ------------------------------------- |
| `instance_type`    | EC2 instance size (default: t3.micro) |
| `key_name`         | Existing AWS key pair name            |
| `private_key_path` | Path to `.pem` file                   |
| `ssh_user`         | Default: `ubuntu`                     |

---

## ▶️ How to Run

### 1. Initialize

```bash
terraform init
```

### 2. Apply

```bash
terraform apply \
  -var="key_name=your-key" \
  -var="private_key_path=/path/to/key.pem"
```

---

## 🔁 Re-running Provisioners (Important)

Provisioners **DO NOT run on updates**.

To force re-execution:

```bash
terraform taint aws_instance.demo
terraform apply
```

Or:

```bash
terraform apply -replace=aws_instance.demo
```

---

## 🔍 What Happens During Execution

### `local-exec`

- Runs locally
- Logs instance metadata

### `remote-exec`

- Connects via SSH
- Executes commands on the instance
- Creates a file in `/tmp`

### `file`

- Copies `welcome.sh` → `/tmp/welcome.sh`

---

## 🧪 Verifying Results

SSH into your instance:

```bash
ssh -i your-key.pem ubuntu@<public-ip>
```

Check files:

```bash
cd /tmp
ls
cat remote.txt
cat welcome.sh
```

---

## ⚠️ Real-World Guidance

Provisioners are powerful — but **not the default choice**.

### Use them when:

- You need quick bootstrapping
- You're integrating with external systems
- You're prototyping or learning

### Avoid them when:

- There’s a native Terraform resource
- You need repeatable, idempotent config
- You’re building production-grade systems

---

## 🆚 Better Alternatives

| Tool                     | When to Use                    |
| ------------------------ | ------------------------------ |
| `user_data` / cloud-init | Instance bootstrap (preferred) |
| Packer                   | Pre-baked images               |
| Ansible                  | Configuration management       |
| AWS SSM                  | Remote commands without SSH    |

---

## 🧯 Common Pitfalls

- Provisioners **run only once**
- SSH failures = broken applies
- Not idempotent by default
- Hard to debug at scale

---

## 🧹 Cleanup

Always destroy resources to avoid charges:

```bash
terraform destroy
```

---

## 🧩 Key Takeaway

Provisioners are not “bad” — they’re just **misused**.

Used correctly, they:

- Fill critical gaps
- Enable fast iteration
- Bridge infra → configuration

Used incorrectly, they:

- Create brittle systems
- Break Terraform’s declarative model

```

```

# AWS Cross-Region VPC Peering — Infrastructure as Code

Terraform implementation of a production-pattern cross-region VPC peering architecture on AWS. Two isolated networks across geographically separate regions, connected over AWS's private backbone — no public internet traversal between workloads.

---

## Architecture

```
┌─────────────────────────────────────┐          ┌─────────────────────────────────────┐
│         us-east-1 (Primary)         │          │        us-west-2 (Secondary)        │
│         CIDR: 10.0.0.0/16           │          │        CIDR: 10.1.0.0/16            │
│                                     │          │                                     │
│  ┌─────────────────────────────┐    │          │    ┌─────────────────────────────┐  │
│  │  Subnet: 10.0.1.0/24        │    │          │    │  Subnet: 10.1.1.0/24        │  │
│  │  ┌───────────────────────┐  │    │          │    │  ┌───────────────────────┐  │  │
│  │  │  EC2 (Apache)         │  │    │          │    │  │  EC2 (Apache)         │  │  │
│  │  │  Private: 10.0.1.x    │  │    │          │    │  │  Private: 10.1.1.x    │  │  │
│  │  └───────────────────────┘  │    │          │    └──└───────────────────────┘  │  │
│  └─────────────────────────────┘    │          │    └─────────────────────────────┘  │
│  Internet Gateway                   │          │    Internet Gateway                  │
└──────────────┬──────────────────────┘          └─────────────────┬───────────────────┘
               │                                                    │
               └──────────────── VPC Peering ───────────────────────┘
                                 (AWS Private Backbone)
```

**18 resources provisioned across 2 AWS regions via a single `terraform apply`.**

---

## What's Deployed

| Layer      | Resource                          | Count |
| ---------- | --------------------------------- | ----- |
| Networking | VPC                               | 2     |
| Networking | Public Subnet                     | 2     |
| Networking | Internet Gateway                  | 2     |
| Networking | Route Table + Association         | 2 + 2 |
| Peering    | VPC Peering Connection + Accepter | 1 + 1 |
| Peering    | Cross-VPC Routes                  | 2     |
| Security   | Security Group                    | 2     |
| Compute    | EC2 Instance (Ubuntu 24.04)       | 2     |

---

## Key Design Decisions

**Non-overlapping CIDRs** — `10.0.0.0/16` and `10.1.0.0/16` are intentionally separated. VPC peering requires unambiguous IP routing; overlapping ranges make the peering connection unusable.

**Explicit peering handshake** — The connection is modeled as a requester (`auto_accept = false`) and accepter (`auto_accept = true`). This mirrors real-world cross-account peering flows where both parties must consent.

**Bidirectional routes** — A peering connection alone doesn't route traffic. Explicit `aws_route` resources are added to each VPC's route table pointing `10.1.0.0/16 → pcx-xxxxx` and `10.0.0.0/16 → pcx-xxxxx` respectively.

**Multi-region provider aliases** — A single Terraform configuration manages both regions using provider aliasing (`aws.primary`, `aws.secondary`) rather than separate state files. Each resource declares its target region explicitly.

**Dynamic AMI resolution** — AMI IDs are region-specific and change with Ubuntu patch releases. Data sources query for the latest `ubuntu-noble-24.04` image at plan time rather than hardcoding IDs that drift.

**`depends_on` for peering** — EC2 instances declare an explicit dependency on `aws_vpc_peering_connection_accepter`. This ensures instances boot into a fully connected network, not a partially wired one.

---

## Prerequisites

- AWS CLI configured with credentials that have VPC, EC2, and peering permissions
- Terraform >= 1.0
- SSH key pairs created in both target regions

### Create SSH Key Pairs

```bash
# us-east-1
aws ec2 create-key-pair \
  --key-name vpc-peering-demo \
  --region us-east-1 \
  --query 'KeyMaterial' \
  --output text > vpc-peering-demo.pem

# us-west-2
aws ec2 create-key-pair \
  --key-name vpc-peering-demo \
  --region us-west-2 \
  --query 'KeyMaterial' \
  --output text > vpc-peering-demo.pem

# Lock down key permissions (required for SSH)
chmod 400 *.pem
```

> **Note:** The key _name_ must match in both regions. The `.pem` filename is local only.

---

## Usage

```bash
# 1. Initialise providers and modules
terraform init

# 2. Review the execution plan (18 resources)
terraform plan

# 3. Provision
terraform apply
```

### `terraform.tfvars` example

```hcl
environment        = "demo"
company            = "your-company"
primary_region     = "us-east-1"
secondary_region   = "us-west-2"
primary_vpc_cidr   = "10.0.0.0/16"
secondary_vpc_cidr = "10.1.0.0/16"
instance_type      = "t3.micro"
primary_key_name   = "vpc-peering-demo"
secondary_key_name = "vpc-peering-demo"
```

---

## Verifying Connectivity

Once provisioned, grab outputs and test the private path:

```bash
terraform output
```

**From primary → secondary (private IP):**

```bash
ssh -i vpc-peering-demo.pem ubuntu@<PRIMARY_PUBLIC_IP>
ping <SECONDARY_PRIVATE_IP>
curl http://<SECONDARY_PRIVATE_IP>
```

**From secondary → primary (private IP):**

```bash
ssh -i vpc-peering-demo.pem ubuntu@<SECONDARY_PUBLIC_IP>
ping <PRIMARY_PRIVATE_IP>
curl http://<PRIMARY_PRIVATE_IP>
```

A successful `curl` returns the Apache page served by the remote instance — confirming traffic is routing over the peering connection on private IPs, not the public internet.

---

## File Structure

```
.
├── main.tf          # Core resources: VPCs, subnets, IGWs, route tables, peering, EC2
├── data.tf          # Data sources: AZs, latest Ubuntu AMI per region
├── variables.tf     # Input variable declarations
├── locals.tf        # Common tags, user_data bootstrap scripts
├── outputs.tf       # Public/private IPs for both instances
└── terraform.tfvars # Variable values (not committed)
```

---

## Troubleshooting

**Ping/curl not working between instances**

Check in order:

1. Security groups — inbound ICMP and TCP rules must reference the _peered VPC's CIDR_, not `0.0.0.0/0`
2. Route tables — both VPCs need a route pointing the remote CIDR at the peering connection ID
3. Peering connection status — must be `active` in both regions (check AWS Console → VPC → Peering Connections)
4. CIDR overlap — if another VPC in your account uses `10.0.0.0/16` or `10.1.0.0/16`, it can cause routing ambiguity

**AMI forcing instance replacement on re-apply**

Expected behaviour. The `most_recent = true` filter returns the latest Ubuntu 24.04 patch at plan time. If Canonical has published a new image since the last apply, Terraform will detect an AMI ID drift and plan a replacement. Pin to a specific AMI ID if instance stability across applies is required.

**Key pair not found error**

The key pair _name_ (set in `terraform.tfvars`) must exactly match what was registered in that region via `aws ec2 create-key-pair`. The `.pem` filename is irrelevant to AWS.

---

## Important Constraints

- **VPC peering is not transitive.** If VPC A peers with B, and B peers with C, A and C cannot communicate. Each pair requires its own peering connection.
- **No edge-to-edge routing.** Traffic cannot flow through a VPC peering connection to a VPN, Direct Connect, or internet gateway on the other side.
- **Max 125 peering connections per VPC** (AWS default limit, raiseable via support).
- For complex multi-VPC topologies, AWS Transit Gateway is the appropriate solution.

---

## Cleanup

```bash
terraform destroy
```

Removes all 18 resources. VPC peering data transfer and EC2 uptime are billed — destroy when not in active use.

---

## Stack

- **IaC:** Terraform
- **Cloud:** AWS (EC2, VPC, VPC Peering)
- **OS:** Ubuntu 24.04 LTS
- **Web server:** Apache2 (via `user_data` bootstrap)

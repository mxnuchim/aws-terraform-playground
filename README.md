# Terraform + AWS Playground

Personal infrastructure lab.

This repository contains my structured notes and hands-on experiments while revisiting Terraform fundamentals and AWS provisioning workflows.

It’s written from the perspective of a DevOps engineer / software engineer who already uses these tools in production — but is intentionally re-walking the foundations with discipline.

The tone is practical, operational, and occasionally reflective.

---

## Why This Repo Exists

Even experienced engineers benefit from:

- Revalidating fundamentals
- Tightening version discipline
- Revisiting authentication flows
- Practicing clean infrastructure lifecycle management
- Documenting thought process for others

This repository serves three purposes:

1. Personal reinforcement of Terraform + AWS concepts
2. Reference material for junior engineers
3. Potential structured teaching material for a future DevOps class

---

## What This Repository Covers

- Infrastructure as Code mindset
- Terraform workflow
- Terraform Core vs Provider separation
- Provider lifecycle awareness
- Credential resolution flow
- CLI vs environment variables vs IAM roles
- Remote state (S3 + DynamoDB)
- State locking
- Modular architecture
- Environment separation
- CI/CD integration
- Production-grade patterns

---

## Philosophy Behind These Notes

This repo is not written like beginner tutorials.

It assumes:

- You’ve used AWS before
- You’ve deployed infrastructure before
- You care about reproducibility and reliability

The emphasis is on:

- Version discipline
- Upgrade safety
- Authentication hygiene
- Cost awareness
- Cleanup discipline
- Operational thinking

---

## How to Use This Repo (If You're a Junior Engineer)

If you're newer to Terraform:

1. Read the notes slowly.
2. Recreate the examples yourself.
3. Run the full lifecycle:
   - `terraform init`
   - `terraform plan`
   - `terraform apply`
   - `terraform destroy`
4. Break things intentionally.
5. Observe error messages.
6. Read provider documentation.

Infrastructure confidence comes from controlled mistakes.

---

## Repository Structure (Example)

Each directory may contain:

- Notes
- Example Terraform configs
- Experiments
- Observations

---

## Standards Followed Here

- Providers are version-constrained
- Lock file is committed
- No open-ended `>=` in production examples
- Resources destroyed after practice
- Authentication methods documented explicitly
- No reliance on “latest”

---

## If I Ever Teach This

This repository is already structured like modular lecture notes:

- Fundamentals first
- Then provider internals
- Then authentication and resource provisioning
- Then state management
- Then production patterns

Each day builds on the previous one.

The goal would not be to teach syntax —
but to teach infrastructure thinking.

---

## Final Notes

Terraform is not just a tool.
It is a reliability discipline.

AWS is not just a console.
It is an API surface.

Infrastructure is not just provisioning.
It is lifecycle management.

This repo documents that mindset.

---

# Security policy

## Reporting a vulnerability

Do **not** open a public issue for security vulnerabilities. Instead, email the
maintainer privately with details and reproduction steps. Please allow a
reasonable response time before any public disclosure.

## Secrets and credentials

This repository is designed to **never** contain real credentials:

- `.env`, `*.tfstate`, private keys, and `.pem` files are git-ignored.
- AWS credentials are never long-lived: CI/CD uses **GitHub OIDC** to assume a
  short-lived IAM role.
- Database and Redis credentials are sourced from **AWS Secrets Manager** /
  SSM Parameter Store at runtime, not embedded in code, user-data or
  Terraform source.
- Use `.env.example` only for fake example values.

If you accidentally commit a secret:

1. Rotate it immediately in the originating system.
2. Remove it from history (`git filter-repo` or BFG) and force-push.
3. Notify anyone with a clone.

## Scanning in CI

The GitHub Actions workflows run:

- Secret scanning (gitleaks)
- Dependency vulnerability scanning (pip-audit)
- Container image scanning (Trivy)
- Terraform security scanning (tfsec / Trivy)

## Least privilege

- IAM roles use least-privilege policies scoped to project resources.
- Security groups allow only required ports from required sources
  (e.g. DB only from the app SG, never 0.0.0.0/0).
- S3, RDS and ElastiCache use encryption at rest; Redis uses TLS in transit.
- EC2 instances enforce IMDSv2 and encrypted EBS volumes.

# SecureShop Lite: Threat Model (v1, Day 1)

## What we are building
3-tier app on AWS: web tier (Nginx + React) and app tier (FastAPI) on k3s on one EC2 lab box in a public subnet; data tier on RDS PostgreSQL in private subnets. CI on GitHub Actions, images on GHCR, delivery via ArgoCD.

## Crown jewels (what an attacker wants)
- AWS account access (lab-admin session, instance role)
- Database contents and credentials
- GitHub account and commit signing key (can push malicious code)
- Container image signing identity (can make malicious images look trusted)

## Trust boundaries
1. Internet -> Traefik ingress (port 443/80)
2. Web tier -> App tier (inside cluster)
3. App tier -> RDS (VPC, port 5432)
4. Developer PC / lab box -> GitHub
5. GitHub Actions -> GHCR -> cluster (supply chain)
6. Pods -> EC2 instance metadata (IMDS) -> AWS APIs

## STRIDE analysis

| # | STRIDE | Where | Threat | Planned control | Day |
|---|---|---|---|---|---|
| S1 | Spoofing | Web tier | Fake site or MITM steals user logins | TLS via Let's Encrypt, HSTS header | 10 |
| S2 | Spoofing | AWS/GitHub | Stolen password, session, or SSH key lets an attacker impersonate me | MFA, short-lived credentials, SSH key protection, least-privilege IAM | 1, 19 |
| T1 | Tampering | CI/CD | Attacker pushes a malicious image to the registry | Cosign keyless signing + Kyverno verification | 8, 12 |
| T2 | Tampering | Terraform/Kubernetes | Attacker modifies infrastructure or Kubernetes manifests without detection | Signed commits, protected branches, CI review, Git diff/audit logs | 1, 8 |
| R1 | Repudiation | Git | Someone commits as me and I cannot prove otherwise | SSH-signed commits, Verified badge | 1 |
| R2 | Repudiation | AWS | Someone deletes or changes AWS resources and I cannot determine who did it | Enable CloudTrail, retain audit logs, record IAM principal and API activity | 3 |
| I1 | Info disclosure | Data tier | Database reachable from the internet | Private subnets, SG allows only lab box | 1, 3 |
| I2 | Info disclosure | Git/Terraform/Logs | Secrets leak through Git history, logs, Terraform state, or public repositories | Secret scanning, `.gitignore`, encrypted/remote state, redact sensitive logs | 1, 4, 8 |
| D1 | Denial of service | Web tier | Request flood takes the site down | Rate limiting, resource limits on pods | 10 |
| D2 | Denial of service | EC2/AWS | Lab box becomes unavailable or unexpected resource usage exhausts AWS credits | CloudWatch alarms, resource limits, budgets/alerts, backup/recovery plan | 3, 19 |
| E1 | Elevation of privilege | App tier | Compromised pod steals instance role via IMDS | IMDSv2, NetworkPolicy blocks IMDS, least-privilege role | 1, 10 |
| E2 | Elevation of privilege | Kubernetes | Container runs as root or attacker obtains excessive `kubectl` privileges | Non-root containers, Pod Security Admission, RBAC least privilege, restrict cluster-admin | 12 |

## Accepted risks (for the lab)
- Single EC2 node: no high availability.
- SSH open to my IP only until SSM replaces it (Day 19).
- Public repos: code is visible, so secrets must never be committed.

## Review
Revisit this file at the end of each week and mark which controls are done.

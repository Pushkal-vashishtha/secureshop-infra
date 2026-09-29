# Learning journal

## Day 1
- Worked: account hardened (MFA, lab-admin, budgets), Terraform built VPC + lab box with no NAT, k3s running with secrets encryption, all tools installed.
- Broke: CloudShell blocked by account verification; root keys found on PC (removed); apostrophe in SG description; file name typos.
- Threat model v1 committed (STRIDE, 3 tiers, 6 trust boundaries).

## Day 3
- Worked: Terraform on the lab box with short-lived creds; RDS Postgres 18.3 private (10.30.23.x), encrypted, TLS forced; app_user SELECT/INSERT only; password in Parameter Store.
- Proved: no internet route to 5432; sslmode=disable refused; box role reads app param but not the admin secret.
- Broke: user_data diff from a whitespace fix (fixed with trimspace); no db.t4g.micro capacity in 1a/1b (added a 1c subnet); rds.force_ssl apply_method drift; exported creds last ~15 min.

## Day 4
- Worked: Checkov + Trivy triage (fixed IAM auth, copy tags, rule descriptions; 12 documented suppressions); custom policy CKV2_SECURESHOP_1; scanners in pre-commit; iac-security pipeline; protect-main ruleset.
- Proved: pre-commit blocks SSH 0.0.0.0/0; a --no-verify commit still blocked at the PR by CI + ruleset.
- Broke: ebs_optimized=true would have REPLACED the lab box (caught in plan); .trivyignore not found from repo root; commits silently cancelled by hooks.

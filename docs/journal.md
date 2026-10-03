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

## Day 5
- Worked: FastAPI app tier (Chainguard, no shell, uid 65532) and Nginx web tier (uid 101), both read-only with all capabilities dropped; base images pinned by digest; schema in Git; full chain web -> api -> RDS working with password from Parameter Store via the instance role.
- Proved: read-only FS, no shell, 422 on bad input, 403 on DELETE, generic 503 to users with the real reason logged.
- Broke: RDS start ran on the box (AccessDenied) and with expired exported creds; ~/.aws/config overwritten with unrelated notes; aws login 400 from a stale browser session.

## Day 6
- Worked: Semgrep (+ custom CWE-89 rule, proven both ways), Trivy fs + Grype (0 vulns in deps), image scans, Syft SBOMs (CycloneDX + SPDX), SonarQube Cloud (gate passed, all A), Dependabot on both repos.
- Fixed: explicit USER; pip removed from runtime (api 6 HIGH -> 0, 183 -> 154 MB); hash-locked deps + --only-binary; Error-based promise rejection.
- Accepted: pcre2 CVE in nginx base, time-boxed to 2026-10-17 (not reachable, EPSS 0.2%).
- Learned: image scans see what SCA can't; scanners disagree; exceptions don't travel between tools; severity vs EPSS.

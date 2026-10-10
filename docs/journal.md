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

## Day 7
- Worked: app-ci pipeline (secrets, SAST, SCA, image scan gate, push to GHCR by commit SHA); images public on GHCR; protect-main ruleset on the app repo with 5 required checks.
- Fixed: SonarQube gate failed on unpinned actions -> pinned all actions to commit SHAs and scanner images to digests.
- Proved (red team): fake AWS key blocked by GitHub push protection; vulnerable PyYAML 5.3 (CVE-2020-14343) failed sca in 33s; build skipped; merge blocked.
- Reviewed and merged 4 Dependabot PRs on infra, one at a time, each passing scan.

## Day 8
- Worked: keyless Cosign signing of every image on main (Fulcio cert + Rekor log); signed CycloneDX SBOM attestation; SLSA build provenance in GitHub's attestation store; infra actions pinned to SHAs, Trivy to a digest.
- Proved: signature and SBOM verify; wrong repo, wrong branch and unsigned images all REJECTED.
- Broke: plan wanted to REPLACE the lab box (most_recent AMI) -> targeted SG apply + lifecycle ignore_changes [ami]; verify-attestation saw only provenance because two storage formats were mixed -> provenance kept in GitHub's store; empty DIGEST from verifying before the run finished; ! in double quotes triggered bash history expansion.

## Day 9
- Worked: gitops repo (hardened manifests, dev overlay pinned to signed digests, kubeconform clean); ArgoCD via pinned Helm chart, reachable only through an SSH tunnel; AppProject fence (one repo, two namespaces, Namespace-only cluster objects); auto-sync with prune + self-heal.
- Promote job: verifies Cosign signatures, then writes digests to gitops with a single-repo deploy key; CI never touches the cluster. Heading change went PR -> signed image -> gitops commit -> new pod.
- Proved: AppProject blocked an empty destination namespace; self-heal reverted nginx:latest to the signed digest in ~30s (repair, not prevention).
- Broke: wrong key files (verified by fingerprint), session key path after moving the .pem, private key fragment pasted in chat -> regenerated.

## Day 10
- Worked: Pod Security "restricted" enforced on web/app (root busybox pod rejected); default-deny NetworkPolicies with tier-to-tier allows; cert-manager + Let's Encrypt (staging -> trusted) on an sslip.io host, HTTPS only; ZAP baseline + API scans.
- Proved: web->api allowed; web->internet, web->IMDS, other-namespace->api blocked. ZAP: 0 FAIL in both scans (117 API checks incl. SQLi/XSS/Log4Shell); baseline 6 WARN -> 0 after CSP, Permissions-Policy, COOP/COEP/CORP.
- Triage: new libtiff CVE blocked the merge; base refresh fixed pcre2 (exception removed) but not libtiff -> unreachable (image-filter module not loaded), exception to 2026-10-24.
- Broke: sed missed the kustomization after kustomize reformatted it (11 vs 12 count caught it); wrong tunnel IP; placeholder copied into tfvars.

## Day 11
- Worked: Gatekeeper 3.23.1 (pinned chart); 4 constraints (ghcr-only, no :latest, digest required via own Rego, tier label) rolled out dryrun -> 0 violations -> deny; ExpansionTemplate so image rules apply at the Deployment; gator offline tests; gitops-validate CI (kubeconform + gator, tools pinned by version + sha256); gitops ruleset with deploy-key bypass for promote.
- Proved: Docker Hub image and :latest denied, digest allowed; requiredlabels enforced as a native ValidatingAdmissionPolicy; cert-manager solver excluded so renewals keep working.
- Broke: first red-team PR passed because kustomize's images transformer restored the digest -> verify the bad input reaches the check; ran PowerShell commands on the box; init -upgrade vs init.

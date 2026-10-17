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

## Day 12
- Worked: Kyverno (pinned chart, single replicas); ClusterPolicy verify-secureshop-signatures - images from ghcr.io/pushkal-vashishtha/* need a keyless Cosign signature from ci.yml@refs/heads/main (GitHub OIDC, Rekor); Audit (all PASS) -> Enforce. Read-only developer RBAC via built-in "view" on web/app, group-bound, kept in platform/.
- Proved: pre-Day-8 unsigned image from our own registry, by digest, passes Gatekeeper but is denied by Kyverno ("no signatures found"); signed image allowed. Developer: can view pods, cannot read secrets, exec, write, or see platform namespaces.
- Broke: k3s crash-looped 18 times right after boot (start-up race; stabilized on its own) - check the service before the pods; Gatekeeper webhook "failing open" noise; testpod lost on reconnect -> saved to ~/.bashrc.
- Noted: Kyverno image verification fails closed, Gatekeeper fails open. ClusterPolicy is deprecated in favour of ImageValidatingPolicy - migrate later.

## Day 13
- Scanned: kube-bench k3s-cis-1.9 -> 58 PASS / 6 FAIL / 52 WARN. Triage: web gets its own ServiceAccount, default SAs never mount tokens (fixed); argocd-redis SA queued for rebuild; cert perms (keys 600, certs public), etcd-cafile (SQLite, N/A), cluster-admin (system:masters + k3s helm installer), ArgoCD wildcard role (compensated by AppProject + Gatekeeper + Kyverno) accepted.
- Kubescape (NSA + MITRE): live 78.59%. Fixed CPU limits, fsGroup, fsGroupChangePolicy, explicit AppArmor RuntimeDefault. Documented exception for C-0211 seLinuxOptions (Ubuntu/AppArmor). CI gate: Kubescape JSON + jq blocks high/critical findings without a documented exception (proved both ways); --severity-threshold ignores alertOnly exceptions.
- INCIDENT: k3s crash-looped on boot (18, then 47 restarts). Root cause: Gatekeeper generated a native ValidatingAdmissionPolicy from requiredlabels' CEL block; it fails closed while its paramKind CRD isn't served, denying k3s's own CRD updates. Fix: removed only the K8sNativeValidation entry (Rego kept), via PR; verified with a reboot (NRestarts=0).
- FINDING: gitops and infra rulesets had "require status checks" ON with an EMPTY list -> failing PRs mergeable (PR #9 was). Fixed: validate / scan, verified via the rules API.
- Lessons: checks that pass on empty input aren't checks (wait script, kubeconform, jq //); test the control you mean (webhook order); read exit codes before pushing.

## Day 14
- Rebuilt the lab box from code: terraform -replace (only aws_instance.lab), new AMI. Recovery time 33 min to a fully secured, HTTPS-serving app.
- Captured before destroying: pinned + checksummed toolchain script, Helm releases/values in Git, platform bootstrap script, helper scripts.
- Came back by itself: k3s with secrets encryption + audit log (user_data); platform + policies (bootstrap.sh); app (ArgoCD). 9/9 control checks pass.
- Rotated: SSH key (new auth + signing key, old deleted), ArgoCD admin password. Host keys verified via the EC2 console log and GitHub's published fingerprint.
- Found by the rebuild: k3s version unpinned; pre-commit hooks not cloned; stale certificate request for the old hostname; argocd-redis pod-level token setting overrides the SA; nightly stop schedule AND its IAM role pinned to the deleted instance ID (fixed: tag-based permission, simulator-verified allowed/implicitDeny).

## Day 15
- Worked: External Secrets Operator (pinned chart, in platform bootstrap); ClusterSecretStore on Parameter Store via the instance role, usable only from namespace "app"; ExternalSecret -> Secret db-credentials; api reads DB_PASSWORD via secretKeyRef. Live read + write over HTTPS through every layer.
- FINDING: IMDS hop limit 2 let pods in every namespace without a NetworkPolicy fetch the box role's credentials (and so the DB password). Fixed: IMDS-guard NetworkPolicies (allow all egress except 169.254.169.254) in argocd, cert-manager, gatekeeper-system, kyverno, kube-system, and external-secrets except the ESO controller. Production answer: IRSA / EKS Pod Identity.
- Proved: guard blocks IMDS everywhere except the ESO controller (first test was a race: new pods briefly run before their policy applies). Pod spec holds only a secretKeyRef; developer can't read the Secret; plaintext absent from k3s datastore (encrypted at rest); no secret in ESO logs.
- FINDING: RDS auto-started 7 days after its last stop (2026-10-08) and ran unnoticed for 5 days.
- Lessons: "Ready=True" can be true for the wrong name (old certificate) - check what it's ready for; bash vs PowerShell windows.

## Day 15
- Worked: External Secrets Operator (pinned chart, in platform bootstrap); ClusterSecretStore on Parameter Store via the instance role, usable only from namespace "app"; ExternalSecret -> Secret db-credentials; api reads DB_PASSWORD via secretKeyRef. Live read + write over HTTPS through every layer.
- FINDING: IMDS hop limit 2 let pods in every namespace without a NetworkPolicy fetch the box role's credentials (and so the DB password). Fixed: IMDS-guard NetworkPolicies in all platform namespaces, with only the ESO controller allowed. Production answer: IRSA / EKS Pod Identity.
- Proved: guard blocks IMDS everywhere except the ESO controller (first test was a race: new pods briefly run before their policy applies). Pod spec holds only a secretKeyRef; developer can't read the Secret; plaintext absent from k3s datastore; no secret in ESO logs.
- Fixed: Nginx declares charset utf-8 (prevents charset sniffing). The "?" for the rupee sign was actually a literal "?" saved in app.js on Day 5 -> now the ASCII-safe escape \u20B9. Looked at the bytes before fixing the presentation.
- FINDING: RDS auto-started 7 days after its last stop (2026-10-08) and ran unnoticed for 5 days. No AWS waiter exists for "stopped": poll the status instead.
- Lessons: "Ready=True" can be true for the wrong name; "OutOfSync" for a few minutes after a commit is ArgoCD's polling interval; merge -> pipeline -> then sync.

## Day 16
- Worked: Falco 9.2.0 chart (modern eBPF driver, JSON output) in the platform bootstrap; container plugin maps events to pod/namespace (k3s containerd socket already in the chart defaults); falco namespace added to the IMDS guard.
- Detected: terminal shell in web (Notice, MITRE T1059); /etc/shadow read (Warning); drop-and-execute of a copied binary (Critical).
- GAP: stock shell rule needs a terminal; an RCE shell has none -> silent. Fixed with a custom rule "Shell in SecureShop workload" (Critical) for web/app; fires on `sh -c id`, quiet on a normal web restart.
- Correlated the alert with the k3s audit log (who ran the exec); shared admin identity limits attribution -> named identities on the backlog.
- Next: alerts only live in one pod's log -> Day 17 (notifications/metrics), Day 18 (ship logs off the box).

## Day 17
- Verified the nightly stop via CloudTrail: lab-scheduler called StopInstances on the new instance at 23:30 IST with no error (StateReason showed the box had been shut down from inside earlier).
- Worked: kube-prometheus-stack 92.3.1, trimmed for one node, in the platform bootstrap. Grafana admin password and the whole Alertmanager config (Gmail address + app password) generated by ESO from Parameter Store: no defaults, no personal data or secrets in Git.
- Monitors with exact label selectors: cert-manager, Kyverno, ESO (PodMonitor), Falco (metrics + rule counters). All 4 targets up.
- Security alerts: FalcoCriticalEvent, AdmissionDenied, CertificateExpiringSoon, CertificateNotReady, ExternalSecretNotSynced. First-appearance counters handled with "or ... unless ... offset". Falco + Kyverno proven by real events; cert/ESO logic proven on live data.
- Email delivery: notifications_total{email}=1, 0 failures; received.
- Found and fixed: monitoring namespace missing from the IMDS guard; a sed that matched nothing left bootstrap.sh unchanged; Grafana OOMKilled twice at 384Mi (used 364Mi) -> 640Mi. kubectl port-forward dies with its pod: run it in a restart loop.

## Day 18
- FINDING: k3s audit log was ~1.5 GB/day (16 x 100 MB files in 2 days), mostly controllers' watches/reads, leases, health checks, permission self-checks; no maxbackup. New audit policy (first match wins): drop probes, leases, events, SARs, system watches and routine system reads; keep every write, every human action, RBAC changes in full, every Secret/ConfigMap access (metadata only). Measured offline first (-92%), then live: ~2,000 -> 21 events/min. Applied on the box and in k3s-bootstrap.sh; k3s pinned to v1.36.5+k3s1; ignore_changes = [ami, user_data] (proven: plan with the changed script = 0 changes to the instance).
- FINDING: the Windows infra checkout had been on a stale local branch since Day 14 - every git pull failed quietly. Fixed; routine now uses `git switch main; git pull --ff-only`.
- CloudWatch log groups /secureshop/dev/{falco,audit,apps}, 30-day retention, Checkov skips with reasons; lab role append-only (CreateLogStream, PutLogEvents).
- Fluent Bit 0.58.3 in the bootstrap: read-only host mounts, no RBAC, IMDS guard exception (like ESO); Falco JSON alerts only; kubelet probe lines dropped. Logs Insights: exec (who) + Falco alert (what) correlated off the box.
- Tamper test with the box's own role: create stream OK; delete stream / delete group / shorten retention -> AccessDenied. IAM simulator wrongly showed everything denied for CloudWatch Logs resources - tested the real system instead.
- Follow-ups: alert on silence (a log group receiving nothing); confirm the API probe filter; host root can still stop the shipper or add fake events.

## Day 19
- Session Manager replaces SSH: Windows plugin verified (Authenticode: Amazon Web Services, Inc.); box Online in SSM (agent preinstalled, AmazonSSMManagedInstanceCore since Day 1).
- Port forwarding over SSM straight to Service ClusterIPs (ArgoCD 8080, Grafana 3000): no kubectl port-forward, no MobaSSHTunnel.
- Session preferences in Terraform (SSM-SessionManagerRunShell): every session's input/output streamed to /secureshop/dev/ssm-sessions (append-only role), runs as ubuntu with a login shell, 20-min idle timeout. Verified: log shows userIdentity user/lab-admins, runAsUser ubuntu, every command and output.
- Port 22 closed (SG now 80/443 only; Test-NetConnection 22 = False, 443 = True); my_ip_cidr and terraform.tfvars removed - the daily IP routine is gone (hostname PR remains). CloudTrail StartSession events all attributed to lab-admins.
- Kept key_name until the next rebuild (changing it replaces the instance); on the runbook.

# Lab box rebuild runbook (tested 2026-10-13, recovery time 33 min)

1. PowerShell: `terraform plan -replace="aws_instance.lab"`. Only aws_instance.lab may be replaced. Apply.
2. Read the new SSH host key from the EC2 console log (set PYTHONUTF8=1 first); verify it on first connect.
3. New box: `ssh-keygen -t ed25519`; add to GitHub as Authentication AND Signing key; delete the old key's two entries.
4. Clone the three repos; git identity = GitHub no-reply email; SSH commit signing (gpg.format ssh, allowed_signers).
5. `bash scripts/bootstrap-box.sh` (pinned, checksummed toolchain), log out and back in; diff against docs/toolchain.txt.
6. `pre-commit install` in every repo (hooks are not cloned).
7. gitops: `./platform/bootstrap.sh` (charts, policies, ArgoCD hand-over, RBAC).
8. ArgoCD: port-forward + tunnel to the new IP; rotate the admin password; delete argocd-initial-admin-secret.
9. Hostname PR for the new IP; if the certificate stays pending, delete the stale CertificateRequest/Order.
10. Run the 9 control checks (Pod Security, Gatekeeper, Kyverno, netpol x2, RBAC, redis token, no native policies, HTTPS).
11. Nightly stop schedule: update its instance ID (role allows any instance tagged Name=secureshop-lab).

## Backlog found by this rebuild
- [ ] Pin k3s in user_data (INSTALL_K3S_VERSION) - rebuild got v1.36.5, old box had v1.36.4
- [ ] Nightly stop schedule + lab-scheduler role into Terraform (input = aws_instance.lab.id)
- [ ] Fixed address (Elastic IP or real DNS) to remove the hostname PR and stale-certificate steps
- [ ] ArgoCD: named user, admin.enabled false
- [ ] RDS auto-restarts 7 days after a stop: nightly rds:stopDBInstance schedule in Terraform, or snapshot+delete when idle

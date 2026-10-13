#!/usr/bin/env bash
# Install the lab box toolchain at pinned versions (see docs/toolchain.txt).
# Run once on a fresh box, as the ubuntu user:  bash scripts/bootstrap-box.sh
set -euo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

# Versions: keep in sync with docs/toolchain.txt
TERRAFORM=1.16.5; TRIVY=0.75.0; HELM=v3.22.0; ARGOCD=v3.5.3; SYFT=1.52.0; GRYPE=0.119.0
COSIGN=v3.1.3; GITLEAKS=8.30.1; KUBESCAPE=v4.0.15; KUBECONFORM=v0.8.0; GATOR=v3.23.1
CHECKOV=3.3.20; SEMGREP=1.178.0; PRECOMMIT=4.6.2
TFLINT=v0.64.0; PIPTOOLS=7.6.1
# SHA-256 for downloads whose projects publish no checksum file (same values as the gitops CI)
KUBESCAPE_SHA=011569dbcde85afc96cf63262e4f967166b6680fd70a623e9065334b6767b244
KUBECONFORM_SHA=9bc2bffbf71f261128533edaf912153948b7ff238f9a531ae6d34466ec287883
GATOR_SHA=c268d7b809c9fe59a110ab0bf7c296ab00b0b6c894c209cd15e94194590291bb

get() { curl -fsSL -o "$2" "$1"; }
check() { sha256sum --ignore-missing -c "$1" | grep -q ': OK$' || { echo "CHECKSUM FAILED: $1"; exit 1; }; }
pin() { echo "$1  $2" | sha256sum -c - > /dev/null || { echo "CHECKSUM FAILED: $2"; exit 1; }; }

echo "== apt packages"
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends ca-certificates curl gnupg lsb-release jq unzip git git-secrets pipx docker.io postgresql-client
sudo usermod -aG docker "$USER"

echo "== Signed apt repositories: HashiCorp (Terraform) and Aqua (Trivy)"
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor --yes -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y "terraform=${TERRAFORM}-*" "trivy=${TRIVY}"

echo "== Release binaries, verified against the project's own checksum file"
get "https://get.helm.sh/helm-${HELM}-linux-amd64.tar.gz" helm.tgz
echo "$(curl -fsSL "https://get.helm.sh/helm-${HELM}-linux-amd64.tar.gz.sha256sum" | cut -d' ' -f1)  helm.tgz" | sha256sum -c - > /dev/null
tar -xzf helm.tgz && sudo install linux-amd64/helm /usr/local/bin/helm

get "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD}/argocd-linux-amd64" argocd-linux-amd64
get "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD}/cli_checksums.txt" argocd.sums
check argocd.sums && sudo install argocd-linux-amd64 /usr/local/bin/argocd

for t in syft grype; do
  v=$([ "$t" = syft ] && echo "$SYFT" || echo "$GRYPE")
  get "https://github.com/anchore/$t/releases/download/v$v/${t}_${v}_linux_amd64.tar.gz" "${t}_${v}_linux_amd64.tar.gz"
  get "https://github.com/anchore/$t/releases/download/v$v/${t}_${v}_checksums.txt" "$t.sums"
  check "$t.sums" && tar -xzf "${t}_${v}_linux_amd64.tar.gz" "$t" && sudo install "$t" "/usr/local/bin/$t"
done

get "https://github.com/sigstore/cosign/releases/download/${COSIGN}/cosign-linux-amd64" cosign-linux-amd64
get "https://github.com/sigstore/cosign/releases/download/${COSIGN}/cosign_checksums.txt" cosign.sums
check cosign.sums && sudo install cosign-linux-amd64 /usr/local/bin/cosign

get "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS}/gitleaks_${GITLEAKS}_linux_x64.tar.gz" "gitleaks_${GITLEAKS}_linux_x64.tar.gz"
get "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS}/gitleaks_${GITLEAKS}_checksums.txt" gitleaks.sums
check gitleaks.sums && tar -xzf "gitleaks_${GITLEAKS}_linux_x64.tar.gz" gitleaks && sudo install gitleaks /usr/local/bin/gitleaks

echo "== Release binaries, verified against pinned SHA-256"
get "https://github.com/kubescape/kubescape/releases/download/${KUBESCAPE}/kubescape_${KUBESCAPE#v}_linux_amd64" kubescape
pin "$KUBESCAPE_SHA" kubescape && sudo install kubescape /usr/local/bin/kubescape
get "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM}/kubeconform-linux-amd64.tar.gz" kc.tgz
pin "$KUBECONFORM_SHA" kc.tgz && tar -xzf kc.tgz kubeconform && sudo install kubeconform /usr/local/bin/kubeconform
get "https://github.com/open-policy-agent/gatekeeper/releases/download/${GATOR}/gator-${GATOR}-linux-amd64.tar.gz" gator.tgz
pin "$GATOR_SHA" gator.tgz && tar -xzf gator.tgz gator && sudo install gator /usr/local/bin/gator

echo "== tflint"
get "https://github.com/terraform-linters/tflint/releases/download/${TFLINT}/tflint_linux_amd64.zip" tflint_linux_amd64.zip
get "https://github.com/terraform-linters/tflint/releases/download/${TFLINT}/checksums.txt" tflint.sums
check tflint.sums && unzip -oq tflint_linux_amd64.zip && sudo install tflint /usr/local/bin/tflint

echo "== Python tools via pipx (pinned)"
pipx install "checkov==${CHECKOV}"
pipx install "semgrep==${SEMGREP}"
pipx install "pre-commit==${PRECOMMIT}"
pipx install "pip-tools==${PIPTOOLS}"
pipx ensurepath

echo "== kubectl access to the local k3s cluster"
mkdir -p "$HOME/.kube"
sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
sudo chown "$USER:" "$HOME/.kube/config" && chmod 600 "$HOME/.kube/config"
grep -q 'KUBECONFIG=' "$HOME/.bashrc" || echo 'export KUBECONFIG=$HOME/.kube/config' >> "$HOME/.bashrc"

echo "== Helpers and git-secrets"
cp "$REPO/scripts/wait-cluster.sh" "$REPO/scripts/pin-actions.sh" "$HOME/"
grep -q 'testpod()' "$HOME/.bashrc" || cat "$REPO/scripts/testpod.sh" >> "$HOME/.bashrc"
git secrets --register-aws --global || true

echo "== Done. Log out and back in (docker group, PATH), then check versions against docs/toolchain.txt."

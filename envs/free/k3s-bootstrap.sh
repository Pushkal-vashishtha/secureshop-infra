#!/usr/bin/env bash
set -euo pipefail
mkdir -p /var/lib/rancher/k3s/server/logs
cat > /var/lib/rancher/k3s/server/audit.yaml <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: Metadata
    resources: [{ group: "", resources: ["secrets", "configmaps"] }]
  - level: RequestResponse
    verbs: ["create", "update", "patch", "delete"]
    resources: [{ group: "rbac.authorization.k8s.io" }]
  - level: Metadata
    omitStages: ["RequestReceived"]
EOF

curl -sfL https://get.k3s.io | sh -s - server \
  --secrets-encryption \
  --write-kubeconfig-mode 0600 \
  --kube-apiserver-arg=audit-log-path=/var/lib/rancher/k3s/server/logs/audit.log \
  --kube-apiserver-arg=audit-policy-file=/var/lib/rancher/k3s/server/audit.yaml \
  --kube-apiserver-arg=audit-log-maxage=7 \
  --kube-apiserver-arg=audit-log-maxsize=100
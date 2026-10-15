#!/usr/bin/env bash
set -euo pipefail
mkdir -p /var/lib/rancher/k3s/server/logs
cat > /var/lib/rancher/k3s/server/audit.yaml <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
# One event per request (when it completes), not two.
omitStages: ["RequestReceived"]
rules:
  # 1. Health and version probes: constant, never interesting.
  - level: None
    nonResourceURLs: ["/healthz*", "/readyz*", "/livez*", "/version", "/metrics", "/openapi*"]
  # 2. Heartbeats: leader-election leases and events.
  - level: None
    resources:
      - {group: "coordination.k8s.io", resources: ["leases"]}
      - {group: "", resources: ["events"]}
      - {group: "events.k8s.io", resources: ["events"]}
  # 3. Components checking their own permissions.
  - level: None
    resources:
      - {group: "authorization.k8s.io", resources: ["selfsubjectaccessreviews", "subjectaccessreviews"]}
  # 4. Long-lived watches by system components (including on Secrets).
  - level: None
    verbs: ["watch"]
    userGroups: ["system:serviceaccounts", "system:nodes"]
  - level: None
    verbs: ["watch"]
    users: ["system:kube-controller-manager", "system:kube-scheduler", "system:apiserver", "system:kube-proxy", "system:k3s-controller", "system:k3s-supervisor", "k3s-cloud-controller-manager"]
  # 5. RBAC changes: who granted what, with full request and response.
  - level: RequestResponse
    verbs: ["create", "update", "patch", "delete"]
    resources: [{group: "rbac.authorization.k8s.io"}]
  # 6. Secrets and configmaps: every access, metadata only (never the values).
  - level: Metadata
    resources: [{group: "", resources: ["secrets", "configmaps"]}]
  # 7. Routine reads by system components.
  - level: None
    verbs: ["get", "list"]
    userGroups: ["system:serviceaccounts", "system:nodes"]
  - level: None
    verbs: ["get", "list"]
    users: ["system:kube-controller-manager", "system:kube-scheduler", "system:apiserver", "system:kube-proxy", "system:k3s-controller", "system:k3s-supervisor", "k3s-cloud-controller-manager"]
  # 8. Everything else: every write, every human action (exec included).
  - level: Metadata
EOF

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.36.5+k3s1 sh -s - server \
  --secrets-encryption \
  --write-kubeconfig-mode 0600 \
  --kube-apiserver-arg=audit-log-path=/var/lib/rancher/k3s/server/logs/audit.log \
  --kube-apiserver-arg=audit-policy-file=/var/lib/rancher/k3s/server/audit.yaml \
  --kube-apiserver-arg=audit-log-maxage=7 \
  --kube-apiserver-arg=audit-log-maxsize=100

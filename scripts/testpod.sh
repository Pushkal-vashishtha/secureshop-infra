# testpod <image>: print a Pod Security-compliant test pod in namespace web
testpod() { cat <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: policy-test
  namespace: web
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 101
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: c
      image: $1
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
EOF
}

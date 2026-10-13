#!/usr/bin/env bash
# Wait until the API answers and every pod (except one-time helm-install jobs) is Running and fully Ready.
while true; do
  out=$(kubectl get pods -A --no-headers 2>/dev/null)
  if [ -z "$out" ]; then echo "$(date +%T)  API not answering yet"; sleep 20; continue; fi
  notready=$(echo "$out" | grep -v helm-install | awk '{split($3,r,"/"); if ($4!="Running" || r[1]!=r[2]) c++} END{print c+0}')
  [ "$notready" = "0" ] && break
  echo "$(date +%T)  not ready yet: $notready pods"; sleep 20
done
echo "ALL READY"; uptime

#!/usr/bin/env bash
set -euo pipefail

# 1) Serveur k3s (control plane)
multipass exec k3s-server -- bash -c \
  "curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode 644"

TOKEN=$(multipass exec k3s-server -- sudo cat /var/lib/rancher/k3s/server/node-token)
SERVER_IP=$(multipass info k3s-server | awk '/IPv4/ {print $2; exit}')

# 2) Agent (worker)
multipass exec k3s-agent-1 -- bash -c \
  "curl -sfL https://get.k3s.io | K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=${TOKEN} sh -"

# 3) Kubeconfig local
multipass exec k3s-server -- sudo cat /etc/rancher/k3s/k3s.yaml \
  | sed "s/127.0.0.1/${SERVER_IP}/; s/: default$/: k3s-obs/" > ~/.kube/k3s-obs.yaml
chmod 600 ~/.kube/k3s-obs.yaml
export KUBECONFIG=~/.kube/k3s-obs.yaml

# 4) Attendre l'agent puis le labelliser
kubectl wait --for=condition=Ready node/k3s-agent-1 --timeout=180s
kubectl label node k3s-agent-1 node-role.kubernetes.io/worker=worker --overwrite
kubectl get nodes -o wide

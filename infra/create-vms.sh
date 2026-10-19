#!/usr/bin/env bash
set -euo pipefail
multipass launch 24.04 --name k3s-server  --cpus 2 --memory 4G --disk 20G
multipass launch 24.04 --name k3s-agent-1 --cpus 4 --memory 8G --disk 40G
multipass list

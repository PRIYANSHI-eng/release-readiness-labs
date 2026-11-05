#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/rollback.sh v2.2.0
TARGET="${1:-v2.2.0}"

echo "Rolling back OrderFlow to ${TARGET}"

# Lab mode: commands are printed, not executed (no real cluster)
echo "kubectl rollout undo deployment/lab-app"
echo "kubectl set image deployment/lab-app lab-app=lab-app:${TARGET}"
echo "kubectl rollout status deployment/lab-app --timeout=120s"

echo "Rollback to ${TARGET} complete."
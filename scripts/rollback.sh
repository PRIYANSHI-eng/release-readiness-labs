#!/bin/bash
set -euo pipefail

TARGET_VERSION="${1:?A rollback target version is required}"

echo "Rolling back deployment to ${TARGET_VERSION}..."
echo "Rollback validation required: check the /health endpoint and deployment status."

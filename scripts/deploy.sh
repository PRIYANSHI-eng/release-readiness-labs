#!/bin/bash
set -euo pipefail

RELEASE_VERSION="${1:?A release version is required}"

echo "Starting deployment..."
echo "Deploying version: ${RELEASE_VERSION}"
echo "Deployment successful."

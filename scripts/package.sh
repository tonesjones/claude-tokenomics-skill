#!/usr/bin/env bash
# Builds dist/tokenomics-<version>.zip for upload to Claude (Settings > Capabilities > Skills).
set -euo pipefail
cd "$(dirname "$0")/.."
version="$(cat VERSION)"
mkdir -p dist
rm -f "dist/tokenomics-${version}.zip"
(cd skills && zip -rq "../dist/tokenomics-${version}.zip" tokenomics)
echo "dist/tokenomics-${version}.zip"

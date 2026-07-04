#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

grep -Fq './scripts/build-prototype.sh dist' "$repo_root/README.md"
grep -Fq './dist/firefox-minimal/launch.sh https://example.com' "$repo_root/README.md"
grep -Fq 'about:policies' "$repo_root/README.md"
grep -Fq 'about:addons' "$repo_root/README.md"
grep -Fq 'Press `?` and confirm Vimium C help opens.' "$repo_root/README.md"

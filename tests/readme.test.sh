#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

grep -Fq 'make build' "$repo_root/README.md"
grep -Fq 'make run' "$repo_root/README.md"
grep -Fq 'make install' "$repo_root/README.md"
grep -Fq 'make test' "$repo_root/README.md"
grep -Fq 'wmfox' "$repo_root/README.md"
grep -Fq 'IBM Plex Mono' "$repo_root/README.md"
grep -Fq 'bottom-mounted chrome' "$repo_root/README.md"
grep -Fq 'about:policies' "$repo_root/README.md"
grep -Fq 'Press `?` and confirm Vimium C help opens.' "$repo_root/README.md"

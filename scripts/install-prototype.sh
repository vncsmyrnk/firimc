#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 APP_DIR INSTALL_DIR" >&2
  exit 64
fi

app_dir="$1"
install_dir="$2"

if [[ ! -d "$app_dir" ]]; then
  echo "missing app dir: $app_dir" >&2
  exit 66
fi

mkdir -p "$(dirname "$install_dir")"
rm -rf "$install_dir"
cp -R "$app_dir" "$install_dir"

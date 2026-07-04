#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 OUTPUT_DIR" >&2
  exit 64
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_root="$1"
mkdir -p "$output_root"
output_root="$(cd "$output_root" && pwd)"

app_dir="$output_root/firefox-minimal"
addons_dir="$app_dir/addons"
profile_prefs_src="$repo_root/prototype/profile/user.js"
theme_src="$repo_root/vendor/wmfox/userChrome.css"
work_dir="$(mktemp -d)"
firefox_url="${FIREFOX_URL:-https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US}"
vimium_url="${VIMIUMC_XPI_URL:-https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi}"

trap 'rm -rf "$work_dir"' EXIT

rm -rf "$app_dir"
mkdir -p "$app_dir" "$addons_dir" "$app_dir/profile/chrome"

curl -fsSL "$firefox_url" -o "$work_dir/firefox.tar.xz"
tar -xJf "$work_dir/firefox.tar.xz" -C "$work_dir"
mv "$work_dir/firefox" "$app_dir/firefox"

curl -fsSL "$vimium_url" -o "$addons_dir/vimium-c.xpi"
install -m 0644 "$profile_prefs_src" "$app_dir/profile/user.js"
install -m 0644 "$theme_src" "$app_dir/profile/chrome/userChrome.css"
mkdir -p "$app_dir/firefox/distribution"
install -m 0755 "$repo_root/scripts/launch-prototype.sh" "$app_dir/launch.sh"

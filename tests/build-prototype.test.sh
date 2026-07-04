#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/firefox"
cat > "$tmp_dir/firefox/firefox" <<'EOF'
#!/usr/bin/env bash
echo stub-firefox
EOF
chmod +x "$tmp_dir/firefox/firefox"

tar -C "$tmp_dir" -cJf "$tmp_dir/firefox.tar.xz" firefox
printf 'fake vimium xpi' > "$tmp_dir/vimium-c.xpi"

FIREFOX_URL="file://$tmp_dir/firefox.tar.xz" \
VIMIUMC_XPI_URL="file://$tmp_dir/vimium-c.xpi" \
  "$repo_root/scripts/build-prototype.sh" "$tmp_dir/out"

app_dir="$tmp_dir/out/firefox-minimal"
test -x "$app_dir/firefox/firefox"
test -f "$app_dir/addons/vimium-c.xpi"
test -f "$app_dir/profile/user.js"
test -f "$app_dir/profile/chrome/userChrome.css"
test -x "$app_dir/launch.sh"

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

src_app="$tmp_dir/source/firefox-minimal"
install_dir="$tmp_dir/install/firefox-minimal"

mkdir -p "$src_app/firefox" "$src_app/profile/chrome" "$src_app/addons"
cat > "$src_app/launch.sh" <<'EOF'
#!/usr/bin/env bash
echo installed-launcher
EOF
chmod +x "$src_app/launch.sh"
printf 'sentinel' > "$src_app/profile/user.js"

mkdir -p "$install_dir"
printf 'stale' > "$install_dir/stale.txt"

"$repo_root/scripts/install-prototype.sh" "$src_app" "$install_dir"

test -x "$install_dir/launch.sh"
grep -Fq 'sentinel' "$install_dir/profile/user.js"
test ! -e "$install_dir/stale.txt"

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

app_dir="$tmp_dir/firefox-minimal"
mkdir -p "$app_dir/firefox" "$app_dir/addons" "$app_dir/profile"
cp "$repo_root/scripts/launch-prototype.sh" "$app_dir/launch.sh"
chmod +x "$app_dir/launch.sh"

cat > "$app_dir/firefox/firefox" <<'EOF'
#!/usr/bin/env bash
echo should-not-run
EOF
chmod +x "$app_dir/firefox/firefox"
printf 'fake vimium xpi' > "$app_dir/addons/vimium-c.xpi"

actual="$("$app_dir/launch.sh" --dry-run https://example.com)"
expected="$app_dir/firefox/firefox --no-remote --profile $app_dir/profile https://example.com"
test "$actual" = "$expected"

grep -Fq '"file://"' "$app_dir/firefox/distribution/policies.json"
grep -Fq 'vimium-c@gdh1995.cn' "$app_dir/firefox/distribution/policies.json"

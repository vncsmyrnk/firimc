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

make -C "$repo_root" build OUTPUT_DIR="$tmp_dir/out" \
  FIREFOX_URL="file://$tmp_dir/firefox.tar.xz" \
  VIMIUMC_XPI_URL="file://$tmp_dir/vimium-c.xpi"

test -x "$tmp_dir/out/firefox-minimal/launch.sh"

actual="$(make -s -C "$repo_root" run OUTPUT_DIR="$tmp_dir/out" RUN_ARGS='--dry-run https://example.com')"
expected="$tmp_dir/out/firefox-minimal/firefox/firefox --no-remote --profile $tmp_dir/out/firefox-minimal/profile https://example.com"
test "$actual" = "$expected"

make -C "$repo_root" install OUTPUT_DIR="$tmp_dir/out" INSTALL_DIR="$tmp_dir/install/firefox-minimal" \
  FIREFOX_URL="file://$tmp_dir/firefox.tar.xz" \
  VIMIUMC_XPI_URL="file://$tmp_dir/vimium-c.xpi"

test -x "$tmp_dir/install/firefox-minimal/launch.sh"
make -n -C "$repo_root" test | grep -Fq 'tests/install-prototype.test.sh'
make -n -C "$repo_root" test | grep -Fq 'tests/makefile.test.sh'

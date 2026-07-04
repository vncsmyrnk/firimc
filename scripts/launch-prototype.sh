#!/usr/bin/env bash
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
firefox_bin="$app_dir/firefox/firefox"
profile_dir="$app_dir/profile"
addon_xpi="$app_dir/addons/vimium-c.xpi"
policy_dir="$app_dir/firefox/distribution"
policy_file="$policy_dir/policies.json"

mkdir -p "$policy_dir"

cat > "$policy_file" <<EOF
{
  "policies": {
    "Extensions": {
      "Install": [
        "file://$addon_xpi"
      ],
      "Locked": [
        "vimium-c@gdh1995.cn"
      ]
    }
  }
}
EOF

if [[ "${1:-}" == "--dry-run" ]]; then
  shift
  printf '%s\n' "$firefox_bin --no-remote --profile $profile_dir $*"
  exit 0
fi

exec "$firefox_bin" --no-remote --profile "$profile_dir" "$@"

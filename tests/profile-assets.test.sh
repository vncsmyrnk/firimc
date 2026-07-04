#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test -f "$repo_root/vendor/wmfox/userChrome.css"
test -f "$repo_root/vendor/wmfox/LICENSE"
grep -Fq 'Pinned commit: 6710ecbd9ed24b6f725ae83c1ffa64363f4a7e0a' \
  "$repo_root/vendor/wmfox/SOURCE.md"

if [[ -e "$repo_root/prototype/profile/chrome/userChrome.css" ]]; then
  echo "expected old source theme file to be removed" >&2
  exit 1
fi

grep -Fq 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' \
  "$repo_root/prototype/profile/user.js"
grep -Fq 'user_pref("browser.compactmode.show", true);' \
  "$repo_root/prototype/profile/user.js"
grep -Fq 'user_pref("browser.uidensity", 1);' \
  "$repo_root/prototype/profile/user.js"

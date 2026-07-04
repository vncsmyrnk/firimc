#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test -f "$repo_root/prototype/profile/user.js"
grep -Fq 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' \
  "$repo_root/prototype/profile/user.js"

test -f "$repo_root/prototype/profile/chrome/userChrome.css"
grep -Fq '.tabbrowser-tab:not([selected="true"]) .tab-label-container' \
  "$repo_root/prototype/profile/chrome/userChrome.css"
grep -Fq '#page-action-buttons' \
  "$repo_root/prototype/profile/chrome/userChrome.css"
grep -Fq '#tracking-protection-icon-container' \
  "$repo_root/prototype/profile/chrome/userChrome.css"

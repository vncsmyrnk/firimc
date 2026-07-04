# Firefox Minimal Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Linux-only prototype distribution that bundles official Firefox, launches with an isolated profile, auto-installs Vimium C, and reduces the tab strip and URL bar to minimal presentation.

**Architecture:** Keep the prototype as a relocatable app directory assembled by Bash. `scripts/build-prototype.sh` downloads the official Firefox tarball and Vimium C XPI, copies a repo-owned profile skeleton, and writes a launchable tree under `dist/firefox-minimal/`. `scripts/launch-prototype.sh` regenerates `firefox/distribution/policies.json` on each launch so the bundled browser can force-install Vimium C from the bundle without touching `/etc` or the user's normal Firefox profile.

**Tech Stack:** Bash, curl, tar, Firefox `policies.json`, `user.js`, `userChrome.css`, POSIX shell tests

## Global Constraints

- Linux only.
- Bundle official Firefox; do not build or fork Firefox.
- Bundle Vimium C from `https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi`.
- Launch with `--no-remote --profile` against an isolated bundled profile.
- Only change presentation of tabs and the current URL; do not change Firefox's tab or address-bar behavior model.
- Do not require root privileges.
- Do not write to `/etc` or the user's default Firefox profile.

---

## Planned File Structure

- `scripts/build-prototype.sh` — assembles `dist/firefox-minimal/` from upstream Firefox, Vimium C, and repo-owned assets.
- `scripts/launch-prototype.sh` — writes a per-bundle `policies.json` pointing at the bundled Vimium C XPI and launches bundled Firefox.
- `prototype/profile/user.js` — enables stylesheet-based chrome customization.
- `prototype/profile/chrome/userChrome.css` — reduces tab noise and URL-bar noise while keeping the active tab label and current URL visible.
- `tests/profile-assets.test.sh` — asserts the profile assets encode the intended prefs and CSS selectors.
- `tests/build-prototype.test.sh` — black-box build test using local fixture downloads via `file://`.
- `tests/launch-prototype.test.sh` — dry-run launcher test that validates policy output and exec argv.
- `tests/readme.test.sh` — ensures the usage document keeps the required build and verification instructions.
- `README.md` — build, launch, update, and manual verification instructions.

### Task 1: Create the profile assets

**Files:**
- Create: `prototype/profile/user.js`
- Create: `prototype/profile/chrome/userChrome.css`
- Create: `tests/profile-assets.test.sh`

**Interfaces:**
- Consumes: none
- Produces:
  - `prototype/profile/user.js` — startup prefs for the bundled profile
  - `prototype/profile/chrome/userChrome.css` — browser-chrome stylesheet copied into the distribution profile

- [ ] **Step 1: Write the failing test**

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/profile-assets.test.sh`
Expected: FAIL with `test: .../prototype/profile/user.js: No such file or directory`

- [ ] **Step 3: Write minimal implementation**

`prototype/profile/user.js`

```js
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
```

`prototype/profile/chrome/userChrome.css`

```css
#TabsToolbar .titlebar-spacer,
#alltabs-button,
#tabs-newtab-button,
.tab-close-button,
.tab-secondary-label {
  display: none !important;
}

.tabbrowser-tab:not([selected="true"]) {
  min-width: 40px !important;
  max-width: 40px !important;
}

.tabbrowser-tab:not([selected="true"]) .tab-label-container {
  display: none !important;
}

.tabbrowser-tab[selected="true"] {
  min-width: 180px !important;
}

#page-action-buttons,
#tracking-protection-icon-container,
#star-button-box,
#reader-mode-button,
#translations-button,
#identity-permission-box {
  display: none !important;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/profile-assets.test.sh && echo PASS`
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add prototype/profile/user.js prototype/profile/chrome/userChrome.css tests/profile-assets.test.sh
git commit -m "feat: add prototype profile assets"
```

### Task 2: Assemble a relocatable Firefox bundle

**Files:**
- Create: `scripts/build-prototype.sh`
- Create: `tests/build-prototype.test.sh`
- Consumes from Task 1: `prototype/profile/user.js`, `prototype/profile/chrome/userChrome.css`

**Interfaces:**
- Consumes:
  - `prototype/profile/` directory copied verbatim into the built app
- Produces:
  - `scripts/build-prototype.sh <output-dir>` — writes `<output-dir>/firefox-minimal/`
  - `<output-dir>/firefox-minimal/firefox/firefox` — bundled Firefox binary
  - `<output-dir>/firefox-minimal/addons/vimium-c.xpi` — bundled Vimium C XPI
  - `<output-dir>/firefox-minimal/profile/` — isolated Firefox profile

- [ ] **Step 1: Write the failing test**

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/build-prototype.test.sh`
Expected: FAIL with `.../scripts/build-prototype.sh: No such file or directory`

- [ ] **Step 3: Write minimal implementation**

`scripts/build-prototype.sh`

```bash
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
profile_src="$repo_root/prototype/profile"
work_dir="$(mktemp -d)"
firefox_url="${FIREFOX_URL:-https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US}"
vimium_url="${VIMIUMC_XPI_URL:-https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi}"

trap 'rm -rf "$work_dir"' EXIT

rm -rf "$app_dir"
mkdir -p "$app_dir" "$addons_dir"

curl -fsSL "$firefox_url" -o "$work_dir/firefox.tar.xz"
tar -xJf "$work_dir/firefox.tar.xz" -C "$work_dir"
mv "$work_dir/firefox" "$app_dir/firefox"

curl -fsSL "$vimium_url" -o "$addons_dir/vimium-c.xpi"
cp -R "$profile_src" "$app_dir/profile"
mkdir -p "$app_dir/firefox/distribution"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/build-prototype.test.sh && echo PASS`
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add scripts/build-prototype.sh tests/build-prototype.test.sh
git commit -m "feat: add prototype bundle assembler"
```

### Task 3: Generate policies at launch time and ship a launcher

**Files:**
- Create: `scripts/launch-prototype.sh`
- Create: `tests/launch-prototype.test.sh`
- Modify: `scripts/build-prototype.sh`
- Modify: `tests/build-prototype.test.sh`

**Interfaces:**
- Consumes:
  - Built tree from `scripts/build-prototype.sh`
  - Bundled Vimium C XPI at `<app-dir>/addons/vimium-c.xpi`
- Produces:
  - `scripts/launch-prototype.sh [--dry-run] [url-or-args...]` — generates policy JSON and starts bundled Firefox
  - `<app-dir>/launch.sh` — launcher copied into the built app
  - `<app-dir>/firefox/distribution/policies.json` — install+lock policy for `vimium-c@gdh1995.cn`

- [ ] **Step 1: Write the failing launcher test**

```bash
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

grep -Fq '"file://'" "$app_dir/firefox/distribution/policies.json"
grep -Fq 'vimium-c@gdh1995.cn' "$app_dir/firefox/distribution/policies.json"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/launch-prototype.test.sh`
Expected: FAIL with `cp: cannot stat '.../scripts/launch-prototype.sh'`

- [ ] **Step 3: Write the launcher implementation**

`scripts/launch-prototype.sh`

```bash
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
```

- [ ] **Step 4: Update the bundle assembler to ship the launcher**

Replace `scripts/build-prototype.sh` with:

```bash
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
profile_src="$repo_root/prototype/profile"
work_dir="$(mktemp -d)"
firefox_url="${FIREFOX_URL:-https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US}"
vimium_url="${VIMIUMC_XPI_URL:-https://addons.mozilla.org/firefox/downloads/latest/vimium-c/latest.xpi}"

trap 'rm -rf "$work_dir"' EXIT

rm -rf "$app_dir"
mkdir -p "$app_dir" "$addons_dir"

curl -fsSL "$firefox_url" -o "$work_dir/firefox.tar.xz"
tar -xJf "$work_dir/firefox.tar.xz" -C "$work_dir"
mv "$work_dir/firefox" "$app_dir/firefox"

curl -fsSL "$vimium_url" -o "$addons_dir/vimium-c.xpi"
cp -R "$profile_src" "$app_dir/profile"
mkdir -p "$app_dir/firefox/distribution"
install -m 0755 "$repo_root/scripts/launch-prototype.sh" "$app_dir/launch.sh"
```

Replace `tests/build-prototype.test.sh` with:

```bash
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
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bash tests/build-prototype.test.sh && bash tests/launch-prototype.test.sh && echo PASS`
Expected: `PASS`

- [ ] **Step 6: Commit**

```bash
git add scripts/build-prototype.sh scripts/launch-prototype.sh tests/build-prototype.test.sh tests/launch-prototype.test.sh
git commit -m "feat: add prototype launcher"
```

### Task 4: Document build, launch, and manual verification

**Files:**
- Create: `README.md`
- Create: `tests/readme.test.sh`

**Interfaces:**
- Consumes:
  - `scripts/build-prototype.sh`
  - `dist/firefox-minimal/launch.sh`
- Produces:
  - `README.md` with exact build command, launch command, update command, and manual verification checklist

- [ ] **Step 1: Write the failing documentation test**

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

grep -Fq './scripts/build-prototype.sh dist' "$repo_root/README.md"
grep -Fq './dist/firefox-minimal/launch.sh https://example.com' "$repo_root/README.md"
grep -Fq 'about:policies' "$repo_root/README.md"
grep -Fq 'about:addons' "$repo_root/README.md"
grep -Fq 'Press `?` and confirm Vimium C help opens.' "$repo_root/README.md"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/readme.test.sh`
Expected: FAIL with `grep: .../README.md: No such file or directory`

- [ ] **Step 3: Write the README**

`README.md`

````markdown
# Firefox Minimal Prototype

Linux-only prototype that bundles official Firefox, uses an isolated profile, installs Vimium C from a generated enterprise policy, and trims the tab strip and URL bar to minimal presentation.

## Build

```bash
./scripts/build-prototype.sh dist
```

The built app is written to `dist/firefox-minimal/`.

## Launch

```bash
./dist/firefox-minimal/launch.sh https://example.com
```

## Update bundled inputs

Re-run the build to refresh both upstream artifacts:

```bash
rm -rf dist/firefox-minimal
./scripts/build-prototype.sh dist
```

## What the prototype changes

- Vimium C is installed and locked by `firefox/distribution/policies.json`.
- Inactive tabs collapse to favicon-only slots.
- The active tab keeps its text label.
- URL bar action clutter is hidden while the current URL remains visible.

## Manual verification

1. Run `./scripts/build-prototype.sh dist`.
2. Run `./dist/firefox-minimal/launch.sh https://example.com`.
3. Open `about:policies` and confirm the extension install policy is active.
4. Open `about:addons` and confirm Vimium C is installed and locked.
5. Open several tabs and confirm inactive tabs show only favicons while the active tab still shows its title.
6. Confirm the URL bar still shows the current page URL but no page-action cluster, star button, or tracking-protection button.
7. Press `?` and confirm Vimium C help opens.
````

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/readme.test.sh && echo PASS`
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add README.md tests/readme.test.sh
git commit -m "docs: add prototype usage guide"
```

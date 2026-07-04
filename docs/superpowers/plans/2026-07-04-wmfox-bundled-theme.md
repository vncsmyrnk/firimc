# wmfox Bundled Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the repository into a Makefile-driven isolated Firefox bundle that ships a pinned upstream wmfox theme snapshot instead of the current hand-written custom theme.

**Architecture:** Keep the existing bundle-and-launch architecture, but move the theme source of truth to a vendored wmfox snapshot under `vendor/wmfox/`. `scripts/build-prototype.sh` assembles a fully configured `dist/firefox-minimal/` tree, `scripts/install-prototype.sh` copies that built bundle into an install directory, and the Makefile becomes the supported interface for build, run, install, and test workflows.

**Tech Stack:** Bash, Make, curl, tar, Firefox `user.js`, Firefox `userChrome.css`, Firefox `policies.json`, POSIX shell tests

## Global Constraints

- Keep the project as an isolated bundled Firefox prototype rather than modifying the user's installed Firefox.
- Replace the repo's current custom `userChrome.css` behavior with a pinned upstream **wmfox** snapshot.
- Avoid repo-specific UI redesign layered on top of wmfox; keep local configuration limited to bundle glue and Firefox prefs needed to enable wmfox in the isolated profile.
- Expose the supported workflow through `make build`, `make run`, `make install`, and `make test`.
- Ensure the final built or installed bundle already contains the opinionated configuration that defines the prototype.
- Applying wmfox to the user's existing system Firefox profile is out of scope.
- Adding a user-facing theme update workflow such as `make update-theme` is out of scope.
- Turning the project into an OS-specific package format such as `.deb` or `.rpm` is out of scope.
- The vendored wmfox snapshot is pinned to commit `6710ecbd9ed24b6f725ae83c1ffa64363f4a7e0a`.
- `prototype/profile/user.js` must contain exactly these prefs: `toolkit.legacyUserProfileCustomizations.stylesheets = true`, `browser.compactmode.show = true`, and `browser.uidensity = 1`.
- `make install` copies the already-built bundle into `INSTALL_DIR`, defaulting to `$(HOME)/.local/firefox-minimal`.

---

## Planned File Structure

- `vendor/wmfox/userChrome.css` — pinned upstream wmfox theme snapshot copied into the built Firefox profile.
- `vendor/wmfox/LICENSE` — upstream wmfox license text shipped alongside the vendored snapshot.
- `vendor/wmfox/SOURCE.md` — provenance note naming the upstream repository URL and pinned commit.
- `prototype/profile/user.js` — bundle-owned Firefox prefs required to enable wmfox in the isolated profile.
- `scripts/build-prototype.sh` — assembles `dist/firefox-minimal/` and copies the vendored wmfox CSS into `profile/chrome/userChrome.css`.
- `scripts/install-prototype.sh` — copies a fully built bundle into an install directory without requiring root.
- `Makefile` — supported top-level interface for build, run, install, and test workflows.
- `tests/profile-assets.test.sh` — asserts vendored wmfox assets and required profile prefs exist, and the old hand-written theme file is gone.
- `tests/build-prototype.test.sh` — black-box build test that verifies the built profile contains the vendored wmfox CSS and bundle assets.
- `tests/install-prototype.test.sh` — verifies the install script replaces a target directory with a runnable bundle copy.
- `tests/makefile.test.sh` — verifies `make build`, `make run`, `make install`, and `make test` expose the documented workflow.
- `tests/launch-prototype.test.sh` — keeps verifying launcher policy generation and exec argv.
- `tests/readme.test.sh` — asserts README documents the Makefile-first wmfox workflow and manual verification checklist.
- `README.md` — documents build, run, install, test, and wmfox-oriented manual verification.

### Task 1: Vendor wmfox and define the profile prefs

**Files:**
- Create: `vendor/wmfox/userChrome.css`
- Create: `vendor/wmfox/LICENSE`
- Create: `vendor/wmfox/SOURCE.md`
- Modify: `prototype/profile/user.js`
- Modify: `tests/profile-assets.test.sh`

**Interfaces:**
- Consumes: none
- Produces:
  - `vendor/wmfox/userChrome.css` — exact upstream wmfox snapshot from commit `6710ecbd9ed24b6f725ae83c1ffa64363f4a7e0a`
  - `vendor/wmfox/LICENSE` — upstream license file from the same pinned commit
  - `vendor/wmfox/SOURCE.md` — provenance note naming the repository URL and pinned commit
  - `prototype/profile/user.js` — exactly three `user_pref(...)` lines for wmfox-enabling prefs

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test -f "$repo_root/vendor/wmfox/userChrome.css"
test -f "$repo_root/vendor/wmfox/LICENSE"
grep -Fq 'Pinned commit: 6710ecbd9ed24b6f725ae83c1ffa64363f4a7e0a' \
  "$repo_root/vendor/wmfox/SOURCE.md"

grep -Fq 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' \
  "$repo_root/prototype/profile/user.js"
grep -Fq 'user_pref("browser.compactmode.show", true);' \
  "$repo_root/prototype/profile/user.js"
grep -Fq 'user_pref("browser.uidensity", 1);' \
  "$repo_root/prototype/profile/user.js"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/profile-assets.test.sh`
Expected: FAIL with `test: .../vendor/wmfox/userChrome.css: No such file or directory`

- [ ] **Step 3: Write minimal implementation**

```bash
mkdir -p vendor/wmfox

curl -fsSL \
  https://raw.githubusercontent.com/cankurttekin/wmfox/6710ecbd9ed24b6f725ae83c1ffa64363f4a7e0a/userChrome.css \
  -o vendor/wmfox/userChrome.css

curl -fsSL \
  https://raw.githubusercontent.com/cankurttekin/wmfox/6710ecbd9ed24b6f725ae83c1ffa64363f4a7e0a/LICENSE \
  -o vendor/wmfox/LICENSE

cat > vendor/wmfox/SOURCE.md <<'EOF'
# wmfox source

Upstream repository: https://github.com/cankurttekin/wmfox
Pinned commit: 6710ecbd9ed24b6f725ae83c1ffa64363f4a7e0a
Fetched files:
- userChrome.css
- LICENSE
EOF

cat > prototype/profile/user.js <<'EOF'
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);
EOF
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/profile-assets.test.sh && echo PASS`
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add vendor/wmfox/userChrome.css vendor/wmfox/LICENSE vendor/wmfox/SOURCE.md prototype/profile/user.js tests/profile-assets.test.sh
git commit -m "feat: vendor wmfox theme assets"
```

### Task 2: Build the bundle from the vendored wmfox snapshot

**Files:**
- Delete: `prototype/profile/chrome/userChrome.css`
- Modify: `scripts/build-prototype.sh`
- Modify: `tests/profile-assets.test.sh`
- Modify: `tests/build-prototype.test.sh`

**Interfaces:**
- Consumes:
  - `vendor/wmfox/userChrome.css` — pinned upstream wmfox snapshot from Task 1
  - `prototype/profile/user.js` — pref file produced by Task 1
- Produces:
  - `scripts/build-prototype.sh OUTPUT_DIR` — writes `OUTPUT_DIR/firefox-minimal/profile/user.js`
  - `scripts/build-prototype.sh OUTPUT_DIR` — writes `OUTPUT_DIR/firefox-minimal/profile/chrome/userChrome.css`
  - source tree no longer contains `prototype/profile/chrome/userChrome.css`

- [ ] **Step 1: Write the failing tests**

`tests/profile-assets.test.sh`

```bash
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
```

`tests/build-prototype.test.sh`

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
cmp "$repo_root/vendor/wmfox/userChrome.css" "$app_dir/profile/chrome/userChrome.css"
test -x "$app_dir/launch.sh"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/profile-assets.test.sh && bash tests/build-prototype.test.sh`
Expected: FAIL with `expected old source theme file to be removed`

- [ ] **Step 3: Write minimal implementation**

```bash
rm -f prototype/profile/chrome/userChrome.css

cat > scripts/build-prototype.sh <<'EOF'
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
EOF

chmod +x scripts/build-prototype.sh
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/profile-assets.test.sh && bash tests/build-prototype.test.sh && bash tests/launch-prototype.test.sh && echo PASS`
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add scripts/build-prototype.sh tests/profile-assets.test.sh tests/build-prototype.test.sh prototype/profile/user.js vendor/wmfox
git rm prototype/profile/chrome/userChrome.css
git commit -m "feat: build bundle from wmfox theme"
```

### Task 3: Add Makefile and install workflow

**Files:**
- Create: `Makefile`
- Create: `scripts/install-prototype.sh`
- Create: `tests/install-prototype.test.sh`
- Create: `tests/makefile.test.sh`

**Interfaces:**
- Consumes:
  - `scripts/build-prototype.sh OUTPUT_DIR` — bundle assembly interface from Task 2
  - `scripts/launch-prototype.sh [--dry-run] [url-or-args...]` — launcher interface from existing code
- Produces:
  - `make build` — runs `scripts/build-prototype.sh "$(OUTPUT_DIR)"`
  - `make run` — runs `"$(OUTPUT_DIR)/firefox-minimal/launch.sh" $(RUN_ARGS)`
  - `make install` — runs `scripts/install-prototype.sh "$(OUTPUT_DIR)/firefox-minimal" "$(INSTALL_DIR)"`
  - `scripts/install-prototype.sh APP_DIR INSTALL_DIR` — copies a built bundle into `INSTALL_DIR`

- [ ] **Step 1: Write the failing tests**

`tests/install-prototype.test.sh`

```bash
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
```

`tests/makefile.test.sh`

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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/install-prototype.test.sh && bash tests/makefile.test.sh`
Expected: FAIL with `.../scripts/install-prototype.sh: No such file or directory`

- [ ] **Step 3: Write minimal implementation**

`scripts/install-prototype.sh`

```bash
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
```

`Makefile`

```make
OUTPUT_DIR ?= dist
APP_DIR := $(OUTPUT_DIR)/firefox-minimal
INSTALL_DIR ?= $(HOME)/.local/firefox-minimal
RUN_ARGS ?=

.PHONY: build run install test

build:
	./scripts/build-prototype.sh "$(OUTPUT_DIR)"

run: build
	"$(APP_DIR)/launch.sh" $(RUN_ARGS)

install: build
	./scripts/install-prototype.sh "$(APP_DIR)" "$(INSTALL_DIR)"

test:
	bash tests/profile-assets.test.sh && \
	bash tests/build-prototype.test.sh && \
	bash tests/launch-prototype.test.sh && \
	bash tests/install-prototype.test.sh && \
	bash tests/makefile.test.sh && \
	bash tests/readme.test.sh
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/install-prototype.test.sh && bash tests/makefile.test.sh && echo PASS`
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add Makefile scripts/install-prototype.sh tests/install-prototype.test.sh tests/makefile.test.sh
git commit -m "feat: add make-based bundle workflow"
```

### Task 4: Rewrite the docs around the wmfox bundle workflow

**Files:**
- Modify: `README.md`
- Modify: `tests/readme.test.sh`

**Interfaces:**
- Consumes:
  - `make build`
  - `make run`
  - `make install`
  - `make test`
- Produces:
  - `README.md` — Makefile-first usage guide for the wmfox-based bundle
  - `tests/readme.test.sh` — exact assertions guarding the documented commands and manual verification checklist

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

grep -Fq 'make build' "$repo_root/README.md"
grep -Fq 'make run' "$repo_root/README.md"
grep -Fq 'make install' "$repo_root/README.md"
grep -Fq 'make test' "$repo_root/README.md"
grep -Fq 'wmfox' "$repo_root/README.md"
grep -Fq 'IBM Plex Mono' "$repo_root/README.md"
grep -Fq 'bottom-mounted chrome' "$repo_root/README.md"
grep -Fq 'about:policies' "$repo_root/README.md"
grep -Fq 'Press `?` and confirm Vimium C help opens.' "$repo_root/README.md"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/readme.test.sh`
Expected: FAIL because the old README still documents script-first commands and lacks the new wmfox/Makefile wording

- [ ] **Step 3: Write minimal implementation**

`README.md`

````markdown
# Firefox Minimal Prototype

Linux-only prototype that bundles official Firefox, uses an isolated profile, installs Vimium C from a generated enterprise policy, and ships a pinned upstream wmfox theme snapshot.

## Requirements

- `make`, `curl`, `tar`, and `xz`
- network access during `make build`
- optional: IBM Plex Mono installed locally if you want wmfox's preferred font instead of Firefox's fallback font

## Build

```bash
make build
```

The built app is written to `dist/firefox-minimal/`.

## Run

```bash
make run
```

To pass a starting URL or other launcher arguments, use `RUN_ARGS`:

```bash
make run RUN_ARGS='https://example.com'
```

## Install

```bash
make install
```

The default install location is `~/.local/firefox-minimal`. Override it with `INSTALL_DIR`:

```bash
make install INSTALL_DIR="$HOME/apps/firefox-minimal"
```

## Test

```bash
make test
```

## What the prototype changes

- wmfox is used as the browser theme from a pinned upstream snapshot.
- Vimium C is installed and locked by `firefox/distribution/policies.json`.
- The bundled profile enables the wmfox-compatible Firefox prefs required by this prototype.
- The browser chrome follows wmfox, including bottom-mounted chrome and wmfox tab/urlbar behavior.

## Manual verification

1. Run `make build`.
2. Run `make run RUN_ARGS='https://example.com'`.
3. Open `about:policies` and confirm the extension install policy is active.
4. Open `about:addons` and confirm Vimium C is installed and locked.
5. Confirm the browser chrome is bottom-mounted and follows wmfox styling.
6. Confirm the tab strip and URL bar follow wmfox behavior instead of the old favicon-only custom theme.
7. If Firefox still shows a toolbar control that wmfox expects you to remove manually, use Customize Toolbar once and keep using the bundled profile afterward.
8. Press `?` and confirm Vimium C help opens.
````

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/readme.test.sh && echo PASS`
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add README.md tests/readme.test.sh
git commit -m "docs: document wmfox bundle workflow"
```

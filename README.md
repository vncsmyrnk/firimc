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

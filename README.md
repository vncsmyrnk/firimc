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

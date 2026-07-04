# wmfox Bundled Theme Design

## Summary

Evolve this repository from a prototype with a small hand-written Firefox UI override into an isolated bundled Firefox distribution that ships the upstream **wmfox** theme as its presentation layer. The repository continues to bundle official Firefox and Vimium C in a relocatable app directory, but the user-facing workflow moves to a Makefile and the built `dist/firefox-minimal/` tree becomes the fully configured final artifact.

## Goals

1. Keep the project as an isolated bundled Firefox prototype rather than modifying the user's installed Firefox.
2. Replace the repo's current custom `userChrome.css` behavior with a pinned upstream **wmfox** snapshot.
3. Avoid repo-specific UI redesign layered on top of wmfox; keep local configuration limited to bundle glue and Firefox prefs needed to enable wmfox in the isolated profile.
4. Expose the supported workflow through `make build`, `make run`, `make install`, and `make test`.
5. Ensure the final built or installed bundle already contains the opinionated configuration that defines the prototype.

## Non-Goals

1. Applying wmfox to the user's existing system Firefox profile.
2. Adding a user-facing theme update workflow such as `make update-theme`.
3. Introducing extra local UI tweaks beyond wmfox except where Firefox requires non-theme glue such as prefs or existing bundle-launch wiring.
4. Turning the project into an OS-specific package format such as `.deb` or `.rpm`.

## Product Shape

The project remains a bundle-oriented prototype:

- `scripts/build-prototype.sh` assembles `dist/firefox-minimal/`
- `scripts/launch-prototype.sh` launches the bundled Firefox with an isolated profile
- Firefox enterprise policies continue to install and lock Vimium C from the bundled XPI

The important change is the contract of the built artifact: `dist/firefox-minimal/` is the complete, opinionated browser distribution, not a partial scaffold that expects the user to apply theme steps afterward.

## Theme Source of Truth

The repository vendors a pinned upstream wmfox snapshot under `vendor/wmfox/`. That directory contains:

- upstream `userChrome.css`
- the upstream license text
- `SOURCE.md`, a short local provenance note naming the upstream repository URL and pinned commit

The vendored `userChrome.css` is treated as upstream content. Local development should replace it wholesale when updating wmfox rather than editing it in place.

## Bundle Assembly Design

`scripts/build-prototype.sh` continues to download official Firefox and the Vimium C XPI, then assembles the app tree. During assembly it also:

1. creates the built profile directory
2. copies the repo-owned profile prefs file into the built profile
3. creates `profile/chrome/` inside the built profile
4. copies `vendor/wmfox/userChrome.css` into `profile/chrome/userChrome.css`
5. installs the launcher into the app root

The source-of-truth profile prefs remain repo-owned because they are bundle glue, not upstream theme content.

## Profile Configuration

`prototype/profile/user.js` is reduced to the minimum Firefox prefs needed to make the bundled profile behave like the intended wmfox prototype:

- `toolkit.legacyUserProfileCustomizations.stylesheets = true`
- `browser.compactmode.show = true`
- `browser.uidensity = 1`

This design does not add any other automatic UI-pref changes. If a desired toolbar customization is not stable or not expressible through prefs, it is documented as a manual follow-up step instead of adding repo-specific theme logic.

## Makefile Workflow

The Makefile becomes the supported entrypoint for the repository.

### Required targets

- `make build` — build `dist/firefox-minimal/`
- `make run` — launch the bundled browser from `dist/firefox-minimal/`
- `make install` — copy the fully built bundle into an install directory
- `make test` — run the repository test suite

### Install behavior

`make install` copies the already-built bundle into a non-root install location. The install location is controlled by `INSTALL_DIR`, with a documented default of `$(HOME)/.local/firefox-minimal`.

Install behavior should be simple and reproducible:

1. `make install` depends on `make build`
2. any existing install directory at `$(INSTALL_DIR)` is replaced
3. the installed result remains runnable in place through its bundled `launch.sh`

The Makefile is the public interface; the existing shell scripts remain the implementation layer underneath it.

## Launch Behavior

`scripts/launch-prototype.sh` keeps its current responsibilities:

- generate `firefox/distribution/policies.json` inside the built bundle
- point the extension install policy at the bundled Vimium C XPI
- launch the bundled Firefox with `--no-remote --profile`

No theme-specific behavior belongs in the launcher. The launcher is responsible only for bundle startup and extension policy generation.

## Manual Setup Policy

The bundle should preconfigure everything that Firefox exposes safely through profile prefs. Documentation should mention manual toolbar adjustments only if Firefox leaves a wmfox prerequisite outside stable pref control.

That keeps the implementation aligned with two constraints:

1. the final dist should bundle the project’s opinionated configuration
2. the repo should avoid adding local theme behavior that goes beyond upstream wmfox

## Testing Strategy

Tests should verify the bundle that gets produced, not just the source files.

### Automated coverage

1. profile/theme tests assert that the build uses vendored wmfox CSS rather than the old repo-specific minimalist selectors
2. build tests assert the built app contains Firefox, Vimium C, `launch.sh`, `user.js`, and wmfox `userChrome.css`
3. launch tests continue to verify generated policy output and launch argv
4. Makefile-oriented tests verify the supported workflow targets behave as documented
5. install tests verify `make install` copies a runnable fully configured bundle into a target directory without requiring root

### Manual verification

The README checklist should validate wmfox-oriented outcomes rather than the old custom theme behavior. The checklist should cover:

- building through `make build`
- launching through `make run` or the installed bundle
- confirming Vimium policy/installation remains active
- confirming the browser chrome matches wmfox expectations such as bottom-mounted chrome and wmfox tab/urlbar behavior
- confirming any remaining manual toolbar tweak only if the implementation cannot preconfigure it through prefs

## Documentation Changes

`README.md` becomes Makefile-first documentation:

- build instructions use `make build`
- run instructions use `make run`
- install instructions use `make install`
- test instructions use `make test`
- the theme description explains that the prototype uses a pinned upstream wmfox snapshot
- any font or toolbar caveats inherited from wmfox are documented explicitly

## Acceptance Criteria

The design is satisfied when all of the following are true:

1. the repository still builds an isolated bundled Firefox distribution
2. the built bundle ships upstream wmfox as its theme layer
3. the old repo-specific minimalist theme behavior is removed from the product contract and documentation
4. Makefile targets are the supported way to build, run, install, and test the prototype
5. the installed bundle is just a copied fully configured dist, not a second configuration flow

# Aster Upstream And Release Flow

Aster should be maintained as a small patch stack on top of official
`openai/codex` Rust release tags.

As of 2026-04-27, the official stable release is `rust-v0.125.0`. The newest
pre-release observed at the same time is `rust-v0.126.0-alpha.4`.

## Desired Repository Shape

The maintainable shape is:

```text
openai/codex rust-v0.125.0  ── Aster white-label commits      main
openai/codex rust-v0.126.0  ── same Aster commits rebased     sync PR
```

This shape keeps the official upstream history. Future updates are normal
`git rebase --onto` / `git cherry-pick` work.

## Current Baseline

Current `main` starts from official `rust-v0.125.0`:

```text
upstream-rust-v0.125.0  ->  Aster commits  ->  main
```

Treat `rust-v0.125.0` as Aster's current maintained baseline. There is no need
to preserve or release previous Aster history.

## Tracking State

The tracking state lives in `ASTER_UPSTREAM_TRACKING.env`.

On the upstream-history branch, it should say:

```text
ASTER_LAST_SYNCED_UPSTREAM_TAG=rust-v0.125.0
ASTER_PATCH_BASE_REF=upstream-rust-v0.125.0
ASTER_NEXT_RELEASE_TAG=aster-v0.125.0
```

## Local Commands

Fetch the latest stable upstream tag without changing files:

```bash
./scripts/aster-sync-upstream --target latest-stable --fetch-only
```

Resolve the latest stable tag only:

```bash
./scripts/aster-sync-upstream --target latest-stable --print-tag
```

Check that model-facing internals still match the upstream release tag:

```bash
./scripts/aster-check-white-label-boundary --base-ref upstream-rust-v0.125.0
```

Prepare a future sync branch:

```bash
./scripts/aster-sync-upstream \
  --target rust-v0.126.0 \
  --base-tag rust-v0.125.0 \
  --source-ref main \
  --create-branch
```

If rebase conflicts occur, resolve them as normal Git conflicts, then run:

```bash
git rebase --continue
```

After the sync branch is merged, create the matching Aster tag:

```bash
git tag -a aster-v0.126.0 -m "Aster 0.126.0"
git push origin main aster-v0.126.0
```

Pushing the `aster-vX.Y.Z` tag triggers the Aster GitHub release workflow.

## GitHub Actions

Use these Aster-specific workflows:

- `.github/workflows/aster-upstream-sync.yml`: manually creates an upstream sync
  pull request by rebasing the Aster patch stack onto an official Rust tag.
- `.github/workflows/aster-linux-package.yml`: manually builds a Linux artifact
  without publishing a release.
- `.github/workflows/aster-release.yml`: publishes Linux and macOS GitHub
  Release assets from an `aster-v*.*.*` tag, or from a manual dispatch pointing
  at such a tag.

Do not use the upstream `rust-release*` workflows for Aster releases unless they
are intentionally white-labeled first.

## What Should Stay As Codex

For easier upstream tracking, keep internal Rust crate names such as
`codex-core` and `codex-tui`. Model IDs such as `gpt-5.2-codex` are also upstream
identifiers and should not be renamed as part of the white-label patch.

Keep model prompt templates and protocol base instructions upstream as well.
Examples include `codex-rs/core/gpt*_prompt.md` and
`codex-rs/protocol/src/prompts/base_instructions/default.md`. Those files define
the model-facing identity/context and are not part of the Aster runtime/process
branding surface.

The sync and release workflows run `scripts/aster-check-white-label-boundary` to
enforce this. If it fails after an upstream rebase, restore the listed files from
the matching `upstream-rust-v*` tag instead of white-labeling them.

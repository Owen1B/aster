# Aster Upstream And Release Flow

This repository keeps Aster as a small white-label patch set on top of official
`openai/codex` Rust release snapshots.

As of 2026-04-22, the official stable release is `rust-v0.122.0`. The newest
pre-release observed at the same time is `rust-v0.123.0-alpha.7`.

## Why This Flow

This repository uses snapshot-style history, not a normal fork history with a
merge-base against `openai/codex`. Do not rely on `git rebase upstream/main` as
the primary update path.

Instead, the fixed process is:

1. Fetch the official Rust release tag from `openai/codex`.
2. Replace the current source tree with that upstream tag.
3. Replay the Aster white-label diff from the previous Aster release tag.
4. Review conflicts and the final diff.
5. Commit the sync PR.
6. Tag the merged result with `aster-vX.Y.Z` to publish a GitHub release.

## Current Tracking State

The current local source snapshot is still based on `rust-v0.120.0` / `aster-v0.120.0`.
The latest fetched stable upstream tag is `rust-v0.122.0`.

The tracking state lives in `ASTER_UPSTREAM_TRACKING.env`.

## Local Commands

Fetch the latest stable upstream tag without changing files:

```bash
./scripts/aster-sync-upstream --target latest-stable --fetch-only
```

Resolve the latest stable tag only:

```bash
./scripts/aster-sync-upstream --target latest-stable --print-tag
```

Prepare a local sync branch after your current Aster patch is committed:

```bash
git switch -c zhw_dev/aster-sync-0.122.0 main
./scripts/aster-sync-upstream \
  --target rust-v0.122.0 \
  --base-ref aster-v0.120.0 \
  --source-ref HEAD \
  --update-worktree

git status
git diff --cached --stat
git commit -m "Sync Aster with upstream rust-v0.122.0"
```

If the sync is accepted and merged, create the matching Aster tag:

```bash
git tag -a aster-v0.122.0 -m "Aster 0.122.0"
git push origin main aster-v0.122.0
```

Pushing the `aster-v0.122.0` tag triggers the Aster GitHub release workflow.

## GitHub Actions

Use these Aster-specific workflows:

- `.github/workflows/aster-upstream-sync.yml`: manually creates an upstream sync
  pull request by replaying the Aster patch onto an official Rust tag.
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

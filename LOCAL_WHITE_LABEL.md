# Local White-Label Notes

This checkout is prepared as an isolated local white-label build named `Aster`.

## Isolation

- Existing `codex` installs are not replaced or modified.
- The compiled binary is named `aster`.
- The default local home/config directory is `~/.aster`.
- The wrapper launcher is `scripts/aster`.

## Fast start

```bash
cd codex-rs
cargo build --release --bin aster
../scripts/aster
```

Or just use the wrapper:

```bash
./scripts/aster
```

The wrapper will:

- build `aster` automatically if needed
- default `ASTER_HOME` to `~/.aster`
- map `CODEX_HOME` to `ASTER_HOME` only for the `aster` process

## Environment

- `ASTER_HOME`: preferred home/config directory for your white-label build
- `CODEX_HOME`: internal compatibility variable used by upstream code. The
  `scripts/aster` launcher maps it to `ASTER_HOME` for the Aster process.
- `ASTER_BIN`: optional path override for the compiled `aster` binary
- `CARGO_BIN`: optional path override for `cargo`
- `ASTER_ENABLE_UPSTREAM_UPDATE_CHECK`: opt in to upstream Codex npm/Homebrew
  update hints. Disabled by default for Aster.
- `ASTER_ENABLE_UPSTREAM_ANNOUNCEMENTS`: opt in to upstream Codex announcement
  tips. Disabled by default for Aster.

## GitHub builds

Use the Aster-specific workflows for GitHub builds:

- `.github/workflows/aster-upstream-sync.yml`
- `.github/workflows/aster-linux-package.yml`
- `.github/workflows/aster-release.yml`

The release workflow publishes Linux x86_64 GNU and macOS universal Apple
Darwin assets into the same GitHub Release.

The upstream `rust-release*` workflows and npm packaging scripts still follow
the official Codex release layout. Do not use those workflows for Aster releases
unless they are intentionally white-labeled first.

See `docs/aster-upstream-release.md` for the fixed upstream tracking and release
process.

## Relay mode

If you use your own OpenAI-compatible relay, point Aster at it with a custom provider in `~/.aster/config.toml`:

```toml
[model_providers.relay]
name = "My Relay"
base_url = "https://your-relay.example.com/v1"
env_key = "RELAY_API_KEY"
wire_api = "responses"

[profiles.relay]
model_provider = "relay"
model = "gpt-5"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
```

Then run:

```bash
export RELAY_API_KEY="your-token"
./scripts/aster --profile relay
```

Using a relay/API-key profile avoids the official ChatGPT login flow and keeps the runtime branding cleaner.

## Limits

This local white-label pass focuses on user-visible branding. Internal crate
names, model IDs, npm package metadata, and some upstream URLs still reference
`codex`.

## Tracking upstream

This fork should keep OpenAI's repository as a Git remote:

```bash
git remote add upstream https://github.com/openai/codex.git
git fetch upstream main --tags
```

The current source snapshot is based on official `rust-v0.120.0`, with a small
Aster patch set layered on top. For future updates, prefer replaying the Aster
patch set onto a fresh upstream tag or `upstream/main` rather than renaming
internal crates wholesale. Keeping internal crate/module names such as
`codex-core` and `codex-tui` minimizes merge conflicts with official updates.

Use `scripts/aster-sync-upstream` to fetch the latest official release and, when
the worktree is clean, replay the Aster patch onto a new upstream Rust tag.

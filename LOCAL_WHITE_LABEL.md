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

This local white-label pass focuses on runtime/user-visible branding. Internal
crate names, model IDs, model prompt templates, protocol base instructions, npm
package metadata, and some upstream URLs still reference `codex`.

Do not mechanically replace `codex` inside files that define model identity,
model IDs, or prompt text sent to the model. The Aster patch should change the
binary/process/config/docs surface, not the model's upstream identity.

Run `scripts/aster-check-white-label-boundary --base-ref upstream-rust-vX.Y.Z`
before release if you edit branding manually. The GitHub sync and release
workflows run this check automatically.

## Tracking upstream

This fork should keep OpenAI's repository as a Git remote:

```bash
git remote add upstream https://github.com/openai/codex.git
git fetch upstream main --tags
```

Current `main` starts from official `rust-v0.122.0` and applies the Aster
white-label patch stack on top:

- `upstream-rust-v0.122.0`
- Aster white-label/runtime/release commits
- `main`

Future updates should use `scripts/aster-sync-upstream` to rebase the Aster patch
stack from the last official Rust tag to the next one. Keeping internal
crate/module names such as `codex-core` and `codex-tui` minimizes merge conflicts
with official updates.

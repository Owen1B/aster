# Aster CLI

Aster is a white-label build of the OpenAI Codex CLI source tree. This repository
keeps the runtime name, binary name, config home, and user-facing copy branded as
`Aster`, while preserving upstream internal crate/module names where that makes
future `openai/codex` updates easier to replay.

This is not the official OpenAI Codex distribution. If you want the upstream
product, use <https://github.com/openai/codex>. If you want this fork, install
and configure `aster` as described below.

## What Is Different

- The CLI binary is `aster`.
- The default config directory is `~/.aster`.
- The main config file is `~/.aster/config.toml`.
- The launcher is `scripts/aster` when running from a source checkout.
- Official Codex npm/Homebrew update prompts are disabled by default.
- Official Codex Desktop integration is disabled in this white-label build.
- Internal Rust crates such as `codex-core` intentionally keep upstream names to
  reduce merge conflicts when tracking official releases.

## Install From GitHub Release

Current release assets are produced by this fork's GitHub Actions, not by the
official Codex npm package or Homebrew cask.

Linux x86_64 GNU example:

```bash
VERSION=0.120.0 # replace with the version from the latest aster-v* release
curl -LO "https://github.com/Owen1B/aster/releases/download/aster-v${VERSION}/aster-${VERSION}-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf "aster-${VERSION}-x86_64-unknown-linux-gnu.tar.gz"
sudo install -m 755 "aster-${VERSION}-x86_64-unknown-linux-gnu/aster" /usr/local/bin/aster
aster --help
```

macOS universal Apple Darwin example:

```bash
VERSION=0.120.0 # replace with the version from the latest aster-v* release
curl -LO "https://github.com/Owen1B/aster/releases/download/aster-v${VERSION}/aster-${VERSION}-universal-apple-darwin.tar.gz"
tar -xzf "aster-${VERSION}-universal-apple-darwin.tar.gz"
sudo install -m 755 "aster-${VERSION}-universal-apple-darwin/aster" /usr/local/bin/aster
aster --help
```

Use the newest `aster-v*` tag from the repository Releases page and replace
`VERSION` accordingly. The archive contains the `aster` executable and white-label
notes.

The macOS archive is unsigned and not notarized. If macOS blocks a manually
downloaded binary, verify the checksum first and then remove the quarantine flag:

```bash
xattr -d com.apple.quarantine /usr/local/bin/aster
```

For other targets, either add a matching GitHub workflow or build from source.
Do not install `@openai/codex` or `brew install --cask codex` if your goal is to
run Aster; those install the official Codex distribution.

## Run From Source Checkout

The source launcher keeps the Aster config isolated from any existing Codex
installation:

```bash
./scripts/aster
```

The launcher will:

- default `ASTER_HOME` to `~/.aster`
- create the config directory if it does not exist
- map the upstream compatibility variable `CODEX_HOME` to `ASTER_HOME` only for
  the launched Aster process
- build `codex-rs/target/release/aster` if no binary is present

If you already have a built binary, point the launcher at it:

```bash
ASTER_BIN=/path/to/aster ./scripts/aster
```

## Config Path

Aster reads user configuration from:

```text
~/.aster/config.toml
```

To use a different config home:

```bash
export ASTER_HOME="$HOME/.config/aster"
aster
```

`CODEX_HOME` remains an internal compatibility fallback for upstream code, but
normal Aster usage should prefer `ASTER_HOME`.

## Basic Config Example

Create `~/.aster/config.toml`:

```toml
model = "gpt-5"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
```

Common values:

- `approval_policy = "on-request"`: ask before commands that need approval.
- `approval_policy = "never"`: do not ask for approvals.
- `sandbox_mode = "workspace-write"`: allow edits in the current workspace.
- `sandbox_mode = "read-only"`: read-only mode.
- `sandbox_mode = "danger-full-access"`: no filesystem sandboxing.

## OpenAI-Compatible Relay Config

If you use a relay or an OpenAI-compatible endpoint, configure a custom provider
and profile in `~/.aster/config.toml`:

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

Run it with:

```bash
export RELAY_API_KEY="your-token"
aster --profile relay
```

You can also use the source launcher:

```bash
export RELAY_API_KEY="your-token"
./scripts/aster --profile relay
```

## Direct OpenAI API Key Config

If you want to use the OpenAI API-compatible provider directly, one practical
pattern is to define an explicit provider and profile:

```toml
[model_providers.openai-api]
name = "OpenAI API"
base_url = "https://api.openai.com/v1"
env_key = "OPENAI_API_KEY"
wire_api = "responses"

[profiles.openai-api]
model_provider = "openai-api"
model = "gpt-5"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
```

Then run:

```bash
export OPENAI_API_KEY="sk-..."
aster --profile openai-api
```

## MCP Server Config

MCP servers are configured in `~/.aster/config.toml` under `mcp_servers`.
Example:

```toml
[mcp_servers.files]
command = "node"
args = ["/absolute/path/to/server.js"]

[mcp_servers.files.tools.search]
approval_mode = "approve"
```

From the CLI, use the Aster command name:

```bash
aster mcp --help
```

## Useful Environment Variables

- `ASTER_HOME`: preferred Aster config/state directory. Defaults to `~/.aster`.
- `ASTER_BIN`: source launcher binary override.
- `CARGO_BIN`: source launcher cargo override.
- `ASTER_ENABLE_UPSTREAM_UPDATE_CHECK`: opt in to official Codex npm/Homebrew
  update checks. Disabled by default.
- `ASTER_ENABLE_UPSTREAM_ANNOUNCEMENTS`: opt in to official Codex announcement
  tips. Disabled by default.

## Upstream Tracking

Aster tracks official Codex releases as a small white-label patch set. The fixed
process is documented in [`docs/aster-upstream-release.md`](docs/aster-upstream-release.md).

Quick checks:

```bash
./scripts/aster-sync-upstream --target latest-stable --fetch-only
./scripts/aster-sync-upstream --target latest-stable --print-tag
```

The GitHub workflow `.github/workflows/aster-upstream-sync.yml` can create a PR
that replays the Aster patch onto a selected official `rust-v*` tag. After that
PR is merged, pushing an `aster-vX.Y.Z` tag triggers
`.github/workflows/aster-release.yml` and publishes Linux plus macOS assets in
one GitHub Release.

## Project Notes

- See [`LOCAL_WHITE_LABEL.md`](LOCAL_WHITE_LABEL.md) for implementation notes and
  white-label boundaries.
- See [`ASTER_UPSTREAM_TRACKING.env`](ASTER_UPSTREAM_TRACKING.env) for the current
  upstream tracking state.
- See [`LICENSE`](LICENSE) for licensing.

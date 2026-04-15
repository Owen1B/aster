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
- `ASTER_BIN`: optional path override for the compiled `aster` binary
- `CARGO_BIN`: optional path override for `cargo`

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

This local white-label pass focuses on user-visible branding. Internal crate names and some upstream URLs still reference `codex`.

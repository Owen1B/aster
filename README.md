# Aster CLI

Aster 是基于 OpenAI Codex CLI 源码树维护的白标构建。本仓库把运行时名称、命令名、配置目录和面向用户的说明改为 `Aster`，同时尽量保留上游内部 crate、模块、模型 ID 和模型提示词，以便后续持续跟踪 `openai/codex` 官方更新。

这不是 OpenAI 官方 Codex 发行版。如果你要使用官方版本，请看 <https://github.com/openai/codex>。如果你要使用本仓库的 Aster，请按下面的方式安装和配置 `aster`。

## 和官方 Codex 的区别

- CLI 命令名是 `aster`。
- 默认配置目录是 `~/.aster`。
- 主配置文件是 `~/.aster/config.toml`。
- 从源码目录运行时使用 `scripts/aster`。
- 官方 Codex 的 npm/Homebrew 更新提示默认关闭。
- 官方 Codex Desktop 集成在这个白标构建中默认关闭。
- 内部 Rust crate 名称，例如 `codex-core`，会继续保持上游名称，减少以后同步官方仓库时的冲突。
- 模型 ID、模型元数据、模型提示词和发给模型的 base instructions 保持和上游 Codex 一致。Aster 的改名范围是运行时/产品表面，不改模型内部身份。

## 从 GitHub Release 安装

本仓库的发布产物由 GitHub Actions 构建，不使用官方 Codex 的 npm 包或 Homebrew cask。

Linux x86_64 GNU 示例：

```bash
VERSION=0.122.0 # 按仓库 Releases 页面最新的 aster-v* 版本替换
curl -LO "https://github.com/Owen1B/aster/releases/download/aster-v${VERSION}/aster-${VERSION}-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf "aster-${VERSION}-x86_64-unknown-linux-gnu.tar.gz"
sudo install -m 755 "aster-${VERSION}-x86_64-unknown-linux-gnu/aster" /usr/local/bin/aster
aster --help
```

macOS universal Apple Darwin 示例：

```bash
VERSION=0.122.0 # 按仓库 Releases 页面最新的 aster-v* 版本替换
curl -LO "https://github.com/Owen1B/aster/releases/download/aster-v${VERSION}/aster-${VERSION}-universal-apple-darwin.tar.gz"
tar -xzf "aster-${VERSION}-universal-apple-darwin.tar.gz"
sudo install -m 755 "aster-${VERSION}-universal-apple-darwin/aster" /usr/local/bin/aster
aster --help
```

请以仓库 Releases 页面里的最新 `aster-v*` 标签为准，并相应替换 `VERSION`。压缩包里包含 `aster` 可执行文件和白标说明文件。

macOS 产物未签名、未 notarize。如果 macOS 阻止手动下载的二进制运行，请先校验 checksum，再移除 quarantine 标记：

```bash
xattr -d com.apple.quarantine /usr/local/bin/aster
```

如果你的目标是使用 Aster，不要安装 `@openai/codex`，也不要运行 `brew install --cask codex`。这些会安装官方 Codex 发行版，而不是本仓库的 Aster。

## 从源码目录运行

正常使用建议直接下载 GitHub Release，不需要本地编译。源码目录里的启动脚本主要用于本地调试或开发，它会把 Aster 的配置和现有 Codex 安装隔离开：

```bash
./scripts/aster
```

启动脚本会做这些事：

- 如果没有设置 `ASTER_HOME`，默认使用 `~/.aster`。
- 如果配置目录不存在，会自动创建。
- 只在启动的 Aster 进程内，把上游兼容变量 `CODEX_HOME` 映射到 `ASTER_HOME`。
- 如果没有找到现成二进制，会尝试构建 `codex-rs/target/release/aster`。

如果你已经有构建好的二进制，可以显式指定：

```bash
ASTER_BIN=/path/to/aster ./scripts/aster
```

## 配置文件路径

Aster 默认读取这个配置文件：

```text
~/.aster/config.toml
```

如果你想使用别的配置目录：

```bash
export ASTER_HOME="$HOME/.config/aster"
aster
```

`CODEX_HOME` 仍然作为上游代码兼容用的 fallback 存在，但正常使用 Aster 时应优先使用 `ASTER_HOME`。

## 基础配置示例

创建 `~/.aster/config.toml`：

```toml
model = "gpt-5"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
```

常用配置含义：

- `approval_policy = "on-request"`：需要提权或额外权限的命令会先询问。
- `approval_policy = "never"`：不请求审批。
- `sandbox_mode = "workspace-write"`：允许修改当前 workspace。
- `sandbox_mode = "read-only"`：只读模式。
- `sandbox_mode = "danger-full-access"`：不启用文件系统沙箱。

## OpenAI 兼容中转配置

如果你使用自建 relay 或其他 OpenAI 兼容 endpoint，可以在 `~/.aster/config.toml` 里配置自定义 provider 和 profile：

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

运行方式：

```bash
export RELAY_API_KEY="your-token"
aster --profile relay
```

源码目录里也可以这样运行：

```bash
export RELAY_API_KEY="your-token"
./scripts/aster --profile relay
```

## 直接使用 OpenAI API Key

如果你想直接使用 OpenAI API 兼容 provider，一个清晰的做法是显式定义 provider 和 profile：

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

运行方式：

```bash
export OPENAI_API_KEY="sk-..."
aster --profile openai-api
```

## MCP Server 配置

MCP server 在 `~/.aster/config.toml` 的 `mcp_servers` 下配置。示例：

```toml
[mcp_servers.files]
command = "node"
args = ["/absolute/path/to/server.js"]

[mcp_servers.files.tools.search]
approval_mode = "approve"
```

查看 MCP 相关命令：

```bash
aster mcp --help
```

## 常用环境变量

- `ASTER_HOME`：Aster 配置和状态目录，默认是 `~/.aster`。
- `ASTER_BIN`：源码启动脚本使用的二进制路径覆盖。
- `CARGO_BIN`：源码启动脚本使用的 Cargo 路径覆盖。
- `ASTER_ENABLE_UPSTREAM_UPDATE_CHECK`：是否启用官方 Codex npm/Homebrew 更新检查，默认关闭。
- `ASTER_ENABLE_UPSTREAM_ANNOUNCEMENTS`：是否启用官方 Codex 公告提示，默认关闭。

## 跟踪上游

Aster 按“小补丁栈”的方式跟踪官方 Codex release：上游 `rust-v*` 标签作为基底，Aster 只在上面保留白标、发布和维护脚本相关改动。固定流程见 [`docs/aster-upstream-release.md`](docs/aster-upstream-release.md)。

当前已经准备好的上游历史迁移分支是：

```text
zhw_dev/aster-upstream-0.122
```

这个分支用于替换旧的 snapshot 风格 `main`。

常用检查命令：

```bash
./scripts/aster-sync-upstream --target latest-stable --fetch-only
./scripts/aster-sync-upstream --target latest-stable --print-tag
./scripts/aster-check-white-label-boundary --base-ref upstream-rust-v0.122.0
```

`.github/workflows/aster-upstream-sync.yml` 可以创建同步上游的 PR：它会把 Aster 补丁栈 rebase 到指定官方 `rust-v*` 标签上。PR 合并后，推送 `aster-vX.Y.Z` 标签会触发 `.github/workflows/aster-release.yml`，并在同一个 GitHub Release 中发布 Linux 和 macOS 两个版本。

## 项目说明

- [`LOCAL_WHITE_LABEL.md`](LOCAL_WHITE_LABEL.md)：白标边界和实现说明。
- [`ASTER_UPSTREAM_TRACKING.env`](ASTER_UPSTREAM_TRACKING.env)：当前跟踪的上游版本状态。
- [`LICENSE`](LICENSE)：许可证信息。

#!/bin/sh

set -eu

RELEASE="latest"
ASTER_REPO="${ASTER_REPO:-Owen1B/aster}"
BIN_DIR="${ASTER_INSTALL_DIR:-$HOME/.local/bin}"
BIN_PATH="$BIN_DIR/aster"
ASTER_HOME_DIR="${ASTER_HOME:-$HOME/.aster}"
STANDALONE_ROOT="$ASTER_HOME_DIR/packages/standalone"
RELEASES_DIR="$STANDALONE_ROOT/releases"
CURRENT_LINK="$STANDALONE_ROOT/current"
LOCK_DIR="$STANDALONE_ROOT/install.lock.d"
LOCK_STALE_AFTER_SECS=600

tmp_dir=""
path_action="already"
path_profile=""

step() {
  printf '==> %s\n' "$1"
}

warn() {
  printf 'WARNING: %s\n' "$1" >&2
}

usage() {
  cat <<EOF_USAGE
Usage: install.sh [--release VERSION]

Install Aster from GitHub Releases. VERSION may be latest, 0.122.0,
v0.122.0, or aster-v0.122.0.
EOF_USAGE
}

normalize_version() {
  case "$1" in
    "" | latest)
      printf 'latest\n'
      ;;
    aster-v*)
      printf '%s\n' "${1#aster-v}"
      ;;
    v*)
      printf '%s\n' "${1#v}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --release)
        if [ "$#" -lt 2 ]; then
          echo "--release requires a value." >&2
          exit 1
        fi
        RELEASE="$2"
        shift 2
        ;;
      --help | -h)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
}

download_file() {
  url="$1"
  output="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$output"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -q -O "$output" "$url"
    return
  fi

  echo "curl or wget is required to install Aster." >&2
  exit 1
}

download_text() {
  url="$1"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -q -O - "$url"
    return
  fi

  echo "curl or wget is required to install Aster." >&2
  exit 1
}

release_url_for_asset() {
  asset="$1"
  resolved_version="$2"

  printf 'https://github.com/%s/releases/download/aster-v%s/%s\n' \
    "$ASTER_REPO" "$resolved_version" "$asset"
}

resolve_version() {
  normalized_version="$(normalize_version "$RELEASE")"

  if [ "$normalized_version" != "latest" ]; then
    printf '%s\n' "$normalized_version"
    return
  fi

  release_json="$(download_text "https://api.github.com/repos/$ASTER_REPO/releases/latest")"
  resolved="$(printf '%s\n' "$release_json" | sed -n 's/.*"tag_name":[[:space:]]*"aster-v\([^"]*\)".*/\1/p' | head -n 1)"

  if [ -z "$resolved" ]; then
    echo "Failed to resolve the latest Aster release version." >&2
    exit 1
  fi

  printf '%s\n' "$resolved"
}

file_sha256() {
  path="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
    return
  fi

  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
    return
  fi

  if command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$path" | sed 's/^.*= //'
    return
  fi

  echo "sha256sum, shasum, or openssl is required to verify the Aster download." >&2
  exit 1
}

verify_archive_digest() {
  archive_path="$1"
  checksum_path="$2"
  expected_digest="$(awk '{print $1; exit}' "$checksum_path")"
  actual_digest="$(file_sha256 "$archive_path")"

  if [ -z "$expected_digest" ] || [ "$actual_digest" != "$expected_digest" ]; then
    echo "Downloaded Aster archive checksum did not match release metadata." >&2
    echo "expected: $expected_digest" >&2
    echo "actual:   $actual_digest" >&2
    exit 1
  fi
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "$1 is required to install Aster." >&2
    exit 1
  fi
}

pick_profile() {
  case "$os:${SHELL:-}" in
    darwin:*/zsh)
      printf '%s\n' "$HOME/.zprofile"
      ;;
    darwin:*/bash)
      printf '%s\n' "$HOME/.bash_profile"
      ;;
    linux:*/zsh)
      printf '%s\n' "$HOME/.zshrc"
      ;;
    linux:*/bash)
      printf '%s\n' "$HOME/.bashrc"
      ;;
    *)
      printf '%s\n' "$HOME/.profile"
      ;;
  esac
}

append_path_block() {
  profile="$1"
  begin_marker="$2"
  end_marker="$3"
  path_line="$4"

  {
    printf '\n%s\n' "$begin_marker"
    printf '%s\n' "$path_line"
    printf '%s\n' "$end_marker"
  } >>"$profile"
}

rewrite_path_block() {
  profile="$1"
  begin_marker="$2"
  end_marker="$3"
  path_line="$4"
  tmp_profile="$tmp_dir/profile.$$.tmp"

  awk -v begin="$begin_marker" -v end="$end_marker" -v line="$path_line" '
    BEGIN { in_block = 0; replaced = 0 }
    $0 == begin {
      if (!replaced) {
        print begin
        print line
        print end
        replaced = 1
      }
      in_block = 1
      next
    }
    in_block {
      if ($0 == end) { in_block = 0 }
      next
    }
    { print }
    END { if (in_block != 0) { exit 1 } }
  ' "$profile" >"$tmp_profile"
  mv "$tmp_profile" "$profile"
}

add_to_path() {
  case ":$PATH:" in
    *":$BIN_DIR:"*)
      path_action="already"
      return
      ;;
  esac

  profile="$(pick_profile)"
  path_profile="$profile"
  begin_marker="# >>> Aster installer >>>"
  end_marker="# <<< Aster installer <<<"
  path_line="export PATH=\"$BIN_DIR:\$PATH\""

  if [ -f "$profile" ] && grep -F "$begin_marker" "$profile" >/dev/null 2>&1; then
    if grep -F "$path_line" "$profile" >/dev/null 2>&1; then
      path_action="configured"
      return
    fi

    if grep -F "$end_marker" "$profile" >/dev/null 2>&1; then
      rewrite_path_block "$profile" "$begin_marker" "$end_marker" "$path_line"
      path_action="updated"
      return
    fi
  fi

  append_path_block "$profile" "$begin_marker" "$end_marker" "$path_line"
  path_action="added"
}

mkdir_lock_is_stale() {
  [ -d "$LOCK_DIR" ] || return 1

  pid="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
  started_at="$(cat "$LOCK_DIR/started_at" 2>/dev/null || true)"
  now="$(date +%s 2>/dev/null || printf '0')"

  case "$started_at" in
    ''|*[!0-9]*) started_at=0 ;;
  esac

  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    return 1
  fi

  if [ "$started_at" -eq 0 ] || [ "$now" -eq 0 ]; then
    return 0
  fi

  [ $((now - started_at)) -ge "$LOCK_STALE_AFTER_SECS" ]
}

acquire_install_lock() {
  mkdir -p "$STANDALONE_ROOT"

  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    if mkdir_lock_is_stale; then
      warn "Removing stale installer lock at $LOCK_DIR"
      rm -rf "$LOCK_DIR"
      continue
    fi
    sleep 1
  done

  printf '%s\n' "$$" >"$LOCK_DIR/pid"
  date +%s >"$LOCK_DIR/started_at" 2>/dev/null || true
}

release_install_lock() {
  rm -rf "$LOCK_DIR" 2>/dev/null || true
}

replace_path_with_symlink() {
  link_path="$1"
  link_target="$2"
  tmp_link="$3"

  rm -f "$tmp_link"
  ln -s "$link_target" "$tmp_link"

  if mv -Tf "$tmp_link" "$link_path" 2>/dev/null; then
    return
  fi

  if mv -hf "$tmp_link" "$link_path" 2>/dev/null; then
    return
  fi

  rm -f "$link_path"
  mv -f "$tmp_link" "$link_path"
}

version_from_binary() {
  aster_path="$1"

  if [ ! -x "$aster_path" ]; then
    return 1
  fi

  "$aster_path" --version 2>/dev/null | sed -n 's/.* \([0-9][0-9A-Za-z.+-]*\)$/\1/p' | head -n 1
}

current_installed_version() {
  version="$(version_from_binary "$CURRENT_LINK/aster" || true)"
  if [ -n "$version" ]; then
    printf '%s\n' "$version"
  fi
}

release_dir_is_complete() {
  release_dir="$1"
  expected_version="$2"
  expected_target="$3"

  [ -d "$release_dir" ] &&
    [ -x "$release_dir/aster" ] &&
    [ "$(basename "$release_dir")" = "$expected_version-$expected_target" ]
}

install_release() {
  release_dir="$1"
  extracted_root="$2"
  stage_release="$RELEASES_DIR/.staging.$(basename "$release_dir").$$"

  mkdir -p "$RELEASES_DIR"
  rm -rf "$stage_release"
  mkdir -p "$stage_release"
  cp "$extracted_root/aster" "$stage_release/aster"
  chmod 0755 "$stage_release/aster"

  if [ -e "$release_dir" ] || [ -L "$release_dir" ]; then
    rm -rf "$release_dir"
  fi
  mv "$stage_release" "$release_dir"
}

update_current_link() {
  release_dir="$1"
  tmp_link="$STANDALONE_ROOT/.current.$$"

  replace_path_with_symlink "$CURRENT_LINK" "$release_dir" "$tmp_link"
}

update_visible_command() {
  mkdir -p "$BIN_DIR"
  tmp_link="$BIN_DIR/.aster.$$"

  replace_path_with_symlink "$BIN_PATH" "$CURRENT_LINK/aster" "$tmp_link"
}

print_launch_instructions() {
  case "$path_action" in
    added)
      step "Current terminal: export PATH=\"$BIN_DIR:\$PATH\" && aster"
      step "Future terminals: open a new terminal and run: aster"
      step "PATH was added to $path_profile"
      ;;
    updated)
      step "Current terminal: export PATH=\"$BIN_DIR:\$PATH\" && aster"
      step "Future terminals: open a new terminal and run: aster"
      step "PATH was updated in $path_profile"
      ;;
    configured)
      step "Current terminal: export PATH=\"$BIN_DIR:\$PATH\" && aster"
      step "Future terminals: open a new terminal and run: aster"
      step "PATH is already configured in $path_profile"
      ;;
    *)
      step "Current terminal: aster"
      step "Future terminals: open a new terminal and run: aster"
      ;;
  esac
}

parse_args "$@"

require_command mktemp
require_command tar

case "$(uname -s)" in
  Darwin)
    os="darwin"
    asset_suffix="universal-apple-darwin"
    platform_label="macOS universal"
    ;;
  Linux)
    os="linux"
    case "$(uname -m)" in
      x86_64 | amd64)
        asset_suffix="x86_64-unknown-linux-gnu"
        platform_label="Linux x86_64 GNU"
        ;;
      *)
        echo "Aster currently publishes Linux x86_64 and macOS universal release assets only." >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "install.sh supports macOS and Linux." >&2
    exit 1
    ;;
esac

resolved_version="$(resolve_version)"
asset="aster-$resolved_version-$asset_suffix.tar.gz"
checksum_asset="aster-$resolved_version-$asset_suffix.sha256"
download_url="$(release_url_for_asset "$asset" "$resolved_version")"
checksum_url="$(release_url_for_asset "$checksum_asset" "$resolved_version")"
release_name="$resolved_version-$asset_suffix"
release_dir="$RELEASES_DIR/$release_name"
current_version="$(current_installed_version)"

if [ -n "$current_version" ] && [ "$current_version" != "$resolved_version" ]; then
  step "Updating Aster CLI from $current_version to $resolved_version"
elif [ -n "$current_version" ]; then
  step "Updating Aster CLI"
else
  step "Installing Aster CLI"
fi
step "Detected platform: $platform_label"
step "Resolved version: $resolved_version"

tmp_dir="$(mktemp -d)"
cleanup() {
  release_install_lock
  if [ -n "$tmp_dir" ]; then
    rm -rf "$tmp_dir"
  fi
}
trap cleanup EXIT INT TERM

acquire_install_lock

if ! release_dir_is_complete "$release_dir" "$resolved_version" "$asset_suffix"; then
  if [ -e "$release_dir" ] || [ -L "$release_dir" ]; then
    warn "Found incomplete existing release at $release_dir; reinstalling."
  fi

  archive_path="$tmp_dir/$asset"
  checksum_path="$tmp_dir/$checksum_asset"
  extract_dir="$tmp_dir/extract"
  extracted_root="$extract_dir/aster-$resolved_version-$asset_suffix"

  step "Downloading Aster CLI"
  download_file "$download_url" "$archive_path"
  download_file "$checksum_url" "$checksum_path"
  verify_archive_digest "$archive_path" "$checksum_path"

  mkdir -p "$extract_dir"
  tar -xzf "$archive_path" -C "$extract_dir"

  step "Installing standalone package to $release_dir"
  install_release "$release_dir" "$extracted_root"
fi

update_current_link "$release_dir"
update_visible_command
add_to_path
"$BIN_PATH" --version >/dev/null
release_install_lock

case "$path_action" in
  added | updated | configured)
    print_launch_instructions
    ;;
  *)
    step "$BIN_DIR is already on PATH"
    print_launch_instructions
    ;;
esac

printf 'Aster CLI %s installed successfully.\n' "$resolved_version"

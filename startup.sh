#!/usr/bin/env bash

set -euo pipefail

workspace_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
obs_project_dir="$workspace_dir/hd-obs"
web_project_dir="$workspace_dir/hd-web"
obs_plugins_dir="$HOME/Library/Application Support/obs-studio/plugins"
obs_plugin_bundle="$obs_plugins_dir/hd-obs.plugin"
obs_build_bundle="$obs_project_dir/build_macos/RelWithDebInfo/hd-obs.plugin"

ensure_obs_plugin() {
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "The OBS plugin can only be installed from macOS." >&2
    exit 1
  fi

  cd "$obs_project_dir"
  cmake --preset macos
  cmake --build --preset macos --config RelWithDebInfo

  if [[ -d "$obs_plugin_bundle" ]] && diff -qr "$obs_build_bundle" "$obs_plugin_bundle" >/dev/null; then
    echo "OBS plugin is already current."
    return
  fi

  mkdir -p "$obs_plugins_dir"
  if [[ -e "$obs_plugin_bundle" || -L "$obs_plugin_bundle" ]]; then
    rm -rf -- "$obs_plugin_bundle"
  fi

  cmake --install build_macos --config RelWithDebInfo
  echo "Installed the current OBS plugin. Fully quit and reopen OBS to load it."
}

start_web() {
  cd "$web_project_dir"
  exec npm run dev
}

ensure_clean_submodule() {
  local project_dir="$1"

  if [[ -e "$project_dir/.git" ]] && [[ -n "$(git -C "$project_dir" status --porcelain)" ]]; then
    echo "Refusing to update $project_dir because it has local changes." >&2
    exit 1
  fi
}

sync_submodules() {
  ensure_clean_submodule "$obs_project_dir"
  ensure_clean_submodule "$web_project_dir"

  git -C "$workspace_dir" submodule sync --recursive
  git -C "$workspace_dir" submodule update --init --remote --recursive
  echo "Updated submodules to their configured develop branches. Review and commit the workspace pointer changes when ready."
}

case "${1:-}" in
  obs)
    ensure_obs_plugin
    ;;
  web)
    start_web
    ;;
  sync)
    sync_submodules
    ;;
  "")
    ensure_obs_plugin
    start_web
    ;;
  *)
    echo "Usage: $0 [obs|web|sync]" >&2
    exit 64
    ;;
esac

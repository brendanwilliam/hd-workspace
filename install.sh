#!/usr/bin/env bash

set -euo pipefail

script_path="${BASH_SOURCE[0]}"
while [[ -L "$script_path" ]]; do
  script_dir="$(cd -P -- "$(dirname -- "$script_path")" && pwd)"
  script_path="$(readlink -- "$script_path")"
  [[ "$script_path" == /* ]] || script_path="$script_dir/$script_path"
done

workspace_dir="$(cd -P -- "$(dirname -- "$script_path")" && pwd)"
obs_project_dir="$workspace_dir/hd-obs"
web_project_dir="$workspace_dir/hd-web"
obs_plugins_dir="$HOME/Library/Application Support/obs-studio/plugins"
obs_plugin_bundle="$obs_plugins_dir/hd-obs.plugin"
obs_build_bundle="$obs_project_dir/build_macos/RelWithDebInfo/hd-obs.plugin"

require_project() {
  local project_dir="$1"
  local project_name="$2"

  if [[ ! -d "$project_dir" ]]; then
    echo "$project_name was not found at $project_dir. Initialize the workspace submodules first:" >&2
    echo "  git submodule update --init --recursive" >&2
    exit 1
  fi
}

configure_obs_build() {
  local cache_file="$obs_project_dir/build_macos/CMakeCache.txt"
  local cached_source_dir=""

  if [[ -f "$cache_file" ]]; then
    cached_source_dir="$(sed -n 's|^CMAKE_HOME_DIRECTORY:INTERNAL=||p' "$cache_file")"
  fi

  if [[ -n "$cached_source_dir" && "$cached_source_dir" != "$obs_project_dir" ]]; then
    echo "Refreshing the OBS build cache after the workspace moved."
    cmake --fresh --preset macos
  else
    cmake --preset macos
  fi
}

link_obs_plugin() {
  mkdir -p "$obs_plugins_dir"

  if [[ -e "$obs_plugin_bundle" && ! -L "$obs_plugin_bundle" ]]; then
    echo "Refusing to replace the existing copied OBS plugin at $obs_plugin_bundle." >&2
    echo "Move it to a timestamped backup, then run this command again to create the development symlink." >&2
    exit 1
  fi

  if [[ -L "$obs_plugin_bundle" ]]; then
    rm -- "$obs_plugin_bundle"
  fi

  ln -s "$obs_build_bundle" "$obs_plugin_bundle"
  echo "Linked OBS to the current build. Fully quit and reopen OBS to load it."
}

install_obs_plugin() {
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "Skipping hd-obs: the OBS plugin currently supports macOS only." >&2
    return
  fi

  require_project "$obs_project_dir" "hd-obs"
  cd "$obs_project_dir"
  configure_obs_build
  cmake --build --preset macos --config RelWithDebInfo

  link_obs_plugin
}

install_web() {
  require_project "$web_project_dir" "hd-web"
  cd "$web_project_dir"
  if [[ ! -f .env ]]; then
    cp .env.example .env
    echo "Created hd-web/.env from .env.example. Update its OAuth and secret values before using authentication."
  fi

  docker compose up --detach --wait db
  npm run db:migrate
  npm run build
}

case "${1:-}" in
  obs)
    install_obs_plugin
    ;;
  web)
    install_web
    ;;
  "")
    install_obs_plugin
    install_web
    ;;
  *)
    echo "Usage: $0 [obs|web]" >&2
    exit 64
    ;;
esac

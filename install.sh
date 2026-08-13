#!/usr/bin/env bash

set -euo pipefail

workspace_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
obs_project_dir="$workspace_dir/hd-obs"
web_project_dir="$workspace_dir/hd-web"
obs_plugins_dir="$HOME/Library/Application Support/obs-studio/plugins"
obs_plugin_bundle="$obs_plugins_dir/hd-obs.plugin"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "The OBS plugin can only be installed from macOS." >&2
  exit 1
fi

cd "$obs_project_dir"
cmake --preset macos
cmake --build --preset macos --config RelWithDebInfo

mkdir -p "$obs_plugins_dir"
if [[ -e "$obs_plugin_bundle" || -L "$obs_plugin_bundle" ]]; then
  rm -rf -- "$obs_plugin_bundle"
fi

cmake --install build_macos --config RelWithDebInfo

cd "$web_project_dir"
if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created hd-web/.env from .env.example. Update its OAuth and secret values before using authentication."
fi

docker compose up --detach --wait db
npm run db:migrate
npm run build

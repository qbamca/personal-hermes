#!/usr/bin/env bash
# Hermes deploy helper.
set -euo pipefail
cd "$(dirname "$0")"

usage() {
  cat <<'EOF'
Usage: ./deploy.sh [hello|build|dev|test "<prompt>"|webui|gateway]

  hello           One-shot sanity check. Builds image on first run.
  build           Build the Hermes image only.
  dev             Interactive dev shell with skills/ and skill-bundles/ mounted.
  test "<prompt>" One-shot with dev skills mounted. E.g.: ./deploy.sh test "use /my-skill"
  webui           Start web UI at http://localhost:8787 (profile webui).
  gateway         Start messaging gateway (profile gateway; Linux host network).
EOF
}

load_env() {
  if [[ -f .env ]]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
  fi
  export HERMES_UID="${HERMES_UID:-$(id -u)}"
  export HERMES_GID="${HERMES_GID:-$(id -g)}"
}

# Seed prod config — only if not already present (preserves user edits).
seed_config() {
  local dest="${HERMES_DATA_DIR:-./data/hermes}/config.yaml"
  if [[ ! -f "$dest" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp config/hermes/config.yaml "$dest"
    echo "Seeded $dest"
  fi
}

# Seed dev config — always overwrite so changes in config/hermes/dev.config.yaml take effect.
seed_dev_config() {
  local dest="${HERMES_DATA_DIR:-./data/hermes}/config.yaml"
  mkdir -p "$(dirname "$dest")"
  cp config/hermes/dev.config.yaml "$dest"
  echo "Seeded dev config → $dest"
}

cmd="${1:-hello}"
case "$cmd" in
  hello)
    load_env
    seed_config
    docker compose run --rm hello
    ;;
  build)
    load_env
    docker compose build hello
    ;;
  dev)
    load_env
    seed_dev_config
    docker compose --profile dev run --rm dev
    ;;
  test)
    if [[ -z "${2:-}" ]]; then
      echo "Usage: ./deploy.sh test \"<prompt>\"" >&2
      exit 1
    fi
    load_env
    seed_dev_config
    docker compose --profile dev run --rm dev -z "$2"
    ;;
  webui)
    load_env
    seed_config
    docker compose --profile webui up -d webui
    echo "Web UI started → http://localhost:8787"
    ;;
  gateway)
    load_env
    seed_config
    docker compose --profile gateway up -d gateway
    echo "Gateway started. Configure channels: docker compose --profile gateway run --rm gateway gateway setup"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage >&2
    exit 1
    ;;
esac

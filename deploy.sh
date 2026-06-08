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

# Seed a profile config — only if not already present (preserves user edits).
# Usage: seed_profile_config <profile_name> <dest_dir>
seed_profile_config() {
  local profile="$1" dest_dir="$2"
  mkdir -p "$dest_dir"
  for file in config.yaml .env SOUL.md profile.yaml; do
    local src="profiles/$profile/$file" dest="$dest_dir/$file"
    if [[ -f "$src" && ! -f "$dest" ]]; then
      cp "$src" "$dest"
      echo "Seeded $dest"
    fi
  done
}

seed_config()          { seed_profile_config default    "${HERMES_DATA_DIR:-./data/hermes}"; }
seed_solar_config()      { seed_profile_config solar      "${HERMES_DATA_DIR:-./data/hermes}/profiles/solar"; }
seed_igus_bot_config()   { seed_profile_config igus-bot   "${HERMES_DATA_DIR:-./data/hermes}/profiles/igus-bot"; }
seed_accountant_config() { seed_profile_config accountant "${HERMES_DATA_DIR:-./data/hermes}/profiles/accountant"; }

# Seed dev config — always overwrite so changes in config/hermes/dev.config.yaml take effect.
seed_dev_config() {
  local dest="${HERMES_DATA_DIR:-./data/hermes}/config.yaml"
  mkdir -p "$(dirname "$dest")"
  cp config/hermes/dev.config.yaml "$dest"
  echo "Seeded dev config → $dest"
}

# Wait for the gateway container to be ready and verify profile gateways are running.
# Hermes registers per-profile gateways dynamically via /run/service/ at container start;
# this function just waits and confirms.
wait_for_gateway() {
  local container="${1:-hermes-gateway}"
  echo "Waiting for $container to be ready..."
  local i=0
  until docker exec "$container" hermes gateway list &>/dev/null; do
    sleep 3; i=$((i+3))
    [[ $i -ge 60 ]] && { echo "WARNING: $container not ready after 60 s"; return; }
  done
  docker exec "$container" hermes gateway list
}

start_solar_gateway()      { wait_for_gateway; }
start_igus_bot_gateway()   { :; }
start_accountant_gateway() { :; }

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
    seed_solar_config
    seed_igus_bot_config
    seed_accountant_config
    # If growatt profile is active, require .env.growatt
    if [[ "${COMPOSE_PROFILES:-}" == *growatt* ]]; then
      if [[ ! -f .env.growatt ]]; then
        echo "ERROR: COMPOSE_PROFILES includes 'growatt' but .env.growatt is missing." >&2
        echo "       Copy .env.growatt.example to .env.growatt and set GROWATT_API_TOKEN." >&2
        exit 1
      fi
      mkdir -p "${GROWATT_AUDIT_DIR:-./data/growatt-bridge}"
      docker compose --profile gateway --profile growatt up -d gateway socket-proxy growatt-bridge
      echo "Gateway + growatt-bridge started."
      echo "Bridge health: curl http://localhost:${GROWATT_BRIDGE_PORT:-8081}/health"
    else
      docker compose --profile gateway up -d gateway socket-proxy
      echo "Gateway started. Add COMPOSE_PROFILES=growatt in .env to also start growatt-bridge."
    fi
    start_solar_gateway
    start_igus_bot_gateway
    start_accountant_gateway
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

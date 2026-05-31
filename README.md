# personal-hermes

Personal [Hermes Agent](https://github.com/NousResearch/hermes-agent) workspace — Docker-first, with a local dev environment for building and testing skills and skill bundles before shipping to prod.

## Setup

**Prerequisites:** Docker Engine 20.10+ and Compose v2 (`docker compose version`).

**Auth (one-time):** Hermes uses Codex OAuth. Since browser OAuth can't run inside a container, do this on the host first:

```bash
# Install Hermes locally (one-time)
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# Authenticate with Codex (OpenAI subscription)
hermes model
# → Select: OpenAI Codex → complete device code / browser login

# Copy credentials into the repo data dir
mkdir -p data/hermes
cp ~/.hermes/auth.json data/hermes/
```

If you already have the Codex CLI installed and logged in, you can copy from there instead:

```bash
mkdir -p data/hermes
cp ~/.codex/auth.json data/hermes/
```

Once `data/hermes/auth.json` exists, all Docker commands will use it automatically.

## Hello world

```bash
./deploy.sh hello
```

Builds the image on first run (several minutes), then prints a one-shot reply confirming auth and model.

## Developing skills

```bash
# 1. Write a skill
mkdir -p skills/my-category/my-skill
cat > skills/my-category/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: Does something useful.
platforms: [cli]
---

Do something useful here.
EOF

# 2. Start the dev shell (skills/ and skill-bundles/ are live-mounted)
./deploy.sh dev

# 3. Inside the container:
/reload-skills          # picks up your skill via external_dirs
/my-skill               # invoke it

# 4. One-shot test without entering the shell
./deploy.sh test "use /my-skill"
```

Changes to files in `skills/` are reflected immediately — no container restart needed, just `/reload-skills`.

## Commands

| Command | Description |
|---|---|
| `./deploy.sh hello` | One-shot sanity check |
| `./deploy.sh build` | Build image only |
| `./deploy.sh dev` | Interactive dev shell with skills mounted |
| `./deploy.sh test "<prompt>"` | One-shot with dev skills mounted |
| `./deploy.sh webui` | Start web UI at http://localhost:8787 |
| `./deploy.sh gateway` | Start messaging gateway (Linux; host network) |

## Repo layout

| Path | Purpose |
|---|---|
| `config/hermes/config.yaml` | Prod config (seeded to `data/hermes/` once, then user-editable) |
| `config/hermes/dev.config.yaml` | Dev config (always applied by `dev`/`test` commands) |
| `skills/` | Version-controlled custom skills (`category/name/SKILL.md`) |
| `skill-bundles/` | Version-controlled skill bundles (`name.yaml`) |
| `data/hermes/` | Runtime state — gitignored, same role as `~/.hermes` |

Upstream docs: [Quickstart](https://hermes-agent.nousresearch.com/docs/getting-started/quickstart) · [Skills](https://hermes-agent.nousresearch.com/docs/user-guide/skills) · [Configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration)

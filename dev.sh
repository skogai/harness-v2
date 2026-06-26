#!/usr/bin/env bash
set -euo pipefail

# dev.sh — clone → ./dev.sh → working app
#
# First run (~60s): uv tool install (odin/taskit-mcp), uv sync, migrate, seed agents
# After that (~3s): just starts services
#
# Requires: uv (https://docs.astral.sh/uv/)
#
# Ctrl-C stops everything.

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/taskit/taskit-backend"
FRONTEND_DIR="$ROOT_DIR/taskit/taskit-frontend"
ODIN_DIR="$ROOT_DIR/odin"
LOG_DIR="$ROOT_DIR/.dev-logs"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[dev]${NC} $*"; }
info() { echo -e "${BLUE}[dev]${NC} $*"; }

PIDS=()
cleanup() {
    echo ""
    log "Shutting down..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    wait 2>/dev/null || true
    log "Done."
}
trap cleanup EXIT INT TERM

# --- Check for .env files that override zero-config defaults ---
YELLOW='\033[1;33m'
warn() { echo -e "${YELLOW}[dev]${NC} $*"; }

env_conflicts=0
for envfile in "$BACKEND_DIR/.env" "$FRONTEND_DIR/.env"; do
    if [ -f "$envfile" ]; then
        warn "Found $(basename "$(dirname "$envfile")")/.env — its settings override dev.sh defaults."
        env_conflicts=1
    fi
done
if [ "$env_conflicts" -eq 1 ]; then
    warn "Remove .env files for zero-config dev, or keep them for custom config."
    echo ""
fi

# --- Provision (idempotent, each step skips if already done) ---

if ! command -v uv &>/dev/null; then
    echo "uv is required but not found on PATH. Install it: https://docs.astral.sh/uv/" >&2
    exit 1
fi

if ! command -v odin &>/dev/null; then
    log "Installing odin + taskit-mcp (uv tool)..."
    uv tool install "$ODIN_DIR[mcp,dev]" --quiet
fi

log "Syncing backend deps (uv)..."
(cd "$BACKEND_DIR" && uv sync --quiet)

if [ ! -d "$FRONTEND_DIR/node_modules" ]; then
    log "Installing frontend deps..."
    (cd "$FRONTEND_DIR" && npm install --silent)
fi

# Migrations — always run (fast no-op when nothing changed)
log "Checking migrations..."
(cd "$BACKEND_DIR" && uv run manage.py migrate --run-syncdb --verbosity 0)

# Seed agent users (idempotent — merges, never duplicates)
(cd "$BACKEND_DIR" && uv run manage.py seedmodels --verbosity 0) > /dev/null 2>&1 || true

# Broker dirs
mkdir -p "$BACKEND_DIR/.celery/out" "$BACKEND_DIR/.celery/processed" "$BACKEND_DIR/.celery/results"
mkdir -p "$LOG_DIR"

# --- Start ---

(cd "$BACKEND_DIR" && uv run manage.py runserver 0.0.0.0:8000) > "$LOG_DIR/backend.log" 2>&1 &
PIDS+=($!)

(cd "$FRONTEND_DIR" && npm run dev) > "$LOG_DIR/frontend.log" 2>&1 &
PIDS+=($!)

(cd "$BACKEND_DIR" && uv run celery -A config worker --beat --loglevel=info --concurrency=3 --pool=prefork) > "$LOG_DIR/celery.log" 2>&1 &
PIDS+=($!)

BOLD='\033[1m'
echo ""
echo -e "${BOLD}${GREEN}  → Open http://localhost:5173${NC}"
echo ""
info "API running on localhost:8000"
info "Ctrl-C to stop  |  Trouble? tail -f .dev-logs/backend.log"
wait

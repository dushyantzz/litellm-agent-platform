#!/usr/bin/env bash
# Usage:  source /usr/local/bin/dev-up
#         (source so exports land in the caller's shell)
#
# What it does:
#   1. Starts the local PostgreSQL cluster (no sudo needed — user owns pgdata)
#   2. Exports dev env vars for the LiteLLM proxy
#   3. Prints the one-liner to boot the proxy
#
# NOTE: set -e intentionally omitted — sourcing a script with set -e would
# exit the caller's shell on any failed command.
set -uo pipefail

PG_VERSION=$(ls /usr/lib/postgresql 2>/dev/null | sort -V | tail -1)
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"
PG_DATA="/home/user/pgdata"

if "${PG_BIN}/pg_ctl" -D "${PG_DATA}" status >/dev/null 2>&1; then
  echo "[dev-up] PostgreSQL already running."
else
  echo "[dev-up] Starting PostgreSQL ${PG_VERSION}..."
  "${PG_BIN}/pg_ctl" -D "${PG_DATA}" start -w -t 30 -l /tmp/postgres.log
  echo "[dev-up] PostgreSQL started."
fi

export DATABASE_URL="postgresql://litellm:litellm@localhost:5432/litellm"
export LITELLM_MASTER_KEY="sk-1234"
export LITELLM_SALT_KEY="sk-litellm-salt-dev-unsafe"
export STORE_MODEL_IN_DB="True"

echo ""
echo "[dev-up] Env exported:"
echo "  DATABASE_URL=${DATABASE_URL}"
echo "  LITELLM_MASTER_KEY=${LITELLM_MASTER_KEY}"
echo "  LITELLM_SALT_KEY=${LITELLM_SALT_KEY}"
echo "  STORE_MODEL_IN_DB=${STORE_MODEL_IN_DB}"
echo ""
echo "[dev-up] Boot proxy:"
echo "  cd ~/litellm && python -m litellm.proxy.proxy_cli --port 4000 --detailed_debug"

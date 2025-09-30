#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MODULE_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)
REPO_ROOT=$(cd -- "${MODULE_ROOT}/../.." && pwd)

ENV_FILE=${1:-"${REPO_ROOT}/backend/.env"}
OUTPUT_FILE=${2:-"${MODULE_ROOT}/terraform.auto.tfvars"}

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file not found: ${ENV_FILE}" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${FRONTEND_HOST:?FRONTEND_HOST must be set in ${ENV_FILE}}"
: "${API_HOST:?API_HOST must be set in ${ENV_FILE}}"
: "${POSTGRES_URL:?POSTGRES_URL must be set in ${ENV_FILE}}"
: "${POSTGRES_SERVER:?POSTGRES_SERVER must be set in ${ENV_FILE}}"
: "${POSTGRES_USER:?POSTGRES_USER must be set in ${ENV_FILE}}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD must be set in ${ENV_FILE}}"
: "${POSTGRES_DB:?POSTGRES_DB must be set in ${ENV_FILE}}"

cat >"${OUTPUT_FILE}" <<EOF
frontend_host   = "${FRONTEND_HOST}"
api_host        = "${API_HOST}"
postgres_url    = "${POSTGRES_URL}"
postgres_server = "${POSTGRES_SERVER}"
postgres_user   = "${POSTGRES_USER}"
postgres_password = "${POSTGRES_PASSWORD}"
postgres_db     = "${POSTGRES_DB}"
EOF

echo "Wrote ${OUTPUT_FILE} from ${ENV_FILE}" >&2

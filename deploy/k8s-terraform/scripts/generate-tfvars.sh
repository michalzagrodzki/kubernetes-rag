#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MODULE_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)
REPO_ROOT=$(cd -- "${MODULE_ROOT}/.." && pwd)

ENV_FILE=${1:-"${REPO_ROOT}/.env"}
OUTPUT_FILE=${2:-"${MODULE_ROOT}/terraform.auto.tfvars"}

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file not found: ${ENV_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a
source "${ENV_FILE}"
set +a

: "${FRONTEND_HOST:?FRONTEND_HOST must be set in ${ENV_FILE}}"
: "${API_HOST:?API_HOST must be set in ${ENV_FILE}}"

cat >"${OUTPUT_FILE}" <<EOF
frontend_host = "${FRONTEND_HOST}"
api_host      = "${API_HOST}"
EOF

echo "Wrote ${OUTPUT_FILE} from ${ENV_FILE}" >&2

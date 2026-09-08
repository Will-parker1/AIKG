#!/usr/bin/env bash
set -euo pipefail

### TO DEPLOY
deployment_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_root="$(cd "${deployment_dir}/.." && pwd)"

if [[ -f "${deployment_dir}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${deployment_dir}/.env"
  set +a
fi

: "${IMAGE_TAG:=dev}"
: "${IMAGE_PULL_POLICY:=Always}"
: "${K8S_NAMESPACE:=primrose}"

: "${SERVICE_TYPE:=ClusterIP}"
: "${PVC_SIZE:=2Gi}"

: "${STORAGE_CLASS:=}"


: "${MANAGE_NAMESPACE:=true}"
: "${MANAGE_PVC:=true}"
: "${MANAGE_SECRETS:=true}"
: "${MANAGE_SERVICE_ACCOUNT:=true}"


: "${REGISTRY_INSECURE:=false}"

if [[ -z "${BACKEND_IMAGE:-}" || -z "${FRONTEND_IMAGE:-}" ]]; then
  if [[ -z "${REGISTRY:-}" ]]; then
    echo "Set REGISTRY in deployment/.env (copy deployment/.env.example), or set" >&2
    echo "BACKEND_IMAGE and FRONTEND_IMAGE directly." >&2
    exit 64
  fi
fi
: "${BACKEND_IMAGE:=${REGISTRY}/primrose-backend:${IMAGE_TAG}}"
: "${FRONTEND_IMAGE:=${REGISTRY}/primrose-frontend:${IMAGE_TAG}}"

export IMAGE_TAG IMAGE_PULL_POLICY K8S_NAMESPACE SERVICE_TYPE PVC_SIZE STORAGE_CLASS
export MANAGE_NAMESPACE MANAGE_PVC MANAGE_SECRETS MANAGE_SERVICE_ACCOUNT
export BACKEND_IMAGE FRONTEND_IMAGE REGISTRY_INSECURE

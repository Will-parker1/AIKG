#!/usr/bin/env bash
# Pushes the pre-built backend/frontend images in images/ to REGISTRY. This
# folder deploys images that were already built and exported elsewhere as
# OCI-archive tarballs (e.g. `docker buildx build --output type=oci,dest=...`
# or `podman save --format oci-archive`) — it does not build them itself.
#
# Run this wherever `skopeo` is installed and already authenticated to
# REGISTRY (`docker login`, or for ECR: `aws ecr get-login-password --region
# <region> | docker login --username AWS --password-stdin
# <account>.dkr.ecr.<region>.amazonaws.com` — skopeo reads the same
# ~/.docker/config.json credentials docker login writes). Configure via
# deployment/.env (copy deployment/.env.example) or exported environment
# variables.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${script_dir}/lib/env.sh"

command -v skopeo >/dev/null || {
  echo "skopeo is required to push the OCI-archive images without a Docker build/daemon." >&2
  echo "  macOS:         brew install skopeo" >&2
  echo "  Debian/Ubuntu: apt-get install skopeo" >&2
  exit 69
}

: "${BACKEND_IMAGE_TAR:=${script_dir}/images/primrose-backend-dev-oci.tar.gz}"
: "${FRONTEND_IMAGE_TAR:=${script_dir}/images/primrose-frontend-dev-oci.tar.gz}"

for f in "${BACKEND_IMAGE_TAR}" "${FRONTEND_IMAGE_TAR}"; do
  [[ -f "${f}" ]] || {
    echo "Image archive not found: ${f}" >&2
    echo "Drop the built OCI-archive tarballs in images/, or point" >&2
    echo "BACKEND_IMAGE_TAR/FRONTEND_IMAGE_TAR (in .env or the environment) at them." >&2
    exit 1
  }
done

skopeo_flags=()
if [[ "${REGISTRY_INSECURE}" == "true" ]]; then
  skopeo_flags+=(--dest-tls-verify=false)
fi

echo "[push] backend  ${BACKEND_IMAGE_TAR} -> ${BACKEND_IMAGE}"
skopeo copy "${skopeo_flags[@]}" "oci-archive:${BACKEND_IMAGE_TAR}" "docker://${BACKEND_IMAGE}"

echo "[push] frontend ${FRONTEND_IMAGE_TAR} -> ${FRONTEND_IMAGE}"
skopeo copy "${skopeo_flags[@]}" "oci-archive:${FRONTEND_IMAGE_TAR}" "docker://${FRONTEND_IMAGE}"

cat <<EOF

Pushed:
  ${BACKEND_IMAGE}
  ${FRONTEND_IMAGE}

From inside the KASM workspace (kubectl pointed at the target cluster), with
the same deployment/.env (or at least the same REGISTRY/IMAGE_TAG), run:
  ./deploy.sh
EOF

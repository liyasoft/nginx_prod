#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short=12 HEAD)}"
IMAGE="${IMAGE:-nginx:${IMAGE_TAG}}"

docker build --pull --tag "$IMAGE" .
printf 'Built image: %s\n' "$IMAGE"

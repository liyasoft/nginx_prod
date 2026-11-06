#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short=12 HEAD)}"
IMAGE="${IMAGE:-nginx:${IMAGE_TAG}}"
: "${ECS_HOST:?Set ECS_HOST to the ECS public or private address}"
: "${ECS_USER:?Set ECS_USER to an SSH user with Docker access}"
: "${ECS_SSH_PRIVATE_KEY:?Set ECS_SSH_PRIVATE_KEY as a protected pipeline variable}"
: "${ECS_KNOWN_HOSTS:?Set ECS_KNOWN_HOSTS to the pinned SSH host key}"

ARCHIVE="$(mktemp)"
SSH_DIR="$(mktemp -d)"
SSH_KEY="${SSH_DIR}/id_ed25519"
KNOWN_HOSTS="${SSH_DIR}/known_hosts"
REMOTE_ARCHIVE="/tmp/nginx-image-${IMAGE_TAG}.tar.gz"

cleanup() {
  rm -f "$ARCHIVE" "$SSH_KEY" "$KNOWN_HOSTS"
  rmdir "$SSH_DIR" 2>/dev/null || true
}
trap cleanup EXIT

printf '%s\n' "$ECS_SSH_PRIVATE_KEY" > "$SSH_KEY"
printf '%s\n' "$ECS_KNOWN_HOSTS" > "$KNOWN_HOSTS"
chmod 600 "$SSH_KEY" "$KNOWN_HOSTS"

docker image inspect "$IMAGE" >/dev/null
docker save "$IMAGE" | gzip > "$ARCHIVE"

SSH_OPTS=(-i "$SSH_KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o "UserKnownHostsFile=$KNOWN_HOSTS")
scp "${SSH_OPTS[@]}" "$ARCHIVE" "${ECS_USER}@${ECS_HOST}:${REMOTE_ARCHIVE}"

IMAGE_QUOTED="$(printf '%q' "$IMAGE")"
REMOTE_ARCHIVE_QUOTED="$(printf '%q' "$REMOTE_ARCHIVE")"
REMOTE_COMMAND="set -e; test -d /usr/server; docker load -i ${REMOTE_ARCHIVE_QUOTED}; docker rm -f nginx >/dev/null 2>&1 || true; docker run -d --restart unless-stopped --name nginx -p 80:80 -p 443:443 -v /usr/server:/usr/server:ro ${IMAGE_QUOTED}; rm -f ${REMOTE_ARCHIVE_QUOTED}"
ssh "${SSH_OPTS[@]}" "${ECS_USER}@${ECS_HOST}" "$REMOTE_COMMAND"

printf 'Deployed image to %s: %s\n' "$ECS_HOST" "$IMAGE"

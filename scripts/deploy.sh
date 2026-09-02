#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "오류: .env 파일이 없습니다." >&2
  exit 1
fi

./scripts/validate-env.sh

if [[ ! -f certbot/conf/live/thing.qook.io/fullchain.pem ]]; then
  echo "오류: 인증서가 없습니다. 먼저 ./scripts/init-ssl.sh를 실행하세요." >&2
  exit 1
fi

mkdir -p nginx/runtime
cp nginx/https.conf nginx/runtime/default.conf
./scripts/build-apps.sh
docker compose up -d --build --remove-orphans
docker compose exec nginx nginx -t
docker compose ps

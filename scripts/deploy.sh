#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "오류: .env 파일이 없습니다." >&2
  exit 1
fi

./scripts/validate-env.sh

# Certbot의 live/archive 디렉터리는 root 소유이므로 일반 사용자 검사는 실패할 수 있습니다.
if ! sudo -v; then
  echo "오류: 인증서 확인에 필요한 sudo 권한을 얻지 못했습니다." >&2
  exit 1
fi

if ! sudo test -f certbot/conf/live/thing.qook.io/fullchain.pem; then
  echo "오류: 인증서가 없습니다. 먼저 ./scripts/init-ssl.sh를 실행하세요." >&2
  exit 1
fi

mkdir -p nginx/runtime
cp nginx/https.conf nginx/runtime/default.conf
./scripts/build-apps.sh
docker compose up -d --build --remove-orphans
docker compose exec nginx nginx -t
docker compose ps

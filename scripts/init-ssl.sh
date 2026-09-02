#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "오류: cp .env.example .env 후 실제 값을 입력하세요." >&2
  exit 1
fi

./scripts/validate-env.sh

LETSENCRYPT_EMAIL="$(sed -n 's/^LETSENCRYPT_EMAIL=//p' .env | tail -n 1 | tr -d '\r')"

mkdir -p nginx/runtime certbot/www certbot/conf
cp nginx/bootstrap.conf nginx/runtime/default.conf

./scripts/build-apps.sh
docker compose up -d --build main admin nginx

docker compose run --rm --entrypoint certbot certbot certonly \
  --webroot --webroot-path /var/www/certbot \
  --email "$LETSENCRYPT_EMAIL" --agree-tos --no-eff-email \
  --cert-name thing.qook.io \
  -d thing.qook.io -d thingcoding.qook.io -d thing-admin.qook.io

cp nginx/https.conf nginx/runtime/default.conf
docker compose up -d --force-recreate nginx certbot
docker compose exec nginx nginx -t

echo "완료: 세 도메인에 HTTPS가 적용되었습니다."

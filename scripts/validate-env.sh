#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "오류: .env 파일이 없습니다. cp .env.example .env를 먼저 실행하세요." >&2
  exit 1
fi

read_env() {
  local value
  value="$(sed -n "s/^$1=//p" .env | tail -n 1 | tr -d '\r')"
  value="${value#\"}"
  value="${value%\"}"
  printf '%s' "$value"
}

email="$(read_env LETSENCRYPT_EMAIL)"
service_name="$(read_env ORACLE_SERVICE_NAME)"
db_username="$(read_env DB_USERNAME)"
db_password="$(read_env DB_PASSWORD)"
wallet_path="$(read_env WALLET_PATH)"

if [[ -z "$email" || "$email" == "admin@example.com" ]]; then
  echo "오류: LETSENCRYPT_EMAIL을 실제 이메일로 변경하세요." >&2
  exit 1
fi

if [[ -z "$service_name" || -z "$db_username" || -z "$db_password" || "$db_password" == "change-me" ]]; then
  echo "오류: ORACLE_SERVICE_NAME, DB_USERNAME, DB_PASSWORD를 실제 값으로 입력하세요." >&2
  exit 1
fi

if [[ ! "$service_name" =~ ^[A-Za-z0-9_.-]+$ ]]; then
  echo "오류: ORACLE_SERVICE_NAME 형식이 올바르지 않습니다." >&2
  exit 1
fi

if [[ -z "$wallet_path" || ! -d "$wallet_path" ]]; then
  echo "오류: WALLET_PATH 디렉터리를 찾을 수 없습니다: $wallet_path" >&2
  exit 1
fi

for wallet_file in tnsnames.ora sqlnet.ora cwallet.sso; do
  if [[ ! -f "$wallet_path/$wallet_file" ]]; then
    echo "오류: Wallet 필수 파일이 없습니다: $wallet_path/$wallet_file" >&2
    exit 1
  fi
done

if ! grep -Eq "^[[:space:]]*$service_name[[:space:]]*=" "$wallet_path/tnsnames.ora"; then
  echo "오류: ORACLE_SERVICE_NAME '$service_name'이 tnsnames.ora에 없습니다." >&2
  exit 1
fi

echo "환경변수와 Oracle Wallet 구성을 확인했습니다."

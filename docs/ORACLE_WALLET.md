# Oracle DB와 Wallet 설정

## 1. 권장 디렉터리 구조

Wallet ZIP 파일은 저장소에 넣지 않고 `/home/opc/work/wallet`에 압축을 해제합니다.

```text
/home/opc/work/
├── thingcoding_infra/
├── thingcoding_main/
├── thingcoding_manage/
└── wallet/
    ├── cwallet.sso
    ├── ewallet.p12
    ├── keystore.jks
    ├── ojdbc.properties
    ├── sqlnet.ora
    ├── tnsnames.ora
    └── truststore.jks
```

애플리케이션 컨테이너에서는 이 경로가 읽기 전용 `/app/wallet`으로 보입니다. Wallet 파일은 공개 저장소나 Docker 이미지에 포함하지 않습니다.

권한 설정 예시:

```bash
sudo chown -R opc:opc /home/opc/work/wallet
chmod 700 /home/opc/work/wallet
chmod 600 /home/opc/work/wallet/*
```

## 2. 환경변수 작성

```bash
cd /home/opc/work/thingcoding_infra
cp .env.example .env
vi .env
```

예시:

```dotenv
LETSENCRYPT_EMAIL=admin@qook.io
ORACLE_SERVICE_NAME=o14d0nm3uo1d4iud_medium
DB_USERNAME=thing
DB_PASSWORD=replace-with-a-real-password
WALLET_PATH=/home/opc/work/wallet
MAIN_JAVA_OPTS=-Xms128m -Xmx320m -XX:MaxMetaspaceSize=128m -Xss256k -XX:+UseSerialGC
ADMIN_JAVA_OPTS=-Xms32m -Xmx128m -XX:MaxMetaspaceSize=96m -Xss256k -XX:+UseSerialGC
```

`ORACLE_SERVICE_NAME`은 `tnsnames.ora` 왼쪽에 정의된 별칭과 정확히 같아야 합니다. 비밀번호에 `#`, 공백 또는 따옴표가 들어가면 Compose의 dotenv 문법에 맞게 큰따옴표로 감싸십시오.

최종 JDBC URL은 컨테이너 내부에서 다음과 같이 만들어집니다.

```text
jdbc:oracle:thin:@${ORACLE_SERVICE_NAME}?TNS_ADMIN=/app/wallet
```

## 3. 설정 검증

```bash
cd /home/opc/work/thingcoding_infra
chmod +x scripts/*.sh
./scripts/validate-env.sh
```

검증 스크립트는 `.env`, Wallet 경로, `tnsnames.ora`, `sqlnet.ora`, `cwallet.sso`와 접속 별칭을 확인합니다. 실제 DB 접속은 컨테이너가 시작된 뒤 로그로 확인합니다.

```bash
docker compose logs --tail=200 main admin
```

## 4. 보안 원칙

- `.env`와 Wallet은 Git에 커밋하지 않습니다.
- OCI DB 사용자에게 애플리케이션에 필요한 최소 권한만 부여합니다.
- 비밀번호가 노출되었다면 Git에서 파일만 지우는 것으로 끝내지 말고 DB 비밀번호를 즉시 변경합니다.
- Wallet을 교체하면 호스트 파일을 갱신한 뒤 `docker compose restart main admin`을 실행합니다.

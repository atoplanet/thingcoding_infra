# thingcoding_infra

Oracle Linux 단일 서버용 운영 구성입니다.

- `thing.qook.io`, `thingcoding.qook.io` → `main:8080`
- `thing-admin.qook.io` → `admin:10000`
- HTTP(80) → HTTPS(443) 리다이렉트
- Let's Encrypt 인증서 발급 및 자동 갱신

## 서버 준비

세 저장소를 같은 디렉터리에 둡니다.

```text
/home/opc/work/
├── thingcoding_infra/
├── thingcoding_main/
├── thingcoding_manage/
├── wallet/
└── static_resource/
    ├── compileTmp/
    ├── thingProjectImg/
    ├── errorReportImg/
    └── profileImg/
```

DNS의 세 도메인 A 레코드가 서버 공인 IP를 가리키는지 확인하고 Oracle Cloud 보안 목록/NSG와 서버 방화벽에서 TCP 80, 443을 허용합니다.

## 최초 배포

```bash
cd /home/opc/work/thingcoding_infra
cp .env.example .env
vi .env
chmod +x scripts/*.sh
./scripts/init-ssl.sh
```

`.env`에는 실제 이메일과 DB 접속 정보를 입력해야 합니다. Oracle Wallet을 사용한다면 기본 경로는 `/home/opc/work/wallet`이며 `WALLET_PATH`로 변경할 수 있습니다.

컴파일 임시 파일과 업로드 이미지는 기본적으로 `/home/opc/work/static_resource`에 저장되며 `STATIC_RESOURCE_PATH`로 변경할 수 있습니다. 배포 전에 다음 디렉터리를 생성합니다.

```bash
mkdir -p /home/opc/work/static_resource/{compileTmp,thingProjectImg,errorReportImg,profileImg}
```

상세 문서:

- [Oracle DB 및 Wallet 설정](docs/ORACLE_WALLET.md)
- [Oracle Linux 배포 및 문제 해결](docs/DEPLOYMENT.md)

## 이후 배포

```bash
cd /home/opc/work/thingcoding_infra
./scripts/deploy.sh
```

상태와 로그 확인:

```bash
docker compose ps
docker compose logs -f --tail=200 main admin nginx
```

인증서 갱신은 `certbot` 컨테이너가 12시간마다 확인하고, `nginx` 컨테이너가 6시간마다 설정을 다시 읽습니다.

애플리케이션 빌드는 Java/Maven 설치 없이 Maven 컨테이너에서 순차 실행됩니다. 1GB RAM 서버에서 주 서비스인 `main`은 최대 힙 320MB/컨테이너 500MB, 사용 빈도가 낮은 `admin`은 최대 힙 128MB/컨테이너 256MB로 제한했습니다. 빌드 중 메모리가 부족하면 임시 swap을 추가하거나, CI에서 이미지를 빌드해 서버에서는 pull만 하는 방식을 권장합니다.

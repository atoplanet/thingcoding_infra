# Oracle Linux 배포 가이드

## 사전 조건

- Docker와 Docker Compose 플러그인이 설치되어 있어야 합니다.
- 세 저장소가 `/home/opc/work` 아래에 나란히 있어야 합니다.
- `thing.qook.io`, `thingcoding.qook.io`, `thing-admin.qook.io`의 A 레코드가 서버 공인 IP를 가리켜야 합니다.
- OCI 보안 목록 또는 NSG와 Oracle Linux 방화벽에서 TCP 80, 443을 허용해야 합니다.
- Oracle Wallet과 `.env` 설정을 완료해야 합니다.

## 최초 배포

```bash
cd /home/opc/work/thingcoding_infra
cp .env.example .env
vi .env
chmod +x scripts/*.sh
./scripts/init-ssl.sh
```

스크립트는 다음 순서로 동작합니다.

1. 환경변수와 Wallet 파일을 검사합니다.
2. 두 Spring Boot 프로젝트를 Maven 컨테이너에서 순차 빌드합니다.
3. 임시 HTTP Nginx를 실행합니다.
4. 세 도메인을 포함한 Let's Encrypt 인증서를 발급합니다.
5. HTTPS Nginx 설정으로 교체하고 Certbot 자동 갱신을 시작합니다.

## 일반 재배포

애플리케이션 저장소에서 새 코드를 받은 뒤 실행합니다.

```bash
cd /home/opc/work/thingcoding_infra
./scripts/deploy.sh
```

## 확인 명령

```bash
docker compose ps
docker compose logs -f --tail=200 main admin nginx certbot
curl -I http://thing.qook.io
curl -I https://thing.qook.io
curl -I https://thingcoding.qook.io
curl -I https://thing-admin.qook.io
```

HTTP 요청은 `301`과 HTTPS 주소를 반환해야 합니다. HTTPS 요청은 애플리케이션 응답을 반환해야 합니다.

## 문제 해결

### 인증서가 있는데 없다고 표시되는 경우

Certbot이 생성한 `live`와 `archive` 디렉터리는 root 소유여서 `opc`의 일반 파일 검사가 실패할 수 있습니다. `deploy.sh`는 `sudo test -f`로 인증서를 확인하며, sudo 인증 실패는 별도 오류로 안내합니다. 배포 전체를 sudo로 실행할 필요는 없습니다.

```bash
sudo test -f certbot/conf/live/thing.qook.io/fullchain.pem && echo "인증서 존재"
```

인증서가 존재하면 재발급하거나 개인키 권한을 완화하지 말고, 수정된 배포 스크립트로 재시도합니다.

### 기타 점검

인증서 발급 실패 시 DNS와 80 포트부터 확인합니다.

```bash
getent hosts thing.qook.io thingcoding.qook.io thing-admin.qook.io
sudo firewall-cmd --list-ports
docker compose logs nginx
```

DB 연결 실패 시 다음 항목을 확인합니다.

- `.env`의 사용자명과 비밀번호
- `ORACLE_SERVICE_NAME`이 `tnsnames.ora`에 존재하는지
- Wallet 파일 권한 및 경로
- 서버에서 Oracle Cloud DB로 나가는 HTTPS/TCPS 연결이 허용되는지

메모리가 부족하면 `free -h`, `docker stats`로 확인합니다. 빌드는 순차 실행됩니다. 주 서비스인 `main`은 최대 힙 320MB와 컨테이너 상한 500MB, 사용 빈도가 낮은 `admin`은 최대 힙 128MB와 컨테이너 상한 256MB입니다. 나머지 메모리는 OS, Docker, Nginx 및 Certbot이 사용합니다.

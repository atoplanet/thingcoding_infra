#!/usr/bin/env bash
set -Eeuo pipefail

infra_dir="$(cd "$(dirname "$0")/.." && pwd)"
work_dir="$(dirname "$infra_dir")"

for project in thingcoding_main thingcoding_manage; do
  project_dir="$work_dir/$project"
  if [[ ! -f "$project_dir/pom.xml" ]]; then
    echo "오류: $project_dir/pom.xml을 찾을 수 없습니다." >&2
    exit 1
  fi

  echo "빌드 중: $project"
  docker run --rm \
    -e MAVEN_OPTS="-Xms128m -Xmx384m -XX:+UseSerialGC" \
    -v "$project_dir:/workspace" \
    -v thingcoding_maven_cache:/root/.m2 \
    -w /workspace \
    maven:3.8.8-eclipse-temurin-8 \
    mvn -B -DskipTests clean package
done

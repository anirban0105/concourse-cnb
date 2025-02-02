#!/bin/bash

set -e

mkdir -p /layers
mkdir -p /platform
cp -r source /

for path in "$PWD/cache" "/layers" "/platform" "/source"; do
    echo "> Setting permissions on '$path'..."
    chown -R "1000:1000" "$path"
done


CACHE_DIR=$PWD/cache
CACHE_IMAGE=${APP_IMAGE}-cache


# Copy env
if [ -d "env" ]
then
  cp -r env /platform/
fi

if [ -d "bindings" ]
then
  cp -r bindings /platform/
fi

unset CNB_REGISTRY_AUTH
mkdir ~/.docker
echo "{\"auths\":{\"${IMAGE_REPO}\":{\"username\":\"${IMAGE_REPO_USERNAME}\",\"password\":\"${IMAGE_REPO_PASSWORD}\"}}}" >> ~/.docker/config.json

/cnb/lifecycle/creator -app=/source \
    -cache-image="${CACHE_IMAGE}" \
    -cache-dir="${CACHE_DIR}" \
    -uid=1000 \
    -gid=1000 \
    -layers=/layers \
    -platform=/platform \
    -report=/layers/report.toml \
    -process-type="${PROCESS_TYPE}" \
    -skip-restore="${SKIP_RESTORE}" \
    -run-image="${RUN_IMAGE}" \
    "${APP_IMAGE}"

cat /layers/report.toml | grep "digest" | cut -d'"' -f2 | cut -d'"' -f2 | tr -d '\n' | tee image/digest

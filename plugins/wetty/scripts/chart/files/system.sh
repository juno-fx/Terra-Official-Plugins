#!/bin/sh
set -e

cd /usr/src/app

addgroup -g "{{ .Values.guid }}" wettyusers

adduser -D -u "{{ .Values.puid }}" -G wettyusers "{{ .Values.user }}"

echo "{{ .Values.user }}:$USER_PASS" | chpasswd

if [ -n "$PACKAGES" ]; then
  apk add "$PACKAGES"
fi

yarn start --base "/polaris/{{ .Values.name }}" --allow-iframe

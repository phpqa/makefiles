#!/usr/bin/env sh

set -e

if test "$(printf %c "$1")" = "-"; then
  set -- php "$@"
elif test -f "$1"; then
  set -- php "$@"
fi

exec "$@"

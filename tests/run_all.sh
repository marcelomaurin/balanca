#!/usr/bin/env sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="$ROOT/tests/bin"

mkdir -p "$OUT"

compile_and_run() {
  name="$1"
  shift
  echo "==> $name"
  fpc -Fu"$ROOT/src/core" -Fu"$ROOT/src/api" -Fu"$ROOT/src" -Fu"$ROOT/tests"       -FE"$OUT" "$ROOT/tests/$name.pas" "$@"
  "$OUT/$name"
}

compile_and_run toledo_protocol_test
compile_and_run commands_test
compile_and_run config_test
compile_and_run api_json_test

echo "OK - toda a suite passou"

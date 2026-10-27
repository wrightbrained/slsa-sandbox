#!/usr/bin/env bash
set -euo pipefail
mkdir -p dist
cc -O2 -o dist/hello-service hello.c

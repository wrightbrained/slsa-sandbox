#!/usr/bin/env bash
set -euo pipefail
mkdir -p dist
cc -O2 -o dist/hello-service hello.c
tar -czf dist/hello-service.tar.gz -C dist hello-service

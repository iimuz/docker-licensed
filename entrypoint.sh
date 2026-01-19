#!/bin/bash
set -e

# GITHUB_TOKENが設定されている場合、GitHub HTTPS認証を設定
if [ -n "$GITHUB_TOKEN" ]; then
  git config --global url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "https://github.com/"
fi

exec "$@"

FROM ruby:3.2-slim AS builder

# パッケージとlicensedをインストールするビルドステージ
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libgit2-dev \
    pkg-config \
    cmake \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && gem install licensed -v 4.4.0 \
    && gem cleanup

# 実行用の軽量イメージ
FROM ruby:3.2-slim

# 必要なランタイム依存関係のみインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libgit2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ビルドステージからlicensedをコピー
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

# 非rootユーザーに切り替え
RUN groupadd -r appuser && useradd -r -g appuser -m -s /bin/bash appuser
WORKDIR /app
RUN mkdir -p /app && chown -R appuser:appuser /app
USER appuser
CMD ["licensed", "--help"]

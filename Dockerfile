FROM ruby:3.2-slim AS builder

# パッケージとlicensedをインストールするビルドステージ
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    pkg-config \
    cmake \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libzstd-dev \
    libssh2-1-dev \
    && gem install licensed -v 4.4.0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && gem cleanup

# 実行用の軽量イメージ
FROM ruby:3.2-slim

# Goのバージョン指定
ENV GO_VERSION=1.23.8

# 必要なランタイム依存関係のみインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libssl3t64 \
    libssh2-1t64 \
    libzstd1 \
    wget \
    curl \
    gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # GitHub CLI (gh) のインストール
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # Goのインストール
    && ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then GO_ARCH="amd64"; elif [ "$ARCH" = "arm64" ]; then GO_ARCH="arm64"; else GO_ARCH="$ARCH"; fi \
    && wget -q https://golang.org/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-${GO_ARCH}.tar.gz \
    && rm go${GO_VERSION}.linux-${GO_ARCH}.tar.gz

# Go環境変数の設定
ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/go
ENV PATH=$PATH:$GOPATH/bin
RUN mkdir -p $GOPATH/src $GOPATH/bin

# ビルドステージからlicensedをコピー
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

# entrypoint.shをコピーして実行可能にする
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 非rootユーザーに切り替え
RUN groupadd -r appuser && useradd -r -g appuser -m -s /bin/bash appuser
WORKDIR /app
RUN mkdir -p /app && chown -R appuser:appuser /app \
    && mkdir -p $GOPATH && chown -R appuser:appuser $GOPATH
USER appuser

ENTRYPOINT ["/entrypoint.sh"]
CMD ["licensed", "--help"]

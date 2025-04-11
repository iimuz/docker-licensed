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

# Goのバージョン指定
ENV GO_VERSION=1.23.7

# 必要なランタイム依存関係のみインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    libgit2-dev \
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
    && wget -q https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz \
    && rm go${GO_VERSION}.linux-amd64.tar.gz

# Go環境変数の設定
ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/go
ENV PATH=$PATH:$GOPATH/bin
RUN mkdir -p $GOPATH/src $GOPATH/bin

# ビルドステージからlicensedをコピー
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

# 非rootユーザーに切り替え
RUN groupadd -r appuser && useradd -r -g appuser -m -s /bin/bash appuser
WORKDIR /app
RUN mkdir -p /app && chown -R appuser:appuser /app \
    && mkdir -p $GOPATH && chown -R appuser:appuser $GOPATH
USER appuser
CMD ["licensed", "--help"]

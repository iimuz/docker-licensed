---
title: GOPRIVATE対応設計書
description: GOPRIVATEパッケージ対応のためのDockerコンテナ内Git認証設定の統合設計書
---

## Summary

# Docker Licensed - GitHub Private Repository認証設計書

## 1. 概要

### 目的

Docker化されたlicensedツール環境において、Goのプライベートリポジトリへのアクセスを可能にする。

### 目標

- コンテナ内でGitHubプライベートリポジトリへのHTTPS認証を実現
- ホスト環境のGit設定を保護
- セキュアで柔軟な認証メカニズムの提供

### スコープ

- Dockerコンテナ起動時の認証設定自動化
- GITHUB_TOKEN環境変数によるトークンベース認証
- 非rootユーザーでの実行

## Context

## 設計方針

### 主要な設計決定

#### 3.1 Entrypointベースの認証設定

**決定**: コンテナ起動時にentrypointスクリプトで動的にGit認証を設定

**理由**:

- イメージビルド時にトークンを埋め込まない（セキュリティ）
- 実行時の柔軟な認証制御が可能
- 環境変数の有無で認証の有効/無効を切り替え可能

**代替案**:

- GIT_CONFIG_GLOBAL環境変数で別ファイルを指定 → 既存.gitconfigを無視する問題
- ビルド時の設定埋め込み → セキュリティリスク

#### 3.2 デフォルトGit設定ファイルの活用

**決定**: コンテナ内のデフォルト`~/.gitconfig`を使用

**理由**:

- ホストの.gitconfigと分離され、環境汚染を防止
- 既存設定との競合を回避
- 標準的なGit動作を維持

#### 3.3 条件付き認証設定

**決定**: GITHUB_TOKEN環境変数の有無で認証設定を制御

**理由**:

- パブリックリポジトリのみの場合は認証不要
- トークン未設定時のエラー回避
- 開発環境と本番環境での柔軟な運用

## 実装詳細

### システム構成

```
[Docker起動]
    ↓
[Entrypointスクリプト実行]
    ↓
[GITHUB_TOKEN確認] → なし → [メインコマンド実行]
    ↓ あり
[Git HTTPS認証設定]
    ↓
[メインコマンド実行]
```

### コンポーネント役割

| コンポーネント | 役割       | 設定内容                                                   |
| -------------- | ---------- | ---------------------------------------------------------- |
| entrypoint.sh  | 認証初期化 | GITHUB_TOKENベースのHTTPS認証を`git config --global`で設定 |
| Dockerfile     | 環境構築   | 非rootユーザー作成、entrypoint登録                         |
| GITHUB_TOKEN   | 認証情報   | 実行時に環境変数で提供されるPersonal Access Token          |

### ファイル実装

#### entrypoint.sh

```bash
#!/bin/bash
set -e

# GITHUB_TOKENが設定されている場合、GitHub HTTPS認証を設定
if [ -n "$GITHUB_TOKEN" ]; then
  git config --global url."https://${GITHUB_TOKEN}:x-oauth-basic@github.com/".insteadOf "https://github.com/"
fi

exec "$@"
```

#### Dockerfile (関連部分)

```dockerfile
# entrypoint.shをコピーして実行可能にする
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 非rootユーザーに切り替え
USER appuser

ENTRYPOINT ["/entrypoint.sh"]
CMD ["licensed", "--help"]
```

## 2. 背景・課題

### 解決すべき課題

| 課題                             | 影響                                                    |
| -------------------------------- | ------------------------------------------------------- |
| Goプライベートパッケージアクセス | GOPRIVATE設定とGit認証の両方が必要                      |
| ホスト環境の保護                 | .gitconfig等の設定ファイルを汚染しない                  |
| 既存設定の尊重                   | GIT_CONFIG_GLOBAL使用時に既存.gitconfigが無視される問題 |

### 制約条件

- Dockerコンテナ内での動作
- セキュアなトークン管理
- 既存のlicensedツールとの互換性維持

## Next Steps

## 5. 使用方法

### 基本的な実行フロー

#### プライベートリポジトリアクセス時

```bash
docker run -e GITHUB_TOKEN=$GITHUB_TOKEN <image> licensed cache
```

#### パブリックリポジトリのみの場合

```bash
docker run <image> licensed cache
```

#### docker-compose.ymlでの指定

```yaml
services:
  licensed:
    image: <image>
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
```

### インターフェース仕様

| 項目               | 仕様                                             |
| ------------------ | ------------------------------------------------ |
| 必須環境変数       | なし（GITHUB_TOKENは任意）                       |
| オプション環境変数 | GITHUB_TOKEN（プライベートリポジトリアクセス時） |
| エントリーポイント | /entrypoint.sh                                   |
| デフォルトコマンド | licensed --help                                  |

## Notes

## 6. 注意事項

### セキュリティ

- **トークン管理**: GITHUB_TOKENは実行時に環境変数で渡し、イメージに埋め込まない
- **権限スコープ**: Personal Access Tokenは必要最小限の権限（repo:read）を設定
- **ログ露出**: トークンがログに出力されないよう注意

### 運用上の考慮事項

- ホストの.gitconfigをマウントする場合はread-only推奨
- コンテナ内のGit設定はコンテナ削除時に消失
- 複数のGitHub組織を使用する場合、url設定の調整が必要な場合あり

### 既知の制約

- SSH認証には非対応（HTTPS認証のみ）
- コンテナ内部でのみ有効な設定

---

## まとめ

本設計は、Dockerコンテナ内でのGoプライベートパッケージアクセスを、セキュアかつ柔軟に実現します。entrypointベースの動的設定により、ホスト環境を保護しながら、実行時の要件に応じた認証制御が可能です。

**主な利点:**

1. セキュア: トークンをイメージに埋め込まず、実行時に提供
2. 柔軟: GITHUB_TOKENの有無で自動的に動作を切り替え
3. 安全: ホストの.gitconfigを汚染しない
4. シンプル: 標準的なgit config --globalを使用

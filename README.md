# Docker Licensed

licensedツールをDocker環境で実行するためのリポジトリです。このコンテナを使用して、プロジェクトの依存ライセンスをチェックできます。

## 環境構築

以下のコマンドでDockerイメージをビルドします。

```bash
docker-compose build
```

## 使用方法

### 基本的な使い方

ヘルプを表示するには:

```bash
docker-compose run licensed
```

### 具体的な使用例

プロジェクトディレクトリ内で以下のように使用します（自分のプロジェクトディレクトリをマウントしてください）:

```bash
# プロジェクトディレクトリに移動
cd /path/to/your/project

# licensedを初期化
docker run --rm -v $(pwd):/app -w /app docker-licensed licensed init

# 依存関係のライセンスをキャッシュ
docker run --rm -v $(pwd):/app -w /app docker-licensed licensed cache

# ライセンスをチェック
docker run --rm -v $(pwd):/app -w /app docker-licensed licensed status
```

または、docker-compose.ymlを自分のプロジェクトにコピーして:

```bash
# 依存関係のライセンスをキャッシュ
docker-compose run licensed licensed cache

# ライセンスをチェック
docker-compose run licensed licensed status
```

## 注意事項

- licensedはプロジェクトのタイプに応じて適切に設定する必要があります
- 詳細は[licensed公式ドキュメント](https://github.com/licensee/licensed)を参照してください

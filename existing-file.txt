# storage-branch-action

GitHub Actionsで専用ブランチにデータを永続化するためのAction。
キャッシュデータや生成ファイルなど、mainブランチで管理したくないがワークフロー間で共有したい情報の管理に便利。

> **Note**: 新規作成時はorphanブランチとして作成されます（mainの履歴と完全分離）。既存ブランチも使用可能。

## Actions

### `taqm/storage-branch-action/checkout`

ストレージブランチからファイルを取得してワークスペースに配置。

### `taqm/storage-branch-action/commit`

ワークスペースのファイルをストレージブランチにコミット。

## Usage

```yaml
permissions:
  contents: write  # commit action requires write permission

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # ストレージブランチからファイルを取得
      - uses: taqm/storage-branch-action/checkout@v1
        with:
          branch: storage
          from: cache/build-cache.json
          to: .cache/build-cache.json

      - uses: taqm/storage-branch-action/checkout@v1
        with:
          branch: storage
          from: data/previous-results.json
          to: data/previous.json

      # ビルド処理...
      - run: npm run build

      # 結果をストレージブランチに保存
      - uses: taqm/storage-branch-action/commit@v1
        with:
          branch: storage
          from: .cache/build-cache.json
          to: cache/build-cache.json
          message: 'Update build cache'

      - uses: taqm/storage-branch-action/commit@v1
        with:
          branch: storage
          from: dist/results.json
          to: data/previous-results.json
          message: 'Update build results'
```

## Inputs

### checkout

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `branch` | ストレージブランチ名 | No | `storage` |
| `from` | ストレージブランチ内のファイルパス | Yes | - |
| `to` | ワークスペース内の保存先パス | Yes | - |
| `working-directory` | toパスの基準ディレクトリ | No | `.` |
| `fail-on-missing` | ファイルがない場合にエラーにするか | No | `false` |

### commit

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `branch` | ストレージブランチ名 | No | `storage` |
| `from` | ワークスペース内のファイルパス | Yes | - |
| `to` | ストレージブランチ内の保存先パス | Yes | - |
| `working-directory` | fromパスの基準ディレクトリ | No | `.` |
| `message` | コミットメッセージ | No | `Update storage files` |

## Behavior

- **ブランチが存在しない場合**:
  - checkout: 警告を出してスキップ
  - commit: 新規ブランチを自動作成（orphanブランチとして作成）

- **ファイルが存在しない場合**:
  - checkout: `fail-on-missing: false` (デフォルト) なら警告のみ、`true` ならエラー
  - commit: エラー

## Tips

### orphanブランチを事前に作成する

commit actionは自動でorphanブランチを作成しますが、手動で作成することもできます。
事前にファイルを置いておくことで、初期データとして使うことができます。

```bash
# orphanブランチを作成（履歴なし）
git checkout --orphan storage
git rm -rf .

# 初期データを配置（任意）
echo '{}' > cache.json

git add -A
git commit -m "Initialize storage branch"
git push origin storage
git checkout main
```

## License

MIT

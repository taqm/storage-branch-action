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
          files: |
            cache/build-cache.json .cache/build-cache.json
            data/previous-results.json data/previous.json

      # ビルド処理...
      - run: npm run build

      # 結果をストレージブランチに保存
      - uses: taqm/storage-branch-action/commit@v1
        with:
          branch: storage
          files: |
            .cache/build-cache.json cache/build-cache.json
            dist/results.json data/previous-results.json
          message: 'Update build cache'
```

## Inputs

### checkout

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `branch` | ストレージブランチ名 | No | `storage` |
| `files` | ファイルマッピング（1行1ペア） | Yes | - |
| `working-directory` | toパスの基準ディレクトリ | No | `.` |
| `fail-on-missing` | ファイルがない場合にエラーにするか | No | `false` |

### commit

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `branch` | ストレージブランチ名 | No | `storage` |
| `files` | ファイルマッピング（1行1ペア） | Yes | - |
| `working-directory` | fromパスの基準ディレクトリ | No | `.` |
| `message` | コミットメッセージ | No | `Update storage files` |

## File Mapping Format

```yaml
files: |
  <source> <destination>
  source/path/file.txt dest/path/file.txt
  another/file.json data/file.json
```

パスにスペースを含む場合はクォートで囲む:
```yaml
files: |
  "path with space/file.txt" "dest path/file.txt"
  'single quotes work too.txt' dest.txt
```

- **checkout**: 左がストレージブランチ内のパス、右がワークスペース内のパス
- **commit**: 左がワークスペース内のパス、右がストレージブランチ内のパス

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

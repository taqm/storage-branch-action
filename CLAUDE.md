# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GitHub Actions用のComposite Action。専用ブランチにデータを永続化する。
キャッシュや生成ファイルなど、mainブランチで管理したくないがワークフロー間で共有したい情報の管理用途。

## Architecture

```
├── checkout/action.yml  # ストレージブランチからファイルを取得
├── commit/action.yml    # ストレージブランチにファイルをコミット
├── README.md
└── CLAUDE.md
```

- Composite Actionのため、ビルドプロセスは不要
- 1回の呼び出しで1ファイルのみ処理（複数ファイルは複数回呼び出し）

## Development

### テスト方法

ローカルでのテストは困難。テスト用ワークフローを作成して検証:

```yaml
# .github/workflows/test.yml
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./checkout
        with:
          branch: test-storage
          from: test.txt
          to: output/test.txt
```

### リリース

```bash
git tag v1.0.0
git push origin v1.0.0

# メジャーバージョンタグ更新
git tag -f v1
git push -f origin v1
```

## Key Implementation Details

- `from`/`to` で単一ファイルを指定（複数ファイルは複数回呼び出し）
- ブランチが存在しない場合、commitアクションでorphanブランチとして自動作成
- checkoutでファイルがない場合は `fail-on-missing` パラメータで挙動制御
- `working-directory` はcheckout時はdestパス、commit時はsrcパスにのみ影響

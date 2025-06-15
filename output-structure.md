# 成果物ディレクトリ構造

## ディレクトリ構成

```
outputs/                    # 全成果物のルートディレクトリ
├── default/               # デフォルトチームの成果物
│   ├── projects/         # プロジェクト成果物
│   ├── docs/            # ドキュメント
│   └── tests/           # テストコード
├── team1/                # チーム1の成果物
│   ├── projects/        # プロジェクト成果物
│   ├── docs/           # ドキュメント
│   └── tests/          # テストコード
├── team2/                # チーム2の成果物
│   ├── projects/        # プロジェクト成果物
│   ├── docs/           # ドキュメント
│   └── tests/          # テストコード
└── ...

tmp/                       # 作業用一時ファイル
├── worker1_done.txt      # デフォルトチームの完了フラグ
├── worker1_progress.log  # デフォルトチームの進捗ログ
├── team1/               # チーム1の一時ファイル
│   ├── worker1_done.txt
│   ├── worker2_done.txt
│   ├── worker3_done.txt
│   └── *.log
└── team2/               # チーム2の一時ファイル
    └── ...
```

## 成果物の種類と保存先

### プロジェクト成果物 (`outputs/[team]/projects/`)
- Webアプリケーション
- APIサーバー
- CLIツール
- ライブラリ

### ドキュメント (`outputs/[team]/docs/`)
- 設計書
- API仕様書
- ユーザーマニュアル
- 技術文書

### テスト (`outputs/[team]/tests/`)
- ユニットテスト
- 統合テスト
- E2Eテスト

## 環境変数

```bash
# デフォルトチーム
OUTPUT_DIR="./outputs/default"

# チーム番号付き
OUTPUT_DIR="./outputs/team${TEAM_NUM}"
```

## 使用例

```bash
# workerが成果物を保存する場合
mkdir -p $OUTPUT_DIR/projects/my-app
cp -r ./my-app/* $OUTPUT_DIR/projects/my-app/

# bossが成果物を確認する場合
ls -la $OUTPUT_DIR/projects/

# presidentが全成果物を確認する場合
find ./outputs -name "*.html" -type f
```
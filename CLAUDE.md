# Agent Communication System

## エージェント構成

### デフォルトチーム
- **PRESIDENT** (president): 統括責任者
- **boss1** (multiagent:0.0): チームリーダー
- **worker1,2,3** (multiagent:0.1-3): 実行担当

### 複数チーム対応
- **チーム1**: president1, boss1, worker1-1,2,3
- **チーム2**: president2, boss2, worker2-1,2,3
- 以下、任意の番号でチームを作成可能

## あなたの役割
- **PRESIDENT/president[N]**: @instructions/president.md
- **boss1/boss[N]**: @instructions/boss.md
- **worker1,2,3/worker[N]-1,2,3**: @instructions/worker.md

## チーム番号の識別
環境変数 `TEAM_NUM` であなたが所属するチームを確認できます。

## メッセージ送信

### デフォルトチーム
```bash
./agent-send.sh [相手] "[メッセージ]"
```

### 複数チーム対応
```bash
./agent-send-team.sh [相手] "[メッセージ]"

# 例: チーム1
./agent-send-team.sh president1 "メッセージ"
./agent-send-team.sh boss1 "メッセージ"
./agent-send-team.sh worker1-1 "メッセージ"
```

## 基本フロー
PRESIDENT[N] → boss[N] → workers[N] → boss[N] → PRESIDENT[N]

## チーム管理
```bash
# チーム作成
./setup-team.sh 1

# チーム一覧
./team-manager.sh list

# チーム削除
./team-manager.sh destroy 1
```

## 成果物ディレクトリ
成果物はチームごとに分かれて保存されます：

```
outputs/
├── default/          # デフォルトチーム
│   ├── projects/    # プロジェクト成果物
│   ├── docs/        # ドキュメント
│   └── tests/       # テストコード
└── team[N]/          # チームNの成果物
    ├── projects/
    ├── docs/
    └── tests/
```

### 環境変数
- `OUTPUT_DIR`: 成果物の保存先ディレクトリ
  - デフォルト: `./outputs/default`
  - チームN: `./outputs/team${TEAM_NUM}` 
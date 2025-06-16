# Agent Communication System

## システム概要

このシステムは 3 つのモードでチームを作成・管理できます：

1. **デフォルトモード**: 単一の標準開発チーム
2. **従来形式モード**: 番号付きの標準開発チーム
3. **役割ベースモード**: 専門特化チーム（出版、デザイン、ゲーム開発など）

## エージェント構成

### デフォルトチーム（単一チーム）

```
セッション: president, multiagent
役割構成:
- PRESIDENT (president): 統括責任者
- boss1 (multiagent:0.0): チームリーダー
- worker1,2,3 (multiagent:0.1-3): 実行担当
```

### 従来形式チーム（番号付き開発チーム）

```
セッション: president[N], multiagent[N]
役割構成:
- PRESIDENT[N]: 統括責任者
- boss[N]: チームリーダー
- worker[N]-1,2,3: 実行担当

例: チーム1
- president1, boss1, worker1-1,2,3
```

### 役割ベースチーム（専門特化チーム）

```
セッション: team[N]-leader, team[N]-workers
役割構成: テンプレートにより動的に決定

利用可能なテンプレート:
- default: 標準開発チーム
- publishing: 出版チーム (Publisher, Editor, Novelist×3)
- design: デザインチーム (CEO, DesignManager, WebDesigner×3)
- game-dev: ゲーム開発チーム (GameProducer, GameDirector, Programmer/Designer/Artist)
- game-planning: ゲーム企画チーム (ChiefPlanner, LeadPlanner, Planner/LevelDesigner/StoryWriter)
- marketing: マーケティングチーム (CMO, MarketingManager, ContentCreator/DataAnalyst/SocialMediaManager)
- research: 研究開発チーム (ResearchDirector, LeadResearcher, DataScientist/Researcher/TechnicalWriter)
```

## あなたの役割の確認方法

### 環境変数で確認

```bash
echo $TEAM_NUM        # チーム番号
echo $ROLE_TEMPLATE   # 役割テンプレート（役割ベースチームのみ）
echo $OUTPUT_DIR      # 成果物保存先
```

### 指示書の場所

#### デフォルト・従来形式チーム

- **PRESIDENT/president[N]**: @instructions/president.md
- **boss1/boss[N]**: @instructions/boss.md
- **worker1,2,3/worker[N]-1,2,3**: @instructions/worker.md

#### 役割ベースチーム

- **リーダー**: @instructions/team[N]/[LeaderRole].md
- **マネージャー**: @instructions/team[N]/[ManagerRole].md
- **ワーカー**: @instructions/team[N]/[WorkerRole].md

例: 出版チーム 1 の場合

- Publisher1: @instructions/team1/Publisher.md
- Editor1: @instructions/team1/Editor.md
- Novelist1-1,2,3: @instructions/team1/Novelist.md

## メッセージ送信

### 統合版 agent-send.sh（全モード対応）

```bash
./agent-send.sh [相手] "[メッセージ]"
```

#### デフォルトチーム

```bash
./agent-send.sh president "メッセージ"
./agent-send.sh boss1 "メッセージ"
./agent-send.sh worker1 "メッセージ"
```

#### 従来形式チーム

```bash
./agent-send.sh president1 "メッセージ"
./agent-send.sh boss1 "メッセージ"
./agent-send.sh worker1-1 "メッセージ"
```

#### 役割ベースチーム

```bash
./agent-send.sh Publisher1 "メッセージ"
./agent-send.sh Editor1 "メッセージ"
./agent-send.sh Novelist1-1 "メッセージ"
```

### 利用可能なエージェント確認

```bash
./agent-send.sh --list      # デフォルトチーム
./agent-send.sh --list-all  # 全チーム
```

## 基本フロー

### 標準開発チーム

```
PRESIDENT[N] → boss[N] → workers[N] → boss[N] → PRESIDENT[N]
```

### 役割ベースチーム（例: 出版チーム）

```
Publisher[N] → Editor[N] → Novelists[N] → Editor[N] → Publisher[N]
```

## チーム管理

### 統合版 setup.sh（全モード対応）

```bash
# デフォルトチーム作成
./setup.sh

# 従来形式チーム作成
./setup.sh [チーム番号]
./setup.sh 1

# 役割ベースチーム作成
./setup.sh [チーム番号] [役割テンプレート]
./setup.sh 1 publishing
./setup.sh 2 design --auto-start

# ヘルプ表示
./setup.sh --help
```

### team-manager.sh（高度な管理）

```bash
# チーム作成
./team-manager.sh create 1              # 従来形式
./team-manager.sh create 2 publishing   # 役割ベース

# チーム状態確認
./team-manager.sh list
./team-manager.sh status 1

# Claude Code起動
./team-manager.sh start 1

# チーム削除
./team-manager.sh destroy 1

# 全チームクリーンアップ
./team-manager.sh clean

# 利用可能な役割確認
./team-manager.sh roles
```

## 成果物ディレクトリ

成果物はチーム・モードごとに分かれて保存されます：

```
outputs/
├── default/          # デフォルトチーム
│   ├── projects/    # プロジェクト成果物
│   ├── docs/        # ドキュメント
│   └── tests/       # テストコード
└── team[N]/          # チーム[N]の成果物（従来・役割ベース共通）
    ├── projects/
    ├── docs/
    └── tests/
```

### 環境変数

- `OUTPUT_DIR`: 成果物の保存先ディレクトリ
  - デフォルト: `./outputs/default`
  - チーム N: `./outputs/team${TEAM_NUM}`
- `TEAM_NUM`: チーム番号（従来・役割ベースチーム）
- `ROLE_TEMPLATE`: 役割テンプレート名（役割ベースチームのみ）

## セッション管理

### tmux セッション名

#### デフォルトチーム

- `president`: リーダーセッション
- `multiagent`: ワーカーセッション（4 ペイン）

#### 従来形式チーム

- `president[N]`: リーダーセッション
- `multiagent[N]`: ワーカーセッション（4 ペイン）

#### 役割ベースチーム

- `team[N]-leader`: リーダーセッション
- `team[N]-workers`: ワーカーセッション（4 ペイン）

### セッション接続

```bash
# デフォルトチーム
tmux attach-session -t president
tmux attach-session -t multiagent

# 従来形式チーム1
tmux attach-session -t president1
tmux attach-session -t multiagent1

# 役割ベースチーム1
tmux attach-session -t team1-leader
tmux attach-session -t team1-workers
```

## 実行例

### デフォルトチーム

```bash
./setup.sh
./agent-send.sh president "あなたはpresidentです。Webアプリを作成してください。"
```

### 従来形式チーム

```bash
./setup.sh 1
./agent-send.sh president1 "あなたはpresident1です。チーム1でAPIを開発してください。"
```

### 役割ベースチーム

```bash
./setup.sh 1 publishing
./agent-send.sh Publisher1 "あなたはPublisher1です。SF小説シリーズを企画してください。"
```

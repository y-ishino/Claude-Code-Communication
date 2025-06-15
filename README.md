# 🤖 Claude Code エージェント通信システム

複数のAIが協力して働く、まるで会社のような開発システムです

## 📌 これは何？

**3行で説明すると：**
1. 複数のAIエージェント（社長・マネージャー・作業者）が協力して開発
2. それぞれ異なるターミナル画面で動作し、メッセージを送り合う
3. 人間の組織のように役割分担して、効率的に開発を進める

**実際の成果：**
- 3時間で完成したアンケートシステム（EmotiFlow）
- 12個の革新的アイデアを生成
- 100%のテストカバレッジ

## 🎬 5分で動かしてみよう！

### 必要なもの
- Mac または Linux
- tmux（ターミナル分割ツール）
- Claude Code CLI

### 手順

#### 1️⃣ ダウンロード（30秒）
```bash
git clone https://github.com/nishimoto265/Claude-Code-Communication.git
cd Claude-Code-Communication
```

#### 2️⃣ 環境構築（1分）

**単一チーム（デフォルト）の場合：**
```bash
./setup.sh
```

**複数チームを作成する場合：**
```bash
# 標準の開発チームを作成
./setup-team.sh 1

# 役割ベースのチームを作成（出版チーム）
./setup-role-team.sh 2 publishing

# ゲーム開発チームを作成
./setup-role-team.sh 3 game-dev

# チーム管理ツールで確認
./team-manager.sh list
```

これでバックグラウンドに各チームのターミナル画面が準備されます！

#### 3️⃣ 社長画面を開いてAI起動（2分）

**デフォルトチームの場合：**
```bash
# 社長画面を開く
tmux attach-session -t president

# 社長画面でClaudeを起動
claude --dangerously-skip-permissions
```

**チーム番号付きの場合（例：チーム1）：**
```bash
# チーム1の社長画面を開く
tmux attach-session -t president1

# 社長画面でClaudeを起動
claude --dangerously-skip-permissions
```

#### 4️⃣ 部下たちを一括起動（1分）

**デフォルトチームの場合：**
```bash
# 新しいターミナルを開いて
for i in {0..3}; do 
  tmux send-keys -t multiagent.$i 'claude --dangerously-skip-permissions' C-m
done
```

**チーム番号付きの場合（例：チーム1）：**
```bash
# team-managerを使って簡単起動
./team-manager.sh start 1

# または手動で
for i in {0..3}; do 
  tmux send-keys -t multiagent1.$i 'claude --dangerously-skip-permissions' C-m
done
```

#### 5️⃣ 部下たちの画面を確認
・各画面でブラウザでのClaude認証が必要な場合あり
```bash
tmux attach-session -t multiagent
```
これで4分割された画面が表示されます：
```
┌────────┬────────┐
│ boss1  │worker1 │
├────────┼────────┤
│worker2 │worker3 │
└────────┴────────┘
```

#### 6️⃣ 魔法の言葉を入力（30秒）

**デフォルトチームの場合：**
```
あなたはpresidentです。おしゃれな充実したIT企業のホームページを作成して。
```

**チーム番号付きの場合（例：チーム1）：**
```
あなたはpresident1です。チーム1の指示書に従って、おしゃれな充実したIT企業のホームページを作成して。
```

**すると自動的に：**
1. 社長がマネージャーに指示
2. マネージャーが3人の作業者に仕事を割り振り
3. みんなで協力して開発
4. 完成したら社長に報告

## 🏢 登場人物（エージェント）

### 👑 社長（PRESIDENT）
- **役割**: 全体の方針を決める
- **特徴**: ユーザーの本当のニーズを理解する天才
- **口癖**: 「このビジョンを実現してください」

### 🎯 マネージャー（boss1）
- **役割**: チームをまとめる中間管理職
- **特徴**: メンバーの創造性を引き出す達人
- **口癖**: 「革新的なアイデアを3つ以上お願いします」

### 👷 作業者たち（worker1, 2, 3）
- **worker1**: デザイン担当（UI/UX）
- **worker2**: データ処理担当
- **worker3**: テスト担当

## 🎭 役割ベースのチーム構成

標準の開発チーム以外にも、様々な専門チームを作成できます！

### 利用可能なチームタイプ

```bash
# 利用可能な役割を確認
./team-manager.sh roles
```

#### 📚 出版チーム（publishing）
- **AI社長**: 出版ビジョンを持つ経営者
- **AI編集者**: コンテンツの品質管理とディレクション
- **AI小説家×3**: それぞれ異なるジャンルの執筆担当

```bash
# 出版チームを作成
./setup-role-team.sh 1 publishing

# 実行例
./agent-send-team.sh Publisher1 "あなたはPublisher1です。SF小説シリーズを企画してください。"
```

#### 🎨 デザインチーム（design）
- **AI社長**: デザイン会社の経営者
- **AIデザインマネージャー**: プロジェクトの進行管理
- **AIWebデザイナー×3**: UI/UX、グラフィック、インタラクション担当

```bash
# デザインチームを作成
./setup-role-team.sh 2 design

# 実行例
./agent-send-team.sh CEO2 "あなたはCEO2です。革新的なECサイトのデザインを作成してください。"
```

#### 🎮 ゲーム開発チーム（game-dev）
- **AIゲームプロデューサー**: ゲーム全体のビジョン策定
- **AIゲームディレクター**: 開発の実務統括
- **AIゲームプログラマー**: システム実装
- **AIゲームデザイナー**: レベルデザインとバランス調整
- **AIゲームアーティスト**: ビジュアル制作

```bash
# ゲーム開発チームを作成
./setup-role-team.sh 3 game-dev

# 実行例
./agent-send-team.sh GameProducer3 "あなたはGameProducer3です。パズルゲームを開発してください。"
```

#### 🎯 ゲーム企画チーム（game-planning）
- **AIチーフプランナー**: ゲーム企画の統括
- **AIリードプランナー**: 企画の実務管理
- **AIゲームプランナー**: ゲームシステム設計
- **AIレベルデザイナー**: ステージ設計
- **AIストーリーライター**: 世界観とシナリオ

```bash
# ゲーム企画チームを作成
./setup-role-team.sh 4 game-planning

# 実行例
./agent-send-team.sh ChiefPlanner4 "あなたはChiefPlanner4です。新しいRPGの企画書を作成してください。"
```

### 役割ベースチームの管理

```bash
# チーム作成（役割指定）
./team-manager.sh create 5 marketing

# 全チームの状態確認（チームタイプも表示）
./team-manager.sh list

# 出力例：
【チーム1】(出版チーム)
  team1-workers: ✅ 起動中
  team1-leader:  ✅ 起動中
  成果物: 5個

【チーム2】(デザインチーム)
  team2-workers: ✅ 起動中
  team2-leader:  ✅ 起動中
  成果物: 12個
```

## 💬 どうやってコミュニケーションする？

### メッセージの送り方

**デフォルトチーム（従来版）：**
```bash
./agent-send.sh [相手の名前] "[メッセージ]"

# 例：マネージャーに送る
./agent-send.sh boss1 "新しいプロジェクトです"

# 例：作業者1に送る
./agent-send.sh worker1 "UIを作ってください"
```

**複数チーム対応版：**
```bash
./agent-send-team.sh [相手の名前] "[メッセージ]"

# チーム1の例
./agent-send-team.sh president1 "チーム1始動"
./agent-send-team.sh boss1 "チーム1のプロジェクト"
./agent-send-team.sh worker1-1 "チーム1のUI作成"

# チーム2の例
./agent-send-team.sh president2 "チーム2始動"
./agent-send-team.sh worker2-3 "チーム2のテスト実行"

# 現在のチーム一覧を確認
./agent-send-team.sh --list-all
```

### 実際のやり取りの例

**社長 → マネージャー：**
```
あなたはboss1です。

【プロジェクト名】アンケートシステム開発

【ビジョン】
誰でも簡単に使えて、結果がすぐ見られるシステム

【成功基準】
- 3クリックで回答完了
- リアルタイムで結果表示

革新的なアイデアで実現してください。
```

**マネージャー → 作業者：**
```
あなたはworker1です。

【プロジェクト】アンケートシステム

【チャレンジ】
UIデザインの革新的アイデアを3つ以上提案してください。

【フォーマット】
1. アイデア名：[キャッチーな名前]
   概要：[説明]
   革新性：[何が新しいか]
```

## 📁 重要なファイルの説明

### 指示書（instructions/）
各エージェントの行動マニュアルです

**president.md** - 社長の指示書
```markdown
# あなたの役割
最高の経営者として、ユーザーのニーズを理解し、
ビジョンを示してください

# ニーズの5層分析
1. 表層：何を作るか
2. 機能層：何ができるか  
3. 便益層：何が改善されるか
4. 感情層：どう感じたいか
5. 価値層：なぜ重要か
```

**boss.md** - マネージャーの指示書
```markdown
# あなたの役割
天才的なファシリテーターとして、
チームの創造性を最大限に引き出してください

# 10分ルール
10分ごとに進捗を確認し、
困っているメンバーをサポートします
```

**worker.md** - 作業者の指示書
```markdown
# あなたの役割
専門性を活かして、革新的な実装をしてください

# タスク管理
1. やることリストを作る
2. 順番に実行
3. 完了したら報告
```

### CLAUDE.md
システム全体の設定ファイル
```markdown
# Agent Communication System

## エージェント構成
- PRESIDENT: 統括責任者
- boss1: チームリーダー  
- worker1,2,3: 実行担当

## メッセージ送信
./agent-send.sh [相手] "[メッセージ]"
```

## 🎨 実際に作られたもの：EmotiFlow

### 何ができた？
- 😊 絵文字で感情を表現できるアンケート
- 📊 リアルタイムで結果が見られる
- 📱 スマホでも使える

### 試してみる
```bash
# 成果物ディレクトリに移動
cd outputs/default/projects/emotiflow-mvp
python -m http.server 8000
# ブラウザで http://localhost:8000 を開く
```

### ファイル構成
```
emotiflow-mvp/
├── index.html    # メイン画面
├── styles.css    # デザイン
├── script.js     # 動作ロジック
└── tests/        # テスト
```

※ 実際の成果物は `./outputs/default/projects/emotiflow-mvp/` に保存されます

## 🔧 困ったときは

### Q: エージェントが反応しない
```bash
# 状態を確認
tmux ls

# 再起動（デフォルトチーム）
./setup.sh

# 再起動（特定チーム）
./setup-team.sh 1
```

### Q: メッセージが届かない
```bash
# ログを見る（デフォルトチーム）
cat logs/send_log.txt

# ログを見る（チーム1）
cat logs/team1/send_log.txt

# 手動でテスト
./agent-send-team.sh boss1 "テスト"
```

### Q: 最初からやり直したい
```bash
# 全チームをクリーンアップ
./team-manager.sh clean

# 特定チームだけ削除
./team-manager.sh destroy 1
```

## 🚀 自分のプロジェクトを作る

### 簡単な例：TODOアプリを作る

社長（PRESIDENT）で入力：
```
あなたはpresidentです。
TODOアプリを作ってください。
シンプルで使いやすく、タスクの追加・削除・完了ができるものです。
```

すると自動的に：
1. マネージャーがタスクを分解
2. worker1がUI作成
3. worker2がデータ管理
4. worker3がテスト作成
5. 完成！

### 複数チームで並行開発

**チーム1とチーム2を同時に動かす：**
```bash
# チーム1を作成・起動
./team-manager.sh create 1
./team-manager.sh start 1

# チーム2を作成・起動
./team-manager.sh create 2
./team-manager.sh start 2

# チーム1にWebアプリ開発を依頼
./agent-send-team.sh president1 "あなたはpresident1です。チーム1でWebアプリを開発してください。"

# チーム2にAPI開発を依頼
./agent-send-team.sh president2 "あなたはpresident2です。チーム2でAPIサーバーを開発してください。"

# 各チームの状態を確認
./team-manager.sh list
```

## 📊 システムの仕組み（図解）

### 画面構成
```
┌─────────────────┐
│   PRESIDENT     │ ← 社長の画面（紫色）
└─────────────────┘

┌────────┬────────┐
│ boss1  │worker1 │ ← マネージャー（赤）と作業者1（青）
├────────┼────────┤
│worker2 │worker3 │ ← 作業者2と3（青）
└────────┴────────┘
```

### コミュニケーションの流れ
```
社長
 ↓ 「ビジョンを実現して」
マネージャー
 ↓ 「みんな、アイデア出して」
作業者たち
 ↓ 「できました！」
マネージャー
 ↓ 「全員完了です」
社長
```

### 進捗管理の仕組み
```
./tmp/
├── worker1_done.txt     # 作業者1が完了したらできるファイル
├── worker2_done.txt     # 作業者2が完了したらできるファイル
├── worker3_done.txt     # 作業者3が完了したらできるファイル
└── worker*_progress.log # 進捗の記録
```

### 成果物の保存先
```
./outputs/
├── default/             # デフォルトチームの成果物
│   ├── projects/       # プロジェクト成果物
│   ├── docs/           # ドキュメント
│   └── tests/          # テストコード
└── team1/               # チーム1の成果物
    ├── projects/
    ├── docs/
    └── tests/
```

## 💡 なぜこれがすごいの？

### 従来の開発
```
人間 → AI → 結果
```

### このシステム
```
人間 → AI社長 → AIマネージャー → AI作業者×3 → 統合 → 結果
```

**メリット：**
- 並列処理で3倍速い
- 専門性を活かせる
- アイデアが豊富
- 品質が高い

## 🎓 もっと詳しく知りたい人へ

### プロンプトの書き方

**良い例：**
```
あなたはboss1です。

【プロジェクト名】明確な名前
【ビジョン】具体的な理想
【成功基準】測定可能な指標
```

**悪い例：**
```
何か作って
```

### カスタマイズ方法

**新しい作業者を追加：**
1. `instructions/worker4.md`を作成
2. `setup.sh`を編集してペインを追加
3. `agent-send.sh`にマッピングを追加

**タイマーを変更：**
```bash
# instructions/boss.md の中の
sleep 600  # 10分を5分に変更するなら
sleep 300
```

### 複数チームの管理

**チーム管理コマンド：**
```bash
# 標準チーム作成
./team-manager.sh create 1

# 役割ベースチーム作成
./team-manager.sh create 2 publishing
./team-manager.sh create 3 game-dev

# 利用可能な役割を表示
./team-manager.sh roles

# チーム起動
./team-manager.sh start 1

# チーム一覧（チームタイプも表示）
./team-manager.sh list

# チーム詳細
./team-manager.sh status 1

# チーム削除
./team-manager.sh destroy 1

# 全チームクリア
./team-manager.sh clean
```

**チーム間の連携：**
```bash
# チーム1の成果をチーム2に共有
./agent-send-team.sh president2 "チーム1が作成したAPI仕様は./tmp/team1/api-spec.mdにあります。これを参照してフロントエンドを開発してください。"
```

### 🎨 役割ベースチームの活用例

**例1: ゲーム企画→開発の連携**
```bash
# まずゲーム企画チームで企画を作成
./team-manager.sh create 1 game-planning
./team-manager.sh start 1
./agent-send-team.sh ChiefPlanner1 "あなたはChiefPlanner1です。新感覚パズルゲームの企画を作成してください。"

# 企画完成後、開発チームで実装
./team-manager.sh create 2 game-dev
./team-manager.sh start 2
./agent-send-team.sh GameProducer2 "あなたはGameProducer2です。./outputs/team1/docs/game-proposal.mdの企画書を実装してください。"
```

**例2: 小説出版プロジェクト**
```bash
# 出版チームでSF小説シリーズを制作
./team-manager.sh create 3 publishing
./team-manager.sh start 3
./agent-send-team.sh Publisher3 "あなたはPublisher3です。宇宙開拓をテーマにしたSF小説シリーズ（3部作）を企画・執筆してください。"

# 成果物確認
ls ./outputs/team3/projects/novels/
```

**例3: ブランディングプロジェクト**
```bash
# デザインチームでビジュアルアイデンティティ作成
./team-manager.sh create 4 design
./team-manager.sh start 4
./agent-send-team.sh CEO4 "あなたはCEO4です。スタートアップ向けの完全なブランドアイデンティティ（ロゴ、カラーパレット、デザインシステム）を作成してください。"
```

## 🌟 まとめ

このシステムは、複数のAIが協力することで：
- **3時間**で本格的なWebアプリが完成
- **12個**の革新的アイデアを生成
- **100%**のテストカバレッジを実現

ぜひ試してみて、AIチームの力を体験してください！

---

**作者**: [GitHub](https://github.com/nishimoto265/Claude-Code-Communication)
**ライセンス**: MIT
**質問**: [Issues](https://github.com/nishimoto265/Claude-Code-Communication/issues)へどうぞ！
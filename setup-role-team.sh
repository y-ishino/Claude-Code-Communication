#!/bin/bash

# 🚀 Multi-Agent Communication Role-Based Team Setup
# 役割ベースのチーム構成対応版セットアップスクリプト

set -e  # エラー時に停止

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# 使用方法表示
usage() {
    echo "Usage: $0 <team_number> <role_template>"
    echo ""
    echo "Available role templates:"
    echo "  default      - ソフトウェア開発チーム（デフォルト）"
    echo "  publishing   - 出版チーム（AI社長、AI編集者、AI小説家）"
    echo "  design       - デザインチーム（AI社長、AIデザインマネージャー、AIWebデザイナー）"
    echo "  marketing    - マーケティングチーム"
    echo "  research     - 研究開発チーム"
    echo "  game-dev     - ゲーム開発チーム"
    echo "  game-planning - ゲーム企画チーム"
    echo ""
    echo "Example:"
    echo "  $0 1 publishing  # Creates team1 with publishing roles"
    echo "  $0 2 design      # Creates team2 with design roles"
    exit 1
}

# パラメータチェック
if [ $# -lt 2 ]; then
    usage
fi

TEAM_NUM=$1
ROLE_TEMPLATE=$2

# 数値チェック
if ! [[ "$TEAM_NUM" =~ ^[0-9]+$ ]]; then
    log_error "チーム番号は数値で指定してください"
    usage
fi

# jqがインストールされているか確認
if ! command -v jq &> /dev/null; then
    log_error "jqがインストールされていません。先にインストールしてください。"
    echo "Mac: brew install jq"
    echo "Linux: sudo apt-get install jq"
    exit 1
fi

# team-roles.jsonから役割情報を読み込む
ROLES_FILE="./team-roles.json"
if [ ! -f "$ROLES_FILE" ]; then
    log_error "team-roles.jsonが見つかりません"
    exit 1
fi

# テンプレートの存在確認
if ! jq -e ".templates.\"$ROLE_TEMPLATE\"" "$ROLES_FILE" > /dev/null 2>&1; then
    log_error "テンプレート '$ROLE_TEMPLATE' が見つかりません"
    echo "利用可能なテンプレート:"
    jq -r '.templates | keys[]' "$ROLES_FILE"
    exit 1
fi

# 役割情報を取得
TEAM_NAME=$(jq -r ".templates.\"$ROLE_TEMPLATE\".name" "$ROLES_FILE")
LEADER_ROLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".leader.role" "$ROLES_FILE")
LEADER_TITLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".leader.title" "$ROLES_FILE")
MANAGER_ROLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".manager.role" "$ROLES_FILE")
MANAGER_TITLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".manager.title" "$ROLES_FILE")

echo "🤖 Multi-Agent Communication Team${TEAM_NUM} (${TEAM_NAME}) 環境構築"
echo "==========================================="
echo ""

# STEP 1: 既存セッションクリーンアップ
log_info "🧹 Team${TEAM_NUM}の既存セッションクリーンアップ開始..."

tmux kill-session -t "team${TEAM_NUM}-workers" 2>/dev/null && log_info "team${TEAM_NUM}-workersセッション削除完了" || log_info "team${TEAM_NUM}-workersセッションは存在しませんでした"
tmux kill-session -t "team${TEAM_NUM}-leader" 2>/dev/null && log_info "team${TEAM_NUM}-leaderセッション削除完了" || log_info "team${TEAM_NUM}-leaderセッションは存在しませんでした"

# ディレクトリ作成
mkdir -p ./tmp/team${TEAM_NUM}
mkdir -p ./outputs/team${TEAM_NUM}/projects
mkdir -p ./outputs/team${TEAM_NUM}/docs
mkdir -p ./outputs/team${TEAM_NUM}/tests
mkdir -p ./instructions/team${TEAM_NUM}

log_success "✅ クリーンアップ完了"
echo ""

# STEP 2: 役割別指示書のコピー
log_info "📝 役割別指示書を準備中..."

# リーダーの指示書
LEADER_INSTRUCTION=$(jq -r ".templates.\"$ROLE_TEMPLATE\".leader.instruction" "$ROLES_FILE")
if [ -f "./instructions/templates/$LEADER_INSTRUCTION" ]; then
    cp "./instructions/templates/$LEADER_INSTRUCTION" "./instructions/team${TEAM_NUM}/${LEADER_ROLE}.md"
else
    cp "./instructions/president.md" "./instructions/team${TEAM_NUM}/${LEADER_ROLE}.md"
fi

# マネージャーの指示書
MANAGER_INSTRUCTION=$(jq -r ".templates.\"$ROLE_TEMPLATE\".manager.instruction" "$ROLES_FILE")
if [ -f "./instructions/templates/$MANAGER_INSTRUCTION" ]; then
    cp "./instructions/templates/$MANAGER_INSTRUCTION" "./instructions/team${TEAM_NUM}/${MANAGER_ROLE}.md"
else
    cp "./instructions/boss.md" "./instructions/team${TEAM_NUM}/${MANAGER_ROLE}.md"
fi

# ワーカーの指示書
WORKER_COUNT=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers | length" "$ROLES_FILE")
for ((i=0; i<$WORKER_COUNT; i++)); do
    WORKER_ROLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].role" "$ROLES_FILE")
    WORKER_INSTRUCTION=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].instruction" "$ROLES_FILE")
    
    if [ -f "./instructions/templates/$WORKER_INSTRUCTION" ]; then
        cp "./instructions/templates/$WORKER_INSTRUCTION" "./instructions/team${TEAM_NUM}/${WORKER_ROLE}.md"
    else
        cp "./instructions/worker.md" "./instructions/team${TEAM_NUM}/${WORKER_ROLE}.md"
    fi
done

log_success "✅ 指示書の準備完了"
echo ""

# STEP 3: workersセッション作成（4ペイン：マネージャー + ワーカー×3）
log_info "📺 team${TEAM_NUM}-workersセッション作成開始 (${TEAM_NAME})..."

# 最初のペイン作成
tmux new-session -d -s "team${TEAM_NUM}-workers" -n "team${TEAM_NUM}"

# 2x2グリッド作成（合計4ペイン）
tmux split-window -h -t "team${TEAM_NUM}-workers:0"
tmux select-pane -t "team${TEAM_NUM}-workers:0.0"
tmux split-window -v
tmux select-pane -t "team${TEAM_NUM}-workers:0.2"
tmux split-window -v

# ペインタイトル設定
log_info "ペインタイトル設定中..."

# マネージャー設定（ペイン0）
tmux select-pane -t "team${TEAM_NUM}-workers:0.0" -T "${MANAGER_ROLE}${TEAM_NUM}"
tmux send-keys -t "team${TEAM_NUM}-workers:0.0" "cd $(pwd)" C-m
tmux send-keys -t "team${TEAM_NUM}-workers:0.0" "export TEAM_NUM=${TEAM_NUM}" C-m
tmux send-keys -t "team${TEAM_NUM}-workers:0.0" "export ROLE_TEMPLATE=${ROLE_TEMPLATE}" C-m
tmux send-keys -t "team${TEAM_NUM}-workers:0.0" "export OUTPUT_DIR=$(pwd)/outputs/team${TEAM_NUM}" C-m
tmux send-keys -t "team${TEAM_NUM}-workers:0.0" "export PS1='(\[\033[1;31m\]${MANAGER_ROLE}${TEAM_NUM}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
tmux send-keys -t "team${TEAM_NUM}-workers:0.0" "echo '=== ${MANAGER_TITLE} (Team${TEAM_NUM}) ==='" C-m

# ワーカー設定（ペイン1-3）
for ((i=0; i<3 && i<$WORKER_COUNT; i++)); do
    PANE_INDEX=$((i+1))
    WORKER_ROLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].role" "$ROLES_FILE")
    WORKER_TITLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].title" "$ROLES_FILE")
    WORKER_NUM=$((i+1))
    
    tmux select-pane -t "team${TEAM_NUM}-workers:0.$PANE_INDEX" -T "${WORKER_ROLE}${TEAM_NUM}-${WORKER_NUM}"
    tmux send-keys -t "team${TEAM_NUM}-workers:0.$PANE_INDEX" "cd $(pwd)" C-m
    tmux send-keys -t "team${TEAM_NUM}-workers:0.$PANE_INDEX" "export TEAM_NUM=${TEAM_NUM}" C-m
    tmux send-keys -t "team${TEAM_NUM}-workers:0.$PANE_INDEX" "export WORKER_NUM=${WORKER_NUM}" C-m
    tmux send-keys -t "team${TEAM_NUM}-workers:0.$PANE_INDEX" "export ROLE_TEMPLATE=${ROLE_TEMPLATE}" C-m
    tmux send-keys -t "team${TEAM_NUM}-workers:0.$PANE_INDEX" "export OUTPUT_DIR=$(pwd)/outputs/team${TEAM_NUM}" C-m
    tmux send-keys -t "team${TEAM_NUM}-workers:0.$PANE_INDEX" "export PS1='(\[\033[1;34m\]${WORKER_ROLE}${TEAM_NUM}-${WORKER_NUM}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    tmux send-keys -t "team${TEAM_NUM}-workers:0.$PANE_INDEX" "echo '=== ${WORKER_TITLE} ${WORKER_NUM} (Team${TEAM_NUM}) ==='" C-m
done

log_success "✅ team${TEAM_NUM}-workersセッション作成完了"
echo ""

# STEP 4: leaderセッション作成（1ペイン）
log_info "👑 team${TEAM_NUM}-leaderセッション作成開始..."

tmux new-session -d -s "team${TEAM_NUM}-leader"
tmux send-keys -t "team${TEAM_NUM}-leader" "cd $(pwd)" C-m
tmux send-keys -t "team${TEAM_NUM}-leader" "export TEAM_NUM=${TEAM_NUM}" C-m
tmux send-keys -t "team${TEAM_NUM}-leader" "export ROLE_TEMPLATE=${ROLE_TEMPLATE}" C-m
tmux send-keys -t "team${TEAM_NUM}-leader" "export OUTPUT_DIR=$(pwd)/outputs/team${TEAM_NUM}" C-m
tmux send-keys -t "team${TEAM_NUM}-leader" "export PS1='(\[\033[1;35m\]${LEADER_ROLE}${TEAM_NUM}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
tmux send-keys -t "team${TEAM_NUM}-leader" "echo '=== ${LEADER_TITLE} (Team${TEAM_NUM}) ==='" C-m
tmux send-keys -t "team${TEAM_NUM}-leader" "echo '${TEAM_NAME}の統括責任者'" C-m
tmux send-keys -t "team${TEAM_NUM}-leader" "echo '========================'" C-m

log_success "✅ team${TEAM_NUM}-leaderセッション作成完了"
echo ""

# STEP 5: 環境確認・表示
log_info "🔍 環境確認中..."

echo ""
echo "📊 Team${TEAM_NUM} (${TEAM_NAME}) セットアップ結果:"
echo "==================="
echo ""
echo "📺 Tmux Sessions:"
tmux list-sessions | grep -E "team${TEAM_NUM}"
echo ""

# 役割構成表示
echo "📋 Team${TEAM_NUM} 役割構成:"
echo "  team${TEAM_NUM}-leader（1ペイン）:"
echo "    ${LEADER_ROLE}${TEAM_NUM}: ${LEADER_TITLE}"
echo ""
echo "  team${TEAM_NUM}-workers（4ペイン）:"
echo "    Pane 0: ${MANAGER_ROLE}${TEAM_NUM} (${MANAGER_TITLE})"

for ((i=0; i<3 && i<$WORKER_COUNT; i++)); do
    WORKER_ROLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].role" "$ROLES_FILE")
    WORKER_TITLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].title" "$ROLES_FILE")
    WORKER_NUM=$((i+1))
    echo "    Pane $((i+1)): ${WORKER_ROLE}${TEAM_NUM}-${WORKER_NUM} (${WORKER_TITLE})"
done

echo ""
echo "📁 成果物ディレクトリ:"
echo "  ./outputs/team${TEAM_NUM}/"
echo "    ├── projects/  # プロジェクト成果物"
echo "    ├── docs/      # ドキュメント"
echo "    └── tests/     # テストコード"

echo ""
log_success "🎉 Team${TEAM_NUM} (${TEAM_NAME}) 環境セットアップ完了！"
echo ""
echo "📋 次のステップ:"
echo "  1. 🔗 セッションアタッチ:"
echo "     tmux attach-session -t team${TEAM_NUM}-workers   # ワーカー画面確認"
echo "     tmux attach-session -t team${TEAM_NUM}-leader    # リーダー画面確認"
echo ""
echo "  2. 🤖 Claude Code起動:"
echo "     # リーダー認証"
echo "     tmux send-keys -t team${TEAM_NUM}-leader 'claude' C-m"
echo "     # ワーカー一括起動"
echo "     for i in {0..3}; do tmux send-keys -t team${TEAM_NUM}-workers:0.\$i 'claude' C-m; done"
echo ""
echo "  3. 📜 指示書確認:"
echo "     ./instructions/team${TEAM_NUM}/ 内の各役割の指示書"
echo ""
echo "  4. 🎯 実行: ${LEADER_ROLE}${TEAM_NUM}に「あなたは${LEADER_ROLE}${TEAM_NUM}です。」と入力"
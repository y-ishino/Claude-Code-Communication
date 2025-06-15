#!/bin/bash

# 🚀 Multi-Agent Communication Team Setup
# 複数チーム対応版セットアップスクリプト

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
    echo "Usage: $0 <team_number>"
    echo "Example: $0 1  # Creates team1 with president1, boss1, worker1-1,2,3"
    echo "         $0 2  # Creates team2 with president2, boss2, worker2-1,2,3"
    exit 1
}

# パラメータチェック
if [ $# -ne 1 ]; then
    usage
fi

TEAM_NUM=$1

# 数値チェック
if ! [[ "$TEAM_NUM" =~ ^[0-9]+$ ]]; then
    log_error "チーム番号は数値で指定してください"
    usage
fi

echo "🤖 Multi-Agent Communication Team${TEAM_NUM} 環境構築"
echo "==========================================="
echo ""

# STEP 1: 既存セッションクリーンアップ
log_info "🧹 Team${TEAM_NUM}の既存セッションクリーンアップ開始..."

tmux kill-session -t "multiagent${TEAM_NUM}" 2>/dev/null && log_info "multiagent${TEAM_NUM}セッション削除完了" || log_info "multiagent${TEAM_NUM}セッションは存在しませんでした"
tmux kill-session -t "president${TEAM_NUM}" 2>/dev/null && log_info "president${TEAM_NUM}セッション削除完了" || log_info "president${TEAM_NUM}セッションは存在しませんでした"

# 完了ファイルクリア
mkdir -p ./tmp/team${TEAM_NUM}
rm -f ./tmp/team${TEAM_NUM}/worker*_done.txt 2>/dev/null && log_info "Team${TEAM_NUM}の完了ファイルをクリア" || log_info "完了ファイルは存在しませんでした"

# 成果物ディレクトリ作成
log_info "Team${TEAM_NUM}の成果物ディレクトリを作成中..."
mkdir -p ./outputs/team${TEAM_NUM}/projects
mkdir -p ./outputs/team${TEAM_NUM}/docs
mkdir -p ./outputs/team${TEAM_NUM}/tests
log_info "Team${TEAM_NUM}の成果物ディレクトリを作成完了"

log_success "✅ クリーンアップ完了"
echo ""

# STEP 2: multiagentセッション作成（4ペイン：boss + worker1,2,3）
log_info "📺 multiagent${TEAM_NUM}セッション作成開始 (4ペイン)..."

# 最初のペイン作成
tmux new-session -d -s "multiagent${TEAM_NUM}" -n "agents"

# 2x2グリッド作成（合計4ペイン）
tmux split-window -h -t "multiagent${TEAM_NUM}:0"      # 水平分割（左右）
tmux select-pane -t "multiagent${TEAM_NUM}:0.0"
tmux split-window -v                                    # 左側を垂直分割
tmux select-pane -t "multiagent${TEAM_NUM}:0.2"
tmux split-window -v                                    # 右側を垂直分割

# ペインタイトル設定
log_info "ペインタイトル設定中..."
PANE_TITLES=("boss${TEAM_NUM}" "worker${TEAM_NUM}-1" "worker${TEAM_NUM}-2" "worker${TEAM_NUM}-3")

for i in {0..3}; do
    tmux select-pane -t "multiagent${TEAM_NUM}:0.$i" -T "${PANE_TITLES[$i]}"
    
    # 作業ディレクトリ設定
    tmux send-keys -t "multiagent${TEAM_NUM}:0.$i" "cd $(pwd)" C-m
    
    # チーム番号と成果物ディレクトリ環境変数設定
    tmux send-keys -t "multiagent${TEAM_NUM}:0.$i" "export TEAM_NUM=${TEAM_NUM}" C-m
    tmux send-keys -t "multiagent${TEAM_NUM}:0.$i" "export OUTPUT_DIR=$(pwd)/outputs/team${TEAM_NUM}" C-m
    
    # カラープロンプト設定（チーム番号で色を変える）
    if [ $i -eq 0 ]; then
        # boss: 赤系（チーム番号で微妙に色を変える）
        COLOR_CODE=$((31 + (TEAM_NUM % 7)))
        tmux send-keys -t "multiagent${TEAM_NUM}:0.$i" "export PS1='(\[\033[1;${COLOR_CODE}m\]${PANE_TITLES[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    else
        # workers: 青系（チーム番号で微妙に色を変える）
        COLOR_CODE=$((34 + (TEAM_NUM % 3)))
        tmux send-keys -t "multiagent${TEAM_NUM}:0.$i" "export PS1='(\[\033[1;${COLOR_CODE}m\]${PANE_TITLES[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    fi
    
    # ウェルカムメッセージ
    tmux send-keys -t "multiagent${TEAM_NUM}:0.$i" "echo '=== ${PANE_TITLES[$i]} エージェント (Team${TEAM_NUM}) ==='" C-m
done

log_success "✅ multiagent${TEAM_NUM}セッション作成完了"
echo ""

# STEP 3: presidentセッション作成（1ペイン）
log_info "👑 president${TEAM_NUM}セッション作成開始..."

tmux new-session -d -s "president${TEAM_NUM}"
tmux send-keys -t "president${TEAM_NUM}" "cd $(pwd)" C-m
tmux send-keys -t "president${TEAM_NUM}" "export TEAM_NUM=${TEAM_NUM}" C-m
tmux send-keys -t "president${TEAM_NUM}" "export OUTPUT_DIR=$(pwd)/outputs/team${TEAM_NUM}" C-m

# プレジデントの色（チーム番号で変える）
COLOR_CODE=$((35 + (TEAM_NUM % 2)))
tmux send-keys -t "president${TEAM_NUM}" "export PS1='(\[\033[1;${COLOR_CODE}m\]PRESIDENT${TEAM_NUM}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
tmux send-keys -t "president${TEAM_NUM}" "echo '=== PRESIDENT${TEAM_NUM} セッション ==='" C-m
tmux send-keys -t "president${TEAM_NUM}" "echo 'Team${TEAM_NUM} プロジェクト統括責任者'" C-m
tmux send-keys -t "president${TEAM_NUM}" "echo '========================'" C-m

log_success "✅ president${TEAM_NUM}セッション作成完了"
echo ""

# STEP 4: 環境確認・表示
log_info "🔍 環境確認中..."

echo ""
echo "📊 Team${TEAM_NUM} セットアップ結果:"
echo "==================="
echo ""
echo "📁 成果物ディレクトリ:"
echo "  ./outputs/team${TEAM_NUM}/"
echo "    ├── projects/  # プロジェクト成果物"
echo "    ├── docs/      # ドキュメント"
echo "    └── tests/     # テストコード"

# tmuxセッション確認
echo "📺 Team${TEAM_NUM} Tmux Sessions:"
tmux list-sessions | grep -E "(multiagent${TEAM_NUM}|president${TEAM_NUM})"
echo ""

# ペイン構成表示
echo "📋 Team${TEAM_NUM} ペイン構成:"
echo "  multiagent${TEAM_NUM}セッション（4ペイン）:"
echo "    Pane 0: boss${TEAM_NUM}       (チームリーダー)"
echo "    Pane 1: worker${TEAM_NUM}-1   (実行担当者A)"
echo "    Pane 2: worker${TEAM_NUM}-2   (実行担当者B)"
echo "    Pane 3: worker${TEAM_NUM}-3   (実行担当者C)"
echo ""
echo "  president${TEAM_NUM}セッション（1ペイン）:"
echo "    Pane 0: PRESIDENT${TEAM_NUM}   (プロジェクト統括)"

echo ""
log_success "🎉 Team${TEAM_NUM} 環境セットアップ完了！"
echo ""
echo "📋 次のステップ:"
echo "  1. 🔗 セッションアタッチ:"
echo "     tmux attach-session -t multiagent${TEAM_NUM}   # Team${TEAM_NUM}マルチエージェント確認"
echo "     tmux attach-session -t president${TEAM_NUM}    # Team${TEAM_NUM}プレジデント確認"
echo ""
echo "  2. 🤖 Claude Code起動:"
echo "     # 手順1: President${TEAM_NUM}認証"
echo "     tmux send-keys -t president${TEAM_NUM} 'claude' C-m"
echo "     # 手順2: 認証後、multiagent${TEAM_NUM}一括起動"
echo "     for i in {0..3}; do tmux send-keys -t multiagent${TEAM_NUM}:0.\$i 'claude' C-m; done"
echo ""
echo "  3. 📜 指示書確認:"
echo "     PRESIDENT${TEAM_NUM}: instructions/president.md"
echo "     boss${TEAM_NUM}: instructions/boss.md"
echo "     worker${TEAM_NUM}-1,2,3: instructions/worker.md"
echo "     システム構造: CLAUDE.md"
echo ""
echo "  4. 🎯 実行: PRESIDENT${TEAM_NUM}に「あなたはpresident${TEAM_NUM}です。チーム${TEAM_NUM}の指示書に従って」と入力"
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
    echo "🚀 Multi-Agent Communication Setup (統合版)"
    echo ""
    echo "Usage:"
    echo "  $0                                    # デフォルトチーム作成"
    echo "  $0 <team_number>                     # 従来形式チーム作成"
    echo "  $0 <team_number> <role_template>     # 役割ベースチーム作成"
    echo "  $0 <team_number> <role_template> --auto-start  # 自動起動付き"
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
    echo "Options:"
    echo "  --auto-start  Claude Code起動と指示書読み込みを自動実行"
    echo ""
    echo "Examples:"
    echo "  $0                           # デフォルトチーム（president, boss1, worker1-3）"
    echo "  $0 1                         # チーム1（従来形式: president1, boss1, worker1-1,2,3）"
    echo "  $0 1 publishing              # 出版チーム1（Publisher1, Editor1, Novelist1-1,2,3）"
    echo "  $0 2 design --auto-start     # デザインチーム2（自動起動付き）"
    exit 1
}

# パラメータ解析と設定
TEAM_NUM=""
ROLE_TEMPLATE=""
AUTO_START=false
SETUP_MODE=""

# 引数の解析
case $# in
    0)
        # デフォルトチーム
        SETUP_MODE="default"
        ;;
    1)
        if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
            usage
        elif [[ "$1" =~ ^[0-9]+$ ]]; then
            # 従来形式チーム
            TEAM_NUM=$1
            SETUP_MODE="legacy"
        else
            log_error "チーム番号は数値で指定してください"
            usage
        fi
        ;;
    2)
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            TEAM_NUM=$1
            if [ "$2" = "--auto-start" ]; then
                # 従来形式 + 自動起動
                SETUP_MODE="legacy"
                AUTO_START=true
            else
                # 役割ベース
                ROLE_TEMPLATE=$2
                SETUP_MODE="role-based"
            fi
        else
            log_error "チーム番号は数値で指定してください"
            usage
        fi
        ;;
    3)
        if [[ "$1" =~ ^[0-9]+$ ]] && [ "$3" = "--auto-start" ]; then
            # 役割ベース + 自動起動
            TEAM_NUM=$1
            ROLE_TEMPLATE=$2
            SETUP_MODE="role-based"
            AUTO_START=true
        else
            log_error "無効な引数です"
            usage
        fi
        ;;
    *)
        usage
        ;;
esac

# 役割ベースモードの場合のみjqチェック
if [ "$SETUP_MODE" = "role-based" ]; then
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
else
    # デフォルト・従来形式の場合の設定
    case "$SETUP_MODE" in
        "default")
            TEAM_NAME="デフォルトチーム"
            LEADER_ROLE="PRESIDENT"
            LEADER_TITLE="プロジェクト統括責任者"
            MANAGER_ROLE="boss1"
            MANAGER_TITLE="チームリーダー"
            ;;
        "legacy")
            TEAM_NAME="開発チーム${TEAM_NUM}"
            LEADER_ROLE="PRESIDENT${TEAM_NUM}"
            LEADER_TITLE="プロジェクト統括責任者"
            MANAGER_ROLE="boss${TEAM_NUM}"
            MANAGER_TITLE="チームリーダー"
            ;;
    esac
fi

# セットアップモード別の表示とセッション名設定
case "$SETUP_MODE" in
    "default")
        echo "🤖 Multi-Agent Communication ${TEAM_NAME} 環境構築"
        echo "==========================================="
        LEADER_SESSION="president"
        WORKERS_SESSION="multiagent"
        OUTPUT_DIR="./outputs/default"
        TMP_DIR="./tmp"
        INSTRUCTIONS_DIR="./instructions"
        WORKSPACE_DIR="./team-workspace"
        ;;
    "legacy")
        echo "🤖 Multi-Agent Communication ${TEAM_NAME} 環境構築"
        echo "==========================================="
        LEADER_SESSION="president${TEAM_NUM}"
        WORKERS_SESSION="multiagent${TEAM_NUM}"
        OUTPUT_DIR="./outputs/team${TEAM_NUM}"
        TMP_DIR="./tmp/team${TEAM_NUM}"
        INSTRUCTIONS_DIR="./instructions"
        WORKSPACE_DIR="./team-workspace/team${TEAM_NUM}"
        ;;
    "role-based")
        echo "🤖 Multi-Agent Communication Team${TEAM_NUM} (${TEAM_NAME}) 環境構築"
        echo "==========================================="
        LEADER_SESSION="team${TEAM_NUM}-leader"
        WORKERS_SESSION="team${TEAM_NUM}-workers"
        OUTPUT_DIR="./outputs/team${TEAM_NUM}"
        TMP_DIR="./tmp/team${TEAM_NUM}"
        INSTRUCTIONS_DIR="./instructions/team${TEAM_NUM}"
        WORKSPACE_DIR="./team-workspace/team${TEAM_NUM}"
        ;;
esac
echo ""

# STEP 1: 既存セッションクリーンアップ
if [ "$SETUP_MODE" = "default" ]; then
    log_info "🧹 デフォルトチームの既存セッションクリーンアップ開始..."
    tmux kill-session -t "multiagent" 2>/dev/null && log_info "multiagentセッション削除完了" || log_info "multiagentセッションは存在しませんでした"
    tmux kill-session -t "president" 2>/dev/null && log_info "presidentセッション削除完了" || log_info "presidentセッションは存在しませんでした"
    rm -f ./tmp/worker*_done.txt 2>/dev/null && log_info "既存の完了ファイルをクリア" || log_info "完了ファイルは存在しませんでした"
else
    log_info "🧹 Team${TEAM_NUM}の既存セッションクリーンアップ開始..."
    tmux kill-session -t "$WORKERS_SESSION" 2>/dev/null && log_info "${WORKERS_SESSION}セッション削除完了" || log_info "${WORKERS_SESSION}セッションは存在しませんでした"
    tmux kill-session -t "$LEADER_SESSION" 2>/dev/null && log_info "${LEADER_SESSION}セッション削除完了" || log_info "${LEADER_SESSION}セッションは存在しませんでした"
    rm -f ${TMP_DIR}/worker*_done.txt 2>/dev/null && log_info "Team${TEAM_NUM}の完了ファイルをクリア" || log_info "完了ファイルは存在しませんでした"
fi

# ディレクトリ作成
mkdir -p $TMP_DIR
mkdir -p ${OUTPUT_DIR}/projects
mkdir -p ${OUTPUT_DIR}/docs
mkdir -p ${OUTPUT_DIR}/tests
mkdir -p $INSTRUCTIONS_DIR
if [ "$SETUP_MODE" = "role-based" ]; then
    mkdir -p ${WORKSPACE_DIR}/{deliverables,dependencies,communications,decisions}
fi

log_success "✅ クリーンアップ完了"
echo ""

# STEP 2: 指示書の準備
if [ "$SETUP_MODE" = "role-based" ]; then
    log_info "📝 ビルド済み指示書を確認中..."

    # ビルド済み指示書の存在確認
    BUILT_INSTRUCTIONS_DIR="./instructions-built/teams/$ROLE_TEMPLATE"
    if [ ! -d "$BUILT_INSTRUCTIONS_DIR" ]; then
        log_error "ビルド済み指示書が見つかりません: $BUILT_INSTRUCTIONS_DIR"
        log_info "先に指示書をビルドしてください:"
        log_info "  ./build-instructions.sh"
        exit 1
    fi

    # ビルド済み指示書をチーム用にコピー
    log_info "ビルド済み指示書をチーム${TEAM_NUM}用にコピー中..."
    cp -r "$BUILT_INSTRUCTIONS_DIR"/* "$INSTRUCTIONS_DIR/"

    log_success "✅ 指示書の準備完了"
else
    log_info "📝 従来形式の指示書を使用します"
    log_success "✅ 指示書の準備完了"
fi
echo ""

# STEP 3: workersセッション作成（4ペイン：マネージャー + ワーカー×3）
log_info "📺 ${WORKERS_SESSION}セッション作成開始 (${TEAM_NAME})..."

# 最初のペイン作成
if [ "$SETUP_MODE" = "default" ]; then
    tmux new-session -d -s "$WORKERS_SESSION" -n "agents"
else
    tmux new-session -d -s "$WORKERS_SESSION" -n "team${TEAM_NUM}"
fi

# 2x2グリッド作成（合計4ペイン）
tmux split-window -h -t "${WORKERS_SESSION}:0"
tmux select-pane -t "${WORKERS_SESSION}:0.0"
tmux split-window -v
tmux select-pane -t "${WORKERS_SESSION}:0.2"
tmux split-window -v

# ペインタイトル設定
log_info "ペインタイトル設定中..."

if [ "$SETUP_MODE" = "role-based" ]; then
    # 役割ベース：マネージャー設定（ペイン0）
    tmux select-pane -t "${WORKERS_SESSION}:0.0" -T "${MANAGER_ROLE}${TEAM_NUM}"
    tmux send-keys -t "${WORKERS_SESSION}:0.0" "cd $(pwd)" C-m
    tmux send-keys -t "${WORKERS_SESSION}:0.0" "export TEAM_NUM=${TEAM_NUM}" C-m
    tmux send-keys -t "${WORKERS_SESSION}:0.0" "export ROLE_TEMPLATE=${ROLE_TEMPLATE}" C-m
    tmux send-keys -t "${WORKERS_SESSION}:0.0" "export OUTPUT_DIR=${OUTPUT_DIR}" C-m
    tmux send-keys -t "${WORKERS_SESSION}:0.0" "export PS1='(\[\033[1;31m\]${MANAGER_ROLE}${TEAM_NUM}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    tmux send-keys -t "${WORKERS_SESSION}:0.0" "echo '=== ${MANAGER_TITLE} (Team${TEAM_NUM}) ==='" C-m

    # 役割ベース：ワーカー設定（ペイン1-3）
    WORKER_COUNT=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers | length" "$ROLES_FILE")
    for ((i=0; i<3 && i<$WORKER_COUNT; i++)); do
        PANE_INDEX=$((i+1))
        WORKER_ROLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].role" "$ROLES_FILE")
        WORKER_TITLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].title" "$ROLES_FILE")
        WORKER_NUM=$((i+1))
        
        tmux select-pane -t "${WORKERS_SESSION}:0.$PANE_INDEX" -T "${WORKER_ROLE}${TEAM_NUM}-${WORKER_NUM}"
        tmux send-keys -t "${WORKERS_SESSION}:0.$PANE_INDEX" "cd $(pwd)" C-m
        tmux send-keys -t "${WORKERS_SESSION}:0.$PANE_INDEX" "export TEAM_NUM=${TEAM_NUM}" C-m
        tmux send-keys -t "${WORKERS_SESSION}:0.$PANE_INDEX" "export WORKER_NUM=${WORKER_NUM}" C-m
        tmux send-keys -t "${WORKERS_SESSION}:0.$PANE_INDEX" "export ROLE_TEMPLATE=${ROLE_TEMPLATE}" C-m
        tmux send-keys -t "${WORKERS_SESSION}:0.$PANE_INDEX" "export OUTPUT_DIR=${OUTPUT_DIR}" C-m
        tmux send-keys -t "${WORKERS_SESSION}:0.$PANE_INDEX" "export PS1='(\[\033[1;34m\]${WORKER_ROLE}${TEAM_NUM}-${WORKER_NUM}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
        tmux send-keys -t "${WORKERS_SESSION}:0.$PANE_INDEX" "echo '=== ${WORKER_TITLE} ${WORKER_NUM} (Team${TEAM_NUM}) ==='" C-m
    done
else
    # デフォルト・従来形式：統一設定
    if [ "$SETUP_MODE" = "default" ]; then
        PANE_TITLES=("boss1" "worker1" "worker2" "worker3")
    else
        PANE_TITLES=("boss${TEAM_NUM}" "worker${TEAM_NUM}-1" "worker${TEAM_NUM}-2" "worker${TEAM_NUM}-3")
    fi

    for i in {0..3}; do
        tmux select-pane -t "${WORKERS_SESSION}:0.$i" -T "${PANE_TITLES[$i]}"
        
        # 作業ディレクトリ設定
        tmux send-keys -t "${WORKERS_SESSION}:0.$i" "cd $(pwd)" C-m
        
        # 環境変数設定
        if [ "$SETUP_MODE" != "default" ]; then
            tmux send-keys -t "${WORKERS_SESSION}:0.$i" "export TEAM_NUM=${TEAM_NUM}" C-m
        fi
        if [ "$SETUP_MODE" = "role-based" ]; then
            tmux send-keys -t "${WORKERS_SESSION}:0.$i" "export ROLE_TEMPLATE=${ROLE_TEMPLATE}" C-m
        fi
        tmux send-keys -t "${WORKERS_SESSION}:0.$i" "export OUTPUT_DIR=${OUTPUT_DIR}" C-m
        
        # カラープロンプト設定
        if [ $i -eq 0 ]; then
            # boss: 赤系
            if [ "$SETUP_MODE" = "default" ]; then
                COLOR_CODE=31
            else
                COLOR_CODE=$((31 + (TEAM_NUM % 7)))
            fi
            tmux send-keys -t "${WORKERS_SESSION}:0.$i" "export PS1='(\[\033[1;${COLOR_CODE}m\]${PANE_TITLES[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
        else
            # workers: 青系
            if [ "$SETUP_MODE" = "default" ]; then
                COLOR_CODE=34
            else
                COLOR_CODE=$((34 + (TEAM_NUM % 3)))
            fi
            tmux send-keys -t "${WORKERS_SESSION}:0.$i" "export PS1='(\[\033[1;${COLOR_CODE}m\]${PANE_TITLES[$i]}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
        fi
        
        # ウェルカムメッセージ
        if [ "$SETUP_MODE" = "default" ]; then
            tmux send-keys -t "${WORKERS_SESSION}:0.$i" "echo '=== ${PANE_TITLES[$i]} エージェント ==='" C-m
        else
            tmux send-keys -t "${WORKERS_SESSION}:0.$i" "echo '=== ${PANE_TITLES[$i]} エージェント (Team${TEAM_NUM}) ==='" C-m
        fi
    done
fi

log_success "✅ ${WORKERS_SESSION}セッション作成完了"
echo ""

# STEP 4: leaderセッション作成（1ペイン）
log_info "👑 ${LEADER_SESSION}セッション作成開始..."

tmux new-session -d -s "$LEADER_SESSION"
tmux send-keys -t "$LEADER_SESSION" "cd $(pwd)" C-m

# 環境変数設定
if [ "$SETUP_MODE" != "default" ]; then
    tmux send-keys -t "$LEADER_SESSION" "export TEAM_NUM=${TEAM_NUM}" C-m
fi
if [ "$SETUP_MODE" = "role-based" ]; then
    tmux send-keys -t "$LEADER_SESSION" "export ROLE_TEMPLATE=${ROLE_TEMPLATE}" C-m
fi
tmux send-keys -t "$LEADER_SESSION" "export OUTPUT_DIR=${OUTPUT_DIR}" C-m

# プロンプト設定
if [ "$SETUP_MODE" = "default" ]; then
    tmux send-keys -t "$LEADER_SESSION" "export PS1='(\[\033[1;35m\]PRESIDENT\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    tmux send-keys -t "$LEADER_SESSION" "echo '=== PRESIDENT セッション ==='" C-m
    tmux send-keys -t "$LEADER_SESSION" "echo 'プロジェクト統括責任者'" C-m
elif [ "$SETUP_MODE" = "legacy" ]; then
    COLOR_CODE=$((35 + (TEAM_NUM % 2)))
    tmux send-keys -t "$LEADER_SESSION" "export PS1='(\[\033[1;${COLOR_CODE}m\]PRESIDENT${TEAM_NUM}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    tmux send-keys -t "$LEADER_SESSION" "echo '=== PRESIDENT${TEAM_NUM} セッション ==='" C-m
    tmux send-keys -t "$LEADER_SESSION" "echo 'Team${TEAM_NUM} プロジェクト統括責任者'" C-m
else
    tmux send-keys -t "$LEADER_SESSION" "export PS1='(\[\033[1;35m\]${LEADER_ROLE}${TEAM_NUM}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ '" C-m
    tmux send-keys -t "$LEADER_SESSION" "echo '=== ${LEADER_TITLE} (Team${TEAM_NUM}) ==='" C-m
    tmux send-keys -t "$LEADER_SESSION" "echo '${TEAM_NAME}の統括責任者'" C-m
fi
tmux send-keys -t "$LEADER_SESSION" "echo '========================'" C-m

log_success "✅ ${LEADER_SESSION}セッション作成完了"
echo ""

# STEP 5: 自動起動オプション処理
if [ "$AUTO_START" = true ]; then
    log_info "🚀 Claude Code自動起動と指示書読み込み開始..."
    
    # Claude Code起動
    log_info "Claude Code起動中..."
    tmux send-keys -t "$LEADER_SESSION" "claude" C-m
    sleep 3
    
    for i in {0..3}; do
        tmux send-keys -t "${WORKERS_SESSION}:0.$i" "claude" C-m
        sleep 1
    done
    
    log_info "Claude Code起動完了。指示書読み込み開始..."
    sleep 5
    
    if [ "$SETUP_MODE" = "role-based" ]; then
        # 役割ベース：指示書読み込み
        # リーダーに指示書読み込み
        LEADER_INSTRUCTION_FILE="${INSTRUCTIONS_DIR}/${LEADER_ROLE}.md"
        if [ -f "$LEADER_INSTRUCTION_FILE" ]; then
            log_info "リーダー指示書読み込み中..."
            tmux send-keys -t "$LEADER_SESSION" "@$LEADER_INSTRUCTION_FILE" C-m
            sleep 2
            tmux send-keys -t "$LEADER_SESSION" "あなたは${LEADER_ROLE}${TEAM_NUM}です。" C-m
            sleep 1
        fi
        
        # マネージャーに指示書読み込み
        MANAGER_INSTRUCTION_FILE="${INSTRUCTIONS_DIR}/${MANAGER_ROLE}.md"
        if [ -f "$MANAGER_INSTRUCTION_FILE" ]; then
            log_info "マネージャー指示書読み込み中..."
            tmux send-keys -t "${WORKERS_SESSION}:0.0" "@$MANAGER_INSTRUCTION_FILE" C-m
            sleep 2
            tmux send-keys -t "${WORKERS_SESSION}:0.0" "あなたは${MANAGER_ROLE}${TEAM_NUM}です。" C-m
            sleep 1
        fi
        
        # ワーカーに指示書読み込み
        WORKER_COUNT=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers | length" "$ROLES_FILE")
        for ((i=0; i<3 && i<$WORKER_COUNT; i++)); do
            PANE_INDEX=$((i+1))
            WORKER_ROLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].role" "$ROLES_FILE")
            WORKER_NUM=$((i+1))
            WORKER_INSTRUCTION_FILE="${INSTRUCTIONS_DIR}/${WORKER_ROLE}.md"
            
            if [ -f "$WORKER_INSTRUCTION_FILE" ]; then
                log_info "ワーカー${WORKER_NUM}指示書読み込み中..."
                tmux send-keys -t "${WORKERS_SESSION}:0.$PANE_INDEX" "@$WORKER_INSTRUCTION_FILE" C-m
                sleep 2
                tmux send-keys -t "${WORKERS_SESSION}:0.$PANE_INDEX" "あなたは${WORKER_ROLE}${TEAM_NUM}-${WORKER_NUM}です。" C-m
                sleep 1
            fi
        done
    else
        # デフォルト・従来形式：従来の指示書読み込み
        log_info "従来形式の指示書読み込み中..."
        
        # リーダー指示書
        if [ "$SETUP_MODE" = "default" ]; then
            PRESIDENT_FILE="./instructions/president.md"
            if [ -f "$PRESIDENT_FILE" ]; then
                tmux send-keys -t "$LEADER_SESSION" "@$PRESIDENT_FILE" C-m
                sleep 2
                tmux send-keys -t "$LEADER_SESSION" "あなたはpresidentです。" C-m
                sleep 1
            fi
        else
            PRESIDENT_FILE="./instructions/president.md"
            if [ -f "$PRESIDENT_FILE" ]; then
                tmux send-keys -t "$LEADER_SESSION" "@$PRESIDENT_FILE" C-m
                sleep 2
                tmux send-keys -t "$LEADER_SESSION" "あなたはpresident${TEAM_NUM}です。" C-m
                sleep 1
            fi
        fi
        
        # マネージャー・ワーカー指示書
        BOSS_FILE="./instructions/boss.md"
        WORKER_FILE="./instructions/worker.md"
        
        if [ -f "$BOSS_FILE" ]; then
            tmux send-keys -t "${WORKERS_SESSION}:0.0" "@$BOSS_FILE" C-m
            sleep 2
            if [ "$SETUP_MODE" = "default" ]; then
                tmux send-keys -t "${WORKERS_SESSION}:0.0" "あなたはboss1です。" C-m
            else
                tmux send-keys -t "${WORKERS_SESSION}:0.0" "あなたはboss${TEAM_NUM}です。" C-m
            fi
            sleep 1
        fi
        
        if [ -f "$WORKER_FILE" ]; then
            for i in {1..3}; do
                tmux send-keys -t "${WORKERS_SESSION}:0.$i" "@$WORKER_FILE" C-m
                sleep 2
                if [ "$SETUP_MODE" = "default" ]; then
                    tmux send-keys -t "${WORKERS_SESSION}:0.$i" "あなたはworker${i}です。" C-m
                else
                    tmux send-keys -t "${WORKERS_SESSION}:0.$i" "あなたはworker${TEAM_NUM}-${i}です。" C-m
                fi
                sleep 1
            done
        fi
    fi
    
    log_success "✅ 自動起動と指示書読み込み完了"
    echo ""
fi

# STEP 6: 環境確認・表示
log_info "🔍 環境確認中..."

echo ""
if [ "$SETUP_MODE" = "default" ]; then
    echo "📊 ${TEAM_NAME} セットアップ結果:"
else
    echo "📊 Team${TEAM_NUM} (${TEAM_NAME}) セットアップ結果:"
fi
echo "==================="
echo ""

# tmuxセッション確認
echo "📺 Tmux Sessions:"
if [ "$SETUP_MODE" = "default" ]; then
    tmux list-sessions | grep -E "(multiagent|president)"
else
    tmux list-sessions | grep -E "(team${TEAM_NUM}|multiagent${TEAM_NUM}|president${TEAM_NUM})"
fi
echo ""

# 役割構成表示
if [ "$SETUP_MODE" = "role-based" ]; then
    echo "📋 Team${TEAM_NUM} 役割構成:"
    echo "  ${LEADER_SESSION}（1ペイン）:"
    echo "    ${LEADER_ROLE}${TEAM_NUM}: ${LEADER_TITLE}"
    echo ""
    echo "  ${WORKERS_SESSION}（4ペイン）:"
    echo "    Pane 0: ${MANAGER_ROLE}${TEAM_NUM} (${MANAGER_TITLE})"

    WORKER_COUNT=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers | length" "$ROLES_FILE")
    for ((i=0; i<3 && i<$WORKER_COUNT; i++)); do
        WORKER_ROLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].role" "$ROLES_FILE")
        WORKER_TITLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].title" "$ROLES_FILE")
        WORKER_NUM=$((i+1))
        echo "    Pane $((i+1)): ${WORKER_ROLE}${TEAM_NUM}-${WORKER_NUM} (${WORKER_TITLE})"
    done
elif [ "$SETUP_MODE" = "legacy" ]; then
    echo "📋 Team${TEAM_NUM} ペイン構成:"
    echo "  ${WORKERS_SESSION}セッション（4ペイン）:"
    echo "    Pane 0: boss${TEAM_NUM}       (チームリーダー)"
    echo "    Pane 1: worker${TEAM_NUM}-1   (実行担当者A)"
    echo "    Pane 2: worker${TEAM_NUM}-2   (実行担当者B)"
    echo "    Pane 3: worker${TEAM_NUM}-3   (実行担当者C)"
    echo ""
    echo "  ${LEADER_SESSION}セッション（1ペイン）:"
    echo "    Pane 0: PRESIDENT${TEAM_NUM}   (プロジェクト統括)"
else
    echo "📋 ペイン構成:"
    echo "  ${WORKERS_SESSION}セッション（4ペイン）:"
    echo "    Pane 0: boss1     (チームリーダー)"
    echo "    Pane 1: worker1   (実行担当者A)"
    echo "    Pane 2: worker2   (実行担当者B)"
    echo "    Pane 3: worker3   (実行担当者C)"
    echo ""
    echo "  ${LEADER_SESSION}セッション（1ペイン）:"
    echo "    Pane 0: PRESIDENT (プロジェクト統括)"
fi

echo ""
echo "📁 成果物ディレクトリ:"
echo "  ${OUTPUT_DIR}/"
echo "    ├── projects/  # プロジェクト成果物"
echo "    ├── docs/      # ドキュメント"
echo "    └── tests/     # テストコード"

if [ "$SETUP_MODE" = "role-based" ]; then
    echo ""
    echo "📁 チーム検討情報蓄積場:"
    echo "  ${WORKSPACE_DIR}/"
    echo "    ├── deliverables/     # 成果物定義書"
    echo "    ├── dependencies/     # 依存関係管理"
    echo "    ├── communications/   # コミュニケーションログ"
    echo "    └── decisions/        # 意思決定記録"
fi

echo ""
if [ "$SETUP_MODE" = "default" ]; then
    log_success "🎉 ${TEAM_NAME} 環境セットアップ完了！"
else
    log_success "🎉 Team${TEAM_NUM} (${TEAM_NAME}) 環境セットアップ完了！"
fi
echo ""

if [ "$AUTO_START" = true ]; then
    echo "🎯 チームは既に起動済みです！"
    echo "📋 次のステップ:"
    echo "  1. 🔗 セッション確認:"
    echo "     tmux attach-session -t ${WORKERS_SESSION}   # ワーカー画面確認"
    echo "     tmux attach-session -t ${LEADER_SESSION}    # リーダー画面確認"
    echo ""
    echo "  2. 🎯 プロジェクト開始:"
    echo "     リーダーにプロジェクト指示を送信してください"
else
    echo "📋 次のステップ:"
    echo "  1. 🔗 セッションアタッチ:"
    echo "     tmux attach-session -t ${WORKERS_SESSION}   # ワーカー画面確認"
    echo "     tmux attach-session -t ${LEADER_SESSION}    # リーダー画面確認"
    echo ""
    echo "  2. 🤖 Claude Code起動:"
    if [ "$SETUP_MODE" = "default" ]; then
        echo "     # 手順1: President認証"
        echo "     tmux send-keys -t president 'claude' C-m"
        echo "     # 手順2: 認証後、multiagent一括起動"
        echo "     for i in {0..3}; do tmux send-keys -t multiagent:0.\$i 'claude' C-m; done"
    elif [ "$SETUP_MODE" = "legacy" ]; then
        echo "     # 手順1: President${TEAM_NUM}認証"
        echo "     tmux send-keys -t president${TEAM_NUM} 'claude' C-m"
        echo "     # 手順2: 認証後、multiagent${TEAM_NUM}一括起動"
        echo "     for i in {0..3}; do tmux send-keys -t multiagent${TEAM_NUM}:0.\$i 'claude' C-m; done"
    else
        echo "     # リーダー認証"
        echo "     tmux send-keys -t ${LEADER_SESSION} 'claude' C-m"
        echo "     # ワーカー一括起動"
        echo "     for i in {0..3}; do tmux send-keys -t ${WORKERS_SESSION}:0.\$i 'claude' C-m; done"
    fi
    echo ""
    echo "  3. 📜 指示書読み込み:"
    
    if [ "$SETUP_MODE" = "role-based" ]; then
        echo "     # リーダー"
        echo "     @${INSTRUCTIONS_DIR}/${LEADER_ROLE}.md"
        echo "     あなたは${LEADER_ROLE}${TEAM_NUM}です。"
        echo ""
        echo "     # マネージャー"
        echo "     @${INSTRUCTIONS_DIR}/${MANAGER_ROLE}.md"
        echo "     あなたは${MANAGER_ROLE}${TEAM_NUM}です。"
        echo ""
        echo "     # 各ワーカー"
        WORKER_COUNT=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers | length" "$ROLES_FILE")
        for ((i=0; i<3 && i<$WORKER_COUNT; i++)); do
            WORKER_ROLE=$(jq -r ".templates.\"$ROLE_TEMPLATE\".workers[$i].role" "$ROLES_FILE")
            WORKER_NUM=$((i+1))
            echo "     @${INSTRUCTIONS_DIR}/${WORKER_ROLE}.md"
            echo "     あなたは${WORKER_ROLE}${TEAM_NUM}-${WORKER_NUM}です。"
        done
        echo ""
        echo "  4. 🚀 自動起動オプション:"
        echo "     $0 ${TEAM_NUM} ${ROLE_TEMPLATE} --auto-start"
    elif [ "$SETUP_MODE" = "legacy" ]; then
        echo "     PRESIDENT${TEAM_NUM}: instructions/president.md"
        echo "     boss${TEAM_NUM}: instructions/boss.md"
        echo "     worker${TEAM_NUM}-1,2,3: instructions/worker.md"
        echo "     システム構造: CLAUDE.md"
        echo ""
        echo "  4. 🎯 実行: PRESIDENT${TEAM_NUM}に「あなたはpresident${TEAM_NUM}です。チーム${TEAM_NUM}の指示書に従って」と入力"
        echo ""
        echo "  5. 🚀 自動起動オプション:"
        echo "     $0 ${TEAM_NUM} --auto-start"
    else
        echo "     PRESIDENT: instructions/president.md"
        echo "     boss1: instructions/boss.md"
        echo "     worker1,2,3: instructions/worker.md"
        echo "     システム構造: CLAUDE.md"
        echo ""
        echo "  4. 🎯 デモ実行: PRESIDENTに「あなたはpresidentです。指示書に従って」と入力"
    fi
fi

echo ""
#!/bin/bash

# 🚀 Multi-Agent Team Manager
# 複数チームの管理スクリプト

set -e

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

log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# ヘルプ表示
show_help() {
    cat << EOF
🤖 Multi-Agent Team Manager

使用方法:
  $0 [コマンド] [オプション]

コマンド:
  create <team_number> [role_template]  指定番号のチームを作成（役割指定可能）
  destroy <team_number>                  指定番号のチームを削除
  list                                   全チームの状態を表示
  start <team_number>                    指定チームのClaude Codeを起動
  clean                                  全チームをクリーンアップ
  status <team_number>                   指定チームの詳細状態を表示
  roles                                  利用可能な役割テンプレート一覧
  
使用例:
  $0 create 1              # チーム1を作成（デフォルト開発チーム）
  $0 create 2 publishing   # チーム2を出版チームとして作成
  $0 create 3 game-dev     # チーム3をゲーム開発チームとして作成
  $0 roles                 # 利用可能な役割を確認
  $0 list                  # 全チームの状態を確認
  $0 start 1               # チーム1のClaude Codeを起動
  $0 destroy 1             # チーム1を削除
  $0 clean                 # 全チームをクリーンアップ
EOF
}

# チーム作成
create_team() {
    local team_num="$1"
    local role_template="$2"
    
    if [[ -z "$team_num" ]]; then
        log_error "チーム番号を指定してください"
        exit 1
    fi
    
    if [[ -z "$role_template" ]]; then
        # デフォルトチーム作成（従来形式）
        log_info "チーム${team_num}を作成します（デフォルト開発チーム）..."
        
        # 統合版setup.shを実行
        if [[ -f "./setup.sh" ]]; then
            ./setup.sh "$team_num"
        else
            log_error "setup.shが見つかりません"
            exit 1
        fi
    else
        # 役割ベースチーム作成
        log_info "チーム${team_num}を作成します（${role_template}チーム）..."
        
        # 統合版setup.shを実行
        if [[ -f "./setup.sh" ]]; then
            ./setup.sh "$team_num" "$role_template"
        else
            log_error "setup.shが見つかりません"
            exit 1
        fi
    fi
    
    # チーム情報を保存
    mkdir -p "./tmp/team${team_num}"
    if [[ -n "$role_template" ]]; then
        echo "$role_template" > "./tmp/team${team_num}/.team_type"
    else
        echo "default" > "./tmp/team${team_num}/.team_type"
    fi
}

# チーム削除
destroy_team() {
    local team_num="$1"
    
    if [[ -z "$team_num" ]]; then
        log_error "チーム番号を指定してください"
        exit 1
    fi
    
    log_warning "チーム${team_num}を削除します..."
    
    # セッション削除（旧形式）
    tmux kill-session -t "multiagent${team_num}" 2>/dev/null && log_info "multiagent${team_num}セッション削除完了" || true
    tmux kill-session -t "president${team_num}" 2>/dev/null && log_info "president${team_num}セッション削除完了" || true
    
    # セッション削除（新形式）
    tmux kill-session -t "team${team_num}-workers" 2>/dev/null && log_info "team${team_num}-workersセッション削除完了" || true
    tmux kill-session -t "team${team_num}-leader" 2>/dev/null && log_info "team${team_num}-leaderセッション削除完了" || true
    
    # チームディレクトリクリーンアップ
    rm -rf "./tmp/team${team_num}" 2>/dev/null && log_info "チーム${team_num}の作業ディレクトリを削除" || true
    rm -rf "./logs/team${team_num}" 2>/dev/null && log_info "チーム${team_num}のログディレクトリを削除" || true
    rm -rf "./outputs/team${team_num}" 2>/dev/null && log_info "チーム${team_num}の成果物ディレクトリを削除" || true
    rm -rf "./instructions/team${team_num}" 2>/dev/null && log_info "チーム${team_num}の指示書ディレクトリを削除" || true
    rm -rf "./team-workspace/team${team_num}" 2>/dev/null && log_info "チーム${team_num}のワークスペースディレクトリを削除" || true
    
    log_success "チーム${team_num}の削除完了"
}

# チーム一覧表示
list_teams() {
    echo "📊 Multi-Agent Teams Status"
    echo "==========================="
    echo ""
    
    # デフォルトチーム確認
    local default_multiagent=false
    local default_president=false
    
    if tmux has-session -t "multiagent" 2>/dev/null; then
        default_multiagent=true
    fi
    
    if tmux has-session -t "president" 2>/dev/null; then
        default_president=true
    fi
    
    if [[ "$default_multiagent" == "true" ]] || [[ "$default_president" == "true" ]]; then
        echo "【デフォルトチーム】"
        echo "  multiagent: $([ "$default_multiagent" == "true" ] && echo "✅ 起動中" || echo "❌ 停止")"
        echo "  president:  $([ "$default_president" == "true" ] && echo "✅ 起動中" || echo "❌ 停止")"
        echo ""
    fi
    
    # 番号付きチーム確認（1-10）
    local team_found=false
    for i in {1..10}; do
        local multiagent_status=false
        local president_status=false
        local workers_status=false
        local leader_status=false
        
        # 旧形式セッション確認
        if tmux has-session -t "multiagent${i}" 2>/dev/null; then
            multiagent_status=true
            team_found=true
        fi
        
        if tmux has-session -t "president${i}" 2>/dev/null; then
            president_status=true
            team_found=true
        fi
        
        # 新形式セッション確認
        if tmux has-session -t "team${i}-workers" 2>/dev/null; then
            workers_status=true
            team_found=true
        fi
        
        if tmux has-session -t "team${i}-leader" 2>/dev/null; then
            leader_status=true
            team_found=true
        fi
        
        if [[ "$multiagent_status" == "true" ]] || [[ "$president_status" == "true" ]] || [[ "$workers_status" == "true" ]] || [[ "$leader_status" == "true" ]]; then
            # チームタイプ取得
            local team_type="default"
            if [[ -f "./tmp/team${i}/.team_type" ]]; then
                team_type=$(cat "./tmp/team${i}/.team_type" 2>/dev/null || echo "default")
            fi
            
            # チーム名取得
            local team_name=""
            if [[ -f "./team-roles.json" ]] && command -v jq &> /dev/null; then
                team_name=$(jq -r ".templates.\"$team_type\".name // \"開発チーム\"" "./team-roles.json" 2>/dev/null || echo "開発チーム")
            fi
            
            echo "【チーム${i}】($team_name)"
            
            # セッション状態表示
            if [[ "$multiagent_status" == "true" ]] || [[ "$president_status" == "true" ]]; then
                echo "  multiagent${i}: $([ "$multiagent_status" == "true" ] && echo "✅ 起動中" || echo "❌ 停止")"
                echo "  president${i}:  $([ "$president_status" == "true" ] && echo "✅ 起動中" || echo "❌ 停止")"
            fi
            
            if [[ "$workers_status" == "true" ]] || [[ "$leader_status" == "true" ]]; then
                echo "  team${i}-workers: $([ "$workers_status" == "true" ] && echo "✅ 起動中" || echo "❌ 停止")"
                echo "  team${i}-leader:  $([ "$leader_status" == "true" ] && echo "✅ 起動中" || echo "❌ 停止")"
            fi
            
            # 作業ディレクトリ確認
            if [[ -d "./tmp/team${i}" ]]; then
                local file_count=$(find "./tmp/team${i}" -type f 2>/dev/null | wc -l | tr -d ' ')
                echo "  作業ファイル: ${file_count}個"
            fi
            
            # 成果物ディレクトリ確認
            if [[ -d "./outputs/team${i}" ]]; then
                local output_count=$(find "./outputs/team${i}" -type f 2>/dev/null | wc -l | tr -d ' ')
                echo "  成果物: ${output_count}個"
            fi
            
            echo ""
        fi
    done
    
    if [[ "$team_found" == "false" ]] && [[ "$default_multiagent" == "false" ]] && [[ "$default_president" == "false" ]]; then
        echo "現在起動中のチームはありません"
    fi
}

# チームのClaude Code起動
start_team() {
    local team_num="$1"
    
    if [[ -z "$team_num" ]]; then
        log_error "チーム番号を指定してください"
        exit 1
    fi
    
    log_info "チーム${team_num}のClaude Codeを起動します..."
    
    # 旧形式と新形式のセッション存在確認
    local has_old_format=false
    local has_new_format=false
    
    if tmux has-session -t "president${team_num}" 2>/dev/null && tmux has-session -t "multiagent${team_num}" 2>/dev/null; then
        has_old_format=true
    fi
    
    if tmux has-session -t "team${team_num}-leader" 2>/dev/null && tmux has-session -t "team${team_num}-workers" 2>/dev/null; then
        has_new_format=true
    fi
    
    if [[ "$has_old_format" == "false" ]] && [[ "$has_new_format" == "false" ]]; then
        log_error "チーム${team_num}のセッションが存在しません。先にチームを作成してください。"
        echo "実行: $0 create ${team_num} [role_template]"
        exit 1
    fi
    
    if [[ "$has_old_format" == "true" ]]; then
        # 旧形式で起動
        log_info "President${team_num}でClaude Codeを起動..."
        tmux send-keys -t "president${team_num}" "claude" C-m
        
        log_warning "President${team_num}で認証が完了したら、Enterを押してください..."
        read -r
        
        log_info "チーム${team_num}の全ワーカーでClaude Codeを起動..."
        for i in {0..3}; do
            tmux send-keys -t "multiagent${team_num}:0.$i" "claude" C-m
            sleep 0.5
        done
        
        log_success "チーム${team_num}のClaude Code起動完了"
        echo ""
        echo "📋 次のステップ:"
        echo "  1. president${team_num}に接続: tmux attach-session -t president${team_num}"
        echo "  2. 指示を送信: ./agent-send.sh president${team_num} \"あなたはpresident${team_num}です。\""
    else
        # 新形式で起動
        log_info "リーダーセッションでClaude Codeを起動..."
        tmux send-keys -t "team${team_num}-leader" "claude" C-m
        
        log_warning "team${team_num}-leaderで認証が完了したら、Enterを押してください..."
        read -r
        
        log_info "チーム${team_num}の全ワーカーでClaude Codeを起動..."
        for i in {0..3}; do
            tmux send-keys -t "team${team_num}-workers:0.$i" "claude" C-m
            sleep 0.5
        done
        
        # チームタイプに応じた指示
        local team_type="default"
        if [[ -f "./tmp/team${team_num}/.team_type" ]]; then
            team_type=$(cat "./tmp/team${team_num}/.team_type" 2>/dev/null || echo "default")
        fi
        
        # リーダー名を取得
        local leader_role="PRESIDENT"
        if [[ -f "./team-roles.json" ]] && command -v jq &> /dev/null; then
            leader_role=$(jq -r ".templates.\"$team_type\".leader.role // \"PRESIDENT\"" "./team-roles.json" 2>/dev/null || echo "PRESIDENT")
        fi
        
        log_success "チーム${team_num}のClaude Code起動完了"
        echo ""
        echo "📋 次のステップ:"
        echo "  1. リーダーに接続: tmux attach-session -t team${team_num}-leader"
        echo "  2. 指示を送信: ./agent-send.sh ${leader_role}${team_num} \"あなたは${leader_role}${team_num}です。\""
    fi
}

# 全チームクリーンアップ
clean_all() {
    log_warning "全チームをクリーンアップします..."
    echo "本当に実行しますか？ (y/N): "
    read -r confirm
    
    if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
        echo "キャンセルしました"
        exit 0
    fi
    
    # デフォルトチーム削除
    tmux kill-session -t "multiagent" 2>/dev/null && log_info "multiagentセッション削除" || true
    tmux kill-session -t "president" 2>/dev/null && log_info "presidentセッション削除" || true
    
    # 番号付きチーム削除（1-10）
    for i in {1..10}; do
        if tmux has-session -t "multiagent${i}" 2>/dev/null || tmux has-session -t "president${i}" 2>/dev/null || \
           tmux has-session -t "team${i}-workers" 2>/dev/null || tmux has-session -t "team${i}-leader" 2>/dev/null; then
            destroy_team "$i"
        fi
    done
    
    # 全体のクリーンアップ
    rm -rf ./tmp/* 2>/dev/null || true
    rm -rf ./logs/* 2>/dev/null || true
    
    log_success "全チームのクリーンアップ完了"
}

# チーム詳細状態表示
show_team_status() {
    local team_num="$1"
    
    if [[ -z "$team_num" ]]; then
        log_error "チーム番号を指定してください"
        exit 1
    fi
    
    echo "📊 チーム${team_num} 詳細状態"
    echo "===================="
    echo ""
    
    # チームタイプ取得
    local team_type="default"
    local team_name="開発チーム"
    if [[ -f "./tmp/team${team_num}/.team_type" ]]; then
        team_type=$(cat "./tmp/team${team_num}/.team_type" 2>/dev/null || echo "default")
    fi
    
    if [[ -f "./team-roles.json" ]] && command -v jq &> /dev/null; then
        team_name=$(jq -r ".templates.\"$team_type\".name // \"開発チーム\"" "./team-roles.json" 2>/dev/null || echo "開発チーム")
    fi
    
    echo "【チームタイプ】$team_name ($team_type)"
    echo ""
    
    # セッション状態
    echo "【セッション状態】"
    
    # 旧形式セッション
    if tmux has-session -t "president${team_num}" 2>/dev/null; then
        echo "  president${team_num}: ✅ 起動中"
        # ペイン情報
        tmux list-panes -t "president${team_num}" -F "    Pane #{pane_index}: #{pane_title}"
    else
        echo "  president${team_num}: ❌ 停止"
    fi
    
    if tmux has-session -t "multiagent${team_num}" 2>/dev/null; then
        echo "  multiagent${team_num}: ✅ 起動中"
        # ペイン情報
        tmux list-panes -t "multiagent${team_num}" -F "    Pane #{pane_index}: #{pane_title}"
    else
        echo "  multiagent${team_num}: ❌ 停止"
    fi
    
    # 新形式セッション
    if tmux has-session -t "team${team_num}-leader" 2>/dev/null; then
        echo "  team${team_num}-leader: ✅ 起動中"
        # ペイン情報
        tmux list-panes -t "team${team_num}-leader" -F "    Pane #{pane_index}: #{pane_title}"
    else
        echo "  team${team_num}-leader: ❌ 停止"
    fi
    
    if tmux has-session -t "team${team_num}-workers" 2>/dev/null; then
        echo "  team${team_num}-workers: ✅ 起動中"
        # ペイン情報
        tmux list-panes -t "team${team_num}-workers" -F "    Pane #{pane_index}: #{pane_title}"
    else
        echo "  team${team_num}-workers: ❌ 停止"
    fi
    echo ""
    
    # 作業ディレクトリ
    echo "【作業ディレクトリ】"
    if [[ -d "./tmp/team${team_num}" ]]; then
        echo "  ./tmp/team${team_num}/:"
        ls -la "./tmp/team${team_num}/" 2>/dev/null | tail -n +2 | head -10 || echo "    (空)"
    else
        echo "  作業ディレクトリなし"
    fi
    echo ""
    
    # ログ
    echo "【最新ログ】"
    if [[ -f "./logs/team${team_num}/send_log.txt" ]]; then
        echo "  最新5件のメッセージ:"
        tail -5 "./logs/team${team_num}/send_log.txt" 2>/dev/null | sed 's/^/    /'
    else
        echo "  ログなし"
    fi
}

# 利用可能な役割表示
show_roles() {
    echo "📋 利用可能な役割テンプレート"
    echo "============================="
    echo ""
    
    if [[ ! -f "./team-roles.json" ]]; then
        log_error "team-roles.jsonが見つかりません"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jqがインストールされていません"
        echo "Mac: brew install jq"
        echo "Linux: sudo apt-get install jq"
        exit 1
    fi
    
    # テンプレート一覧を表示
    while IFS= read -r template; do
        local name=$(jq -r ".templates.\"$template\".name" "./team-roles.json")
        local desc=$(jq -r ".templates.\"$template\".description" "./team-roles.json")
        local leader=$(jq -r ".templates.\"$template\".leader.title" "./team-roles.json")
        local manager=$(jq -r ".templates.\"$template\".manager.title" "./team-roles.json")
        local worker_count=$(jq -r ".templates.\"$template\".workers | length" "./team-roles.json")
        
        echo "【$template】$name"
        echo "  説明: $desc"
        echo "  構成:"
        echo "    - リーダー: $leader"
        echo "    - マネージャー: $manager"
        echo -n "    - ワーカー: "
        
        for ((i=0; i<$worker_count; i++)); do
            local worker_title=$(jq -r ".templates.\"$template\".workers[$i].title" "./team-roles.json")
            if [[ $i -eq 0 ]]; then
                echo -n "$worker_title"
            else
                echo -n ", $worker_title"
            fi
        done
        echo ""
        echo ""
    done < <(jq -r '.templates | keys[]' "./team-roles.json")
    
    echo "使用例:"
    echo "  $0 create 1 publishing   # 出版チームとしてチーム1を作成"
    echo "  $0 create 2 game-dev     # ゲーム開発チームとしてチーム2を作成"
}

# メイン処理
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        "create")
            create_team "$@"
            ;;
        "destroy")
            destroy_team "$@"
            ;;
        "list")
            list_teams
            ;;
        "start")
            start_team "$@"
            ;;
        "clean")
            clean_all
            ;;
        "status")
            show_team_status "$@"
            ;;
        "roles")
            show_roles
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "不明なコマンド: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
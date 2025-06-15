#!/bin/bash

# 🚀 Agent間メッセージ送信スクリプト（複数チーム対応版）

# エージェント→tmuxターゲット マッピング（チーム番号対応）
get_agent_target() {
    local agent_name="$1"
    local team_num="$2"
    
    # チーム番号が指定されていない場合はデフォルトチーム（番号なし）
    if [[ -z "$team_num" ]]; then
        case "$agent_name" in
            "president") echo "president" ;;
            "boss1") echo "multiagent:0.0" ;;
            "worker1") echo "multiagent:0.1" ;;
            "worker2") echo "multiagent:0.2" ;;
            "worker3") echo "multiagent:0.3" ;;
            *) echo "" ;;
        esac
    else
        # チーム番号が指定されている場合
        case "$agent_name" in
            "president${team_num}") echo "president${team_num}" ;;
            "boss${team_num}") echo "multiagent${team_num}:0.0" ;;
            "worker${team_num}-1") echo "multiagent${team_num}:0.1" ;;
            "worker${team_num}-2") echo "multiagent${team_num}:0.2" ;;
            "worker${team_num}-3") echo "multiagent${team_num}:0.3" ;;
            *) echo "" ;;
        esac
    fi
}

# エージェント名からチーム番号を抽出
extract_team_number() {
    local agent_name="$1"
    
    # president1, boss2, worker3-1 などからチーム番号を抽出
    if [[ "$agent_name" =~ ^(president|boss)([0-9]+)$ ]]; then
        echo "${BASH_REMATCH[2]}"
    elif [[ "$agent_name" =~ ^worker([0-9]+)-[0-9]+$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo ""
    fi
}

show_usage() {
    cat << EOF
🤖 Agent間メッセージ送信（複数チーム対応版）

使用方法:
  $0 [エージェント名] [メッセージ]
  $0 --list [チーム番号]
  $0 --list-all

エージェント名の形式:
  デフォルトチーム（チーム番号なし）:
    president, boss1, worker1, worker2, worker3
    
  チーム番号付き:
    president1, boss1, worker1-1, worker1-2, worker1-3
    president2, boss2, worker2-1, worker2-2, worker2-3
    など

使用例:
  # デフォルトチーム
  $0 president "指示書に従って"
  $0 boss1 "Hello World プロジェクト開始指示"
  
  # チーム1
  $0 president1 "チーム1の指示書に従って"
  $0 boss1 "チーム1のプロジェクト開始"
  $0 worker1-1 "チーム1の作業完了"
  
  # チーム2
  $0 president2 "チーム2の指示書に従って"
  $0 worker2-3 "チーム2のworker3作業完了"
EOF
}

# 特定チームのエージェント一覧表示
show_team_agents() {
    local team_num="$1"
    
    if [[ -z "$team_num" ]]; then
        echo "📋 デフォルトチームのエージェント:"
        echo "================================"
        echo "  president → president:0     (プロジェクト統括責任者)"
        echo "  boss1     → multiagent:0.0  (チームリーダー)"
        echo "  worker1   → multiagent:0.1  (実行担当者A)"
        echo "  worker2   → multiagent:0.2  (実行担当者B)" 
        echo "  worker3   → multiagent:0.3  (実行担当者C)"
    else
        echo "📋 チーム${team_num}のエージェント:"
        echo "================================"
        echo "  president${team_num} → president${team_num}:0     (プロジェクト統括責任者)"
        echo "  boss${team_num}     → multiagent${team_num}:0.0  (チームリーダー)"
        echo "  worker${team_num}-1  → multiagent${team_num}:0.1  (実行担当者A)"
        echo "  worker${team_num}-2  → multiagent${team_num}:0.2  (実行担当者B)" 
        echo "  worker${team_num}-3  → multiagent${team_num}:0.3  (実行担当者C)"
    fi
}

# 全チームのエージェント一覧表示
show_all_agents() {
    echo "📋 現在起動中の全チーム:"
    echo "========================"
    
    # デフォルトチームの確認
    if tmux has-session -t "president" 2>/dev/null || tmux has-session -t "multiagent" 2>/dev/null; then
        echo ""
        echo "【デフォルトチーム】"
        show_team_agents ""
    fi
    
    # 番号付きチームの確認（1-10まで確認）
    for i in {1..10}; do
        if tmux has-session -t "president${i}" 2>/dev/null || tmux has-session -t "multiagent${i}" 2>/dev/null; then
            echo ""
            echo "【チーム${i}】"
            show_team_agents "$i"
        fi
    done
}

# ログ記録（チーム番号対応）
log_send() {
    local agent="$1"
    local message="$2"
    local team_num="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p logs
    
    if [[ -z "$team_num" ]]; then
        echo "[$timestamp] $agent: SENT - \"$message\"" >> logs/send_log.txt
    else
        mkdir -p "logs/team${team_num}"
        echo "[$timestamp] $agent: SENT - \"$message\"" >> "logs/team${team_num}/send_log.txt"
    fi
}

# メッセージ送信
send_message() {
    local target="$1"
    local message="$2"
    
    echo "📤 送信中: $target ← '$message'"
    
    # Claude Codeのプロンプトを一度クリア
    tmux send-keys -t "$target" C-c
    sleep 0.3
    
    # メッセージ送信
    tmux send-keys -t "$target" "$message"
    sleep 0.1
    
    # エンター押下
    tmux send-keys -t "$target" C-m
    sleep 0.5
}

# ターゲット存在確認
check_target() {
    local target="$1"
    local session_name="${target%%:*}"
    
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "❌ セッション '$session_name' が見つかりません"
        echo "💡 ヒント: setup-team.sh [チーム番号] でチームを作成してください"
        return 1
    fi
    
    return 0
}

# メイン処理
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    # --list-allオプション
    if [[ "$1" == "--list-all" ]]; then
        show_all_agents
        exit 0
    fi
    
    # --listオプション
    if [[ "$1" == "--list" ]]; then
        if [[ -n "$2" ]]; then
            show_team_agents "$2"
        else
            show_team_agents ""
        fi
        exit 0
    fi
    
    if [[ $# -lt 2 ]]; then
        show_usage
        exit 1
    fi
    
    local agent_name="$1"
    local message="$2"
    
    # エージェント名からチーム番号を抽出
    local team_num
    team_num=$(extract_team_number "$agent_name")
    
    # エージェントターゲット取得
    local target
    target=$(get_agent_target "$agent_name" "$team_num")
    
    if [[ -z "$target" ]]; then
        echo "❌ エラー: 不明なエージェント '$agent_name'"
        echo "利用可能エージェント: $0 --list-all"
        exit 1
    fi
    
    # ターゲット確認
    if ! check_target "$target"; then
        exit 1
    fi
    
    # メッセージ送信
    send_message "$target" "$message"
    
    # ログ記録
    log_send "$agent_name" "$message" "$team_num"
    
    echo "✅ 送信完了: $agent_name に '$message'"
    
    return 0
}

main "$@"
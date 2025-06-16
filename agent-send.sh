#!/bin/bash

# 🚀 Agent間メッセージ送信スクリプト（統合版 - デフォルト・複数チーム対応）

# team-roles.jsonから動的にエージェント情報を取得
get_team_info() {
    local team_template="$1"
    local team_num="$2"
    
    if [ ! -f "./team-roles.json" ]; then
        return 1
    fi
    
    # チーム情報をJSONから取得
    if [ -n "$team_template" ]; then
        jq -r ".templates.\"$team_template\"" "./team-roles.json" 2>/dev/null
    else
        return 1
    fi
}

# エージェント→tmuxターゲット マッピング（動的対応）
get_agent_target() {
    local agent_name="$1"
    local team_num="$2"
    
    # チーム番号が指定されていない場合はデフォルトチーム（番号なし）
    if [[ -z "$team_num" ]]; then
        case "$agent_name" in
            # 従来の固定名前（後方互換性）
            "president") echo "president" ;;
            "boss1") echo "multiagent:0.0" ;;
            "worker1") echo "multiagent:0.1" ;;
            "worker2") echo "multiagent:0.2" ;;
            "worker3") echo "multiagent:0.3" ;;
            # 新しいセッション名（team-leader, team-workers）
            *) 
                # デフォルトチームの動的役割名対応
                if [ -f "./team-roles.json" ]; then
                    # 全テンプレートを確認して、この役割がリーダーかどうか判定
                    local is_leader=false
                    local is_manager=false
                    local templates=$(jq -r '.templates | keys[]' "./team-roles.json" 2>/dev/null)
                    
                    for template in $templates; do
                        local leader_role=$(jq -r ".templates.\"$template\".leader.role" "./team-roles.json" 2>/dev/null)
                        local manager_role=$(jq -r ".templates.\"$template\".manager.role" "./team-roles.json" 2>/dev/null)
                        
                        if [ "$agent_name" = "$leader_role" ]; then
                            is_leader=true
                            break
                        elif [ "$agent_name" = "$manager_role" ]; then
                            is_manager=true
                            break
                        fi
                    done
                    
                    # デフォルトチームのセッション名判定
                    if [ "$is_leader" = true ] && tmux has-session -t "president" 2>/dev/null; then
                        echo "president"
                    elif [ "$is_manager" = true ] && tmux has-session -t "multiagent" 2>/dev/null; then
                        echo "multiagent:0.0"
                    elif [[ "$agent_name" =~ ^([A-Za-z]+)(-[0-9]+)?$ ]]; then
                        # ワーカー役割の判定
                        local role_base="${BASH_REMATCH[1]}"
                        local worker_num="${BASH_REMATCH[2]}"
                        
                        if [ -n "$worker_num" ] && tmux has-session -t "multiagent" 2>/dev/null; then
                            local pane_num="${worker_num#-}"
                            echo "multiagent:0.$pane_num"
                        else
                            echo ""
                        fi
                    else
                        echo ""
                    fi
                else
                    echo ""
                fi
                ;;
        esac
    else
        # チーム番号が指定されている場合
        case "$agent_name" in
            # 従来の固定名前パターン（後方互換性）
            "president${team_num}") echo "team${team_num}-leader" ;;
            "boss${team_num}") echo "team${team_num}-workers:0.0" ;;
            "worker${team_num}-1") echo "team${team_num}-workers:0.1" ;;
            "worker${team_num}-2") echo "team${team_num}-workers:0.2" ;;
            "worker${team_num}-3") echo "team${team_num}-workers:0.3" ;;
            # 動的役割名パターン
            *)
                # エージェント名から役割とチーム番号を解析
                if [[ "$agent_name" =~ ^([A-Za-z]+)([0-9]+)(-[0-9]+)?$ ]]; then
                    local role_base="${BASH_REMATCH[1]}"
                    local extracted_team="${BASH_REMATCH[2]}"
                    local worker_num="${BASH_REMATCH[3]}"
                    
                    if [ "$extracted_team" = "$team_num" ]; then
                        # team-roles.jsonから役割情報を取得して判定
                        if [ -f "./team-roles.json" ]; then
                            # 全テンプレートを確認して、この役割がリーダーかどうか判定
                            local is_leader=false
                            local is_manager=false
                            local templates=$(jq -r '.templates | keys[]' "./team-roles.json" 2>/dev/null)
                            
                            for template in $templates; do
                                local leader_role=$(jq -r ".templates.\"$template\".leader.role" "./team-roles.json" 2>/dev/null)
                                local manager_role=$(jq -r ".templates.\"$template\".manager.role" "./team-roles.json" 2>/dev/null)
                                
                                if [ "$role_base" = "$leader_role" ]; then
                                    is_leader=true
                                    break
                                elif [ "$role_base" = "$manager_role" ]; then
                                    is_manager=true
                                    break
                                fi
                            done
                            
                            # リーダー役割の場合
                            if [ "$is_leader" = true ] && tmux has-session -t "team${team_num}-leader" 2>/dev/null; then
                                echo "team${team_num}-leader"
                            # マネージャー役割の場合（ペイン0）
                            elif [ "$is_manager" = true ] && tmux has-session -t "team${team_num}-workers" 2>/dev/null; then
                                echo "team${team_num}-workers:0.0"
                            # ワーカー役割の場合
                            elif tmux has-session -t "team${team_num}-workers" 2>/dev/null; then
                                if [ -n "$worker_num" ]; then
                                    local pane_num="${worker_num#-}"
                                    echo "team${team_num}-workers:0.$pane_num"
                                else
                                    # worker_numがない場合はデフォルトでペイン0（マネージャー）
                                    echo "team${team_num}-workers:0.0"
                                fi
                            fi
                        else
                            # team-roles.jsonがない場合は従来の動作
                            if tmux has-session -t "team${team_num}-leader" 2>/dev/null; then
                                echo "team${team_num}-leader"
                            elif tmux has-session -t "team${team_num}-workers" 2>/dev/null; then
                                if [ -n "$worker_num" ]; then
                                    local pane_num="${worker_num#-}"
                                    echo "team${team_num}-workers:0.$pane_num"
                                else
                                    echo "team${team_num}-workers:0.0"
                                fi
                            fi
                        fi
                    fi
                else
                    echo ""
                fi
                ;;
        esac
    fi
}

# エージェント名からチーム番号を抽出（拡張版）
extract_team_number() {
    local agent_name="$1"
    
    # 様々なパターンからチーム番号を抽出
    if [[ "$agent_name" =~ ^(president|boss)([0-9]+)$ ]]; then
        # president1, boss2 パターン
        echo "${BASH_REMATCH[2]}"
    elif [[ "$agent_name" =~ ^worker([0-9]+)-[0-9]+$ ]]; then
        # worker1-1, worker2-3 パターン
        echo "${BASH_REMATCH[1]}"
    elif [[ "$agent_name" =~ ^([A-Za-z]+)([0-9]+)(-[0-9]+)?$ ]]; then
        # Publisher1, Editor2, Novelist1-1 などの動的パターン
        echo "${BASH_REMATCH[2]}"
    else
        echo ""
    fi
}

# エージェント名から役割情報を抽出
extract_role_info() {
    local agent_name="$1"
    
    if [[ "$agent_name" =~ ^([A-Za-z]+)([0-9]+)(-([0-9]+))?$ ]]; then
        local role="${BASH_REMATCH[1]}"
        local team="${BASH_REMATCH[2]}"
        local worker_num="${BASH_REMATCH[4]}"
        
        echo "$role|$team|$worker_num"
    else
        echo "||"
    fi
}

show_usage() {
    cat << EOF
🤖 Agent間メッセージ送信（統合版 - デフォルト・複数チーム対応）

使用方法:
  $0 [エージェント名] [メッセージ]
  $0 --list [チーム番号]
  $0 --list-all
  $0 --help

エージェント名の形式:
  【従来形式（後方互換性）】
  デフォルトチーム: president, boss1, worker1, worker2, worker3
  チーム番号付き: president1, boss1, worker1-1, worker1-2, worker1-3
  
  【新形式（動的役割名）】
  出版チーム1: Publisher1, Editor1, Novelist1-1, Novelist1-2, Novelist1-3
  デザインチーム2: CEO2, DesignManager2, WebDesigner2-1, WebDesigner2-2
  ゲーム開発チーム3: GameProducer3, GameDirector3, GameProgrammer3-1
  
使用例:
  # 従来形式（デフォルトチーム）
  $0 president "指示書に従って"
  $0 boss1 "Hello World プロジェクト開始指示"
  
  # 従来形式（チーム番号付き）
  $0 president1 "チーム1の指示書に従って"
  $0 worker1-1 "チーム1の作業完了"
  
  # 新形式（動的役割名）
  $0 Publisher1 "出版プロジェクト開始"
  $0 Editor1 "編集方針を確認してください"
  $0 Novelist1-1 "第1章の執筆を開始してください"
  $0 CEO2 "デザインチーム2の統括をお願いします"
  $0 WebDesigner2-1 "ランディングページのデザインを作成"

オプション:
  --list [番号]    指定チームのエージェント一覧（番号省略でデフォルト）
  --list-all       全チームのエージェント一覧
  --help           このヘルプを表示
EOF
}

# 特定チームのエージェント一覧表示（動的対応）
show_team_agents() {
    local team_num="$1"
    
    if [[ -z "$team_num" ]]; then
        echo "📋 デフォルトチームのエージェント:"
        echo "================================"
        echo "【従来形式】"
        echo "  president → president:0     (プロジェクト統括責任者)"
        echo "  boss1     → multiagent:0.0  (チームリーダー)"
        echo "  worker1   → multiagent:0.1  (実行担当者A)"
        echo "  worker2   → multiagent:0.2  (実行担当者B)" 
        echo "  worker3   → multiagent:0.3  (実行担当者C)"
    else
        echo "📋 チーム${team_num}のエージェント:"
        echo "================================"
        
        # team-roles.jsonから動的にチーム情報を取得
        if [ -f "./team-roles.json" ]; then
            # チーム番号からテンプレートを推測（実際の運用では環境変数等で管理）
            local found_template=""
            local templates=$(jq -r '.templates | keys[]' "./team-roles.json" 2>/dev/null)
            
            # 実際のtmuxセッションから推測
            for template in $templates; do
                local leader_role=$(jq -r ".templates.\"$template\".leader.role" "./team-roles.json" 2>/dev/null)
                if tmux has-session -t "team${team_num}-leader" 2>/dev/null; then
                    found_template="$template"
                    break
                fi
            done
            
            if [ -n "$found_template" ]; then
                echo "【動的役割名（$found_template チーム）】"
                local leader_role=$(jq -r ".templates.\"$found_template\".leader.role" "./team-roles.json")
                local leader_title=$(jq -r ".templates.\"$found_template\".leader.title" "./team-roles.json")
                local manager_role=$(jq -r ".templates.\"$found_template\".manager.role" "./team-roles.json")
                local manager_title=$(jq -r ".templates.\"$found_template\".manager.title" "./team-roles.json")
                
                echo "  ${leader_role}${team_num} → team${team_num}-leader     ($leader_title)"
                echo "  ${manager_role}${team_num} → team${team_num}-workers:0.0  ($manager_title)"
                
                # ワーカー情報を取得
                local worker_count=$(jq -r ".templates.\"$found_template\".workers | length" "./team-roles.json")
                for ((i=0; i<$worker_count && i<3; i++)); do
                    local worker_role=$(jq -r ".templates.\"$found_template\".workers[$i].role" "./team-roles.json")
                    local worker_title=$(jq -r ".templates.\"$found_template\".workers[$i].title" "./team-roles.json")
                    local worker_num=$((i+1))
                    echo "  ${worker_role}${team_num}-${worker_num} → team${team_num}-workers:0.$worker_num  ($worker_title)"
                done
            fi
        fi
        
        echo ""
        echo "【従来形式（後方互換性）】"
        echo "  president${team_num} → team${team_num}-leader     (プロジェクト統括責任者)"
        echo "  boss${team_num}     → team${team_num}-workers:0.0  (チームリーダー)"
        echo "  worker${team_num}-1  → team${team_num}-workers:0.1  (実行担当者A)"
        echo "  worker${team_num}-2  → team${team_num}-workers:0.2  (実行担当者B)" 
        echo "  worker${team_num}-3  → team${team_num}-workers:0.3  (実行担当者C)"
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
        if tmux has-session -t "president${i}" 2>/dev/null || tmux has-session -t "multiagent${i}" 2>/dev/null ||
           tmux has-session -t "team${i}-leader" 2>/dev/null || tmux has-session -t "team${i}-workers" 2>/dev/null; then
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
        echo "💡 ヒント:"
        echo "   デフォルトチーム: ./setup.sh"
echo "   従来形式チーム: ./setup.sh [チーム番号]"
echo "   役割ベースチーム: ./setup.sh [チーム番号] [テンプレート]"
echo "   例: ./setup.sh 1 publishing"
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
    
    # オプション処理
    case "$1" in
        "--help"|"-h")
            show_usage
            exit 0
            ;;
        "--list-all")
            show_all_agents
            exit 0
            ;;
        "--list")
            if [[ -n "$2" ]]; then
                show_team_agents "$2"
            else
                show_team_agents ""
            fi
            exit 0
            ;;
    esac
    
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
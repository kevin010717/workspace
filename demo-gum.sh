#!/data/data/com.termux/files/usr/bin/bash
#
# Gum Termux Toolbox Demo
# Requires: bash, gum
# Recommended: curl, file, nano, coreutils
#
# Install:
#   pkg update
#   pkg install gum bash coreutils curl file nano
#
# Run:
#   chmod +x gum-termux-demo.sh
#   ./gum-termux-demo.sh

set -o pipefail

APP_NAME="Gum Termux Toolbox"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/gum-termux-demo"
NOTES_DIR="$APP_DIR/notes"
TODO_FILE="$APP_DIR/todos.tsv"
CLIPBOARD_FALLBACK="$APP_DIR/clipboard.txt"

mkdir -p "$NOTES_DIR"
touch "$TODO_FILE"

# ---------- Theme ----------
PINK="212"
PURPLE="99"
CYAN="51"
GREEN="42"
YELLOW="220"
RED="196"
MUTED="244"

# ---------- Basic helpers ----------
need_gum() {
  if ! command -v gum >/dev/null 2>&1; then
    cat <<'EOF'
未找到 gum。

请在 Termux 中运行：
  pkg update
  pkg install gum bash coreutils curl file nano

然后重新执行本脚本。
EOF
    exit 127
  fi
}

terminal_width() {
  local width
  width="$(tput cols 2>/dev/null || printf '60')"
  if ! [[ "$width" =~ ^[0-9]+$ ]]; then
    width=60
  fi
  if (( width > 78 )); then
    width=78
  elif (( width < 36 )); then
    width=36
  fi
  printf '%s' "$width"
}

press_enter() {
  printf '\n'
  gum style --foreground "$MUTED" "按 Enter 返回主菜单…"
  read -r _
}

success() {
  gum log --level info "$1"
}

warn() {
  gum log --level warn "$1"
}

error() {
  gum log --level error "$1"
}

copy_text() {
  local text="$1"
  if command -v termux-clipboard-set >/dev/null 2>&1; then
    printf '%s' "$text" | termux-clipboard-set
    success "已复制到 Android 剪贴板"
  else
    printf '%s\n' "$text" > "$CLIPBOARD_FALLBACK"
    warn "未检测到 termux-clipboard-set，内容已保存到：$CLIPBOARD_FALLBACK"
  fi
}

shell_quote() {
  printf '%q' "$1"
}

safe_clear() {
  clear 2>/dev/null || printf '\033[2J\033[H'
}

banner() {
  local width logo info
  width="$(terminal_width)"

  logo="$(gum style \
    --foreground "$PINK" \
    --border-foreground "$PURPLE" \
    --border double \
    --bold \
    --padding "0 2" \
    "GUM" "TERMUX")"

  info="$(gum style \
    --foreground "$CYAN" \
    --padding "0 1" \
    "$APP_NAME" \
    "Interactive shell UI demo")"

  if (( width >= 58 )); then
    gum join --horizontal --align center "$logo" "$info"
  else
    gum join --vertical --align center "$logo" "$info"
  fi
  printf '\n'
}

choose_or_return() {
  # Usage: choose_or_return "header" item1 item2...
  local header="$1"
  shift
  gum choose \
    --height 14 \
    --header "$header" \
    --cursor.foreground "$PINK" \
    --selected.foreground "$CYAN" \
    "$@"
}

# ---------- System dashboard ----------
format_uptime() {
  local total days hours minutes
  total="$(cut -d. -f1 /proc/uptime 2>/dev/null || printf '0')"
  [[ "$total" =~ ^[0-9]+$ ]] || total=0
  days=$((total / 86400))
  hours=$(((total % 86400) / 3600))
  minutes=$(((total % 3600) / 60))
  printf '%sd %sh %sm' "$days" "$hours" "$minutes"
}

memory_summary() {
  awk '
    /^MemTotal:/     { total=$2 }
    /^MemAvailable:/ { available=$2 }
    END {
      if (total > 0) {
        used=total-available
        printf "%.1f GiB / %.1f GiB", used/1048576, total/1048576
      } else {
        print "N/A"
      }
    }
  ' /proc/meminfo 2>/dev/null
}

battery_summary() {
  if command -v termux-battery-status >/dev/null 2>&1; then
    local json percentage status temperature
    json="$(termux-battery-status 2>/dev/null || true)"
    if command -v jq >/dev/null 2>&1 && [[ -n "$json" ]]; then
      percentage="$(printf '%s' "$json" | jq -r '.percentage // "?"')"
      status="$(printf '%s' "$json" | jq -r '.status // "unknown"')"
      temperature="$(printf '%s' "$json" | jq -r '.temperature // "?"')"
      printf '%s%%, %s, %s°C' "$percentage" "$status" "$temperature"
    else
      printf 'Termux:API 可用；安装 jq 可显示详情'
    fi
  else
    printf '未安装 Termux:API'
  fi
}

system_dashboard() {
  safe_clear
  banner
  gum style --bold --foreground "$PURPLE" "📊 系统信息"

  local model android kernel arch shell_version storage prefix battery tmp
  model="$(getprop ro.product.manufacturer 2>/dev/null) $(getprop ro.product.model 2>/dev/null)"
  model="${model# }"
  [[ -n "$model" ]] || model="Unknown Android device"

  android="$(getprop ro.build.version.release 2>/dev/null)"
  [[ -n "$android" ]] || android="Unknown"

  kernel="$(uname -sr 2>/dev/null || printf 'Unknown')"
  arch="$(uname -m 2>/dev/null || printf 'Unknown')"
  shell_version="${BASH_VERSION:-Unknown}"
  storage="$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
  [[ -n "$storage" ]] || storage="N/A"
  prefix="${PREFIX:-N/A}"
  battery="$(battery_summary)"

  tmp="$(mktemp)"
  {
    printf '项目|值\n'
    printf '设备|%s\n' "$model"
    printf 'Android|%s\n' "$android"
    printf 'Kernel|%s\n' "$kernel"
    printf '架构|%s\n' "$arch"
    printf 'Bash|%s\n' "$shell_version"
    printf 'Gum|%s\n' "$(gum --version 2>/dev/null || gum version 2>/dev/null || printf 'Unknown')"
    printf '运行时间|%s\n' "$(format_uptime)"
    printf '内存|%s\n' "$(memory_summary)"
    printf '主目录存储|%s\n' "$storage"
    printf '电池|%s\n' "$battery"
    printf 'PREFIX|%s\n' "$prefix"
  } > "$tmp"

  gum table \
    --print \
    --separator "|" \
    --border rounded \
    --header.foreground "$PINK" \
    --border.foreground "$PURPLE" \
    < "$tmp"
  rm -f "$tmp"
  press_enter
}

# ---------- File center ----------
file_information() {
  local path="$1" tmp mime size modified sha
  mime="$(file -b --mime-type "$path" 2>/dev/null || printf 'Unknown')"
  size="$(du -h "$path" 2>/dev/null | awk '{print $1}')"
  [[ -n "$size" ]] || size="N/A"
  modified="$(date -r "$path" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || printf 'N/A')"
  sha="$(sha256sum "$path" 2>/dev/null | awk '{print $1}')"
  [[ -n "$sha" ]] || sha="N/A"

  tmp="$(mktemp)"
  {
    printf '属性|值\n'
    printf '路径|%s\n' "$path"
    printf '类型|%s\n' "$mime"
    printf '大小|%s\n' "$size"
    printf '修改时间|%s\n' "$modified"
    printf 'SHA-256|%s\n' "$sha"
  } > "$tmp"

  gum table --print --separator "|" --border rounded < "$tmp"
  rm -f "$tmp"
}

preview_file() {
  local path="$1" mime
  mime="$(file -b --mime-type "$path" 2>/dev/null || printf '')"

  case "$mime" in
    text/*|application/json|application/xml|application/x-shellscript|inode/x-empty)
      head -c 200000 "$path" | gum pager
      ;;
    *)
      warn "这看起来不是文本文件，改为显示文件信息。"
      file_information "$path"
      ;;
  esac
}

edit_file() {
  local path="$1"
  if [[ -n "${EDITOR:-}" ]]; then
    # EDITOR is intentionally respected as a user-configured command.
    $EDITOR "$path"
  elif command -v nano >/dev/null 2>&1; then
    nano "$path"
  elif command -v vim >/dev/null 2>&1; then
    vim "$path"
  elif command -v vi >/dev/null 2>&1; then
    vi "$path"
  else
    error "未找到编辑器。可运行：pkg install nano"
  fi
}

file_center() {
  while true; do
    safe_clear
    banner
    gum style --bold --foreground "$PURPLE" "📁 文件中心"

    local selected action
    selected="$(gum file "$HOME" \
      --height 16 \
      --header "选择一个文件；Esc 返回" \
      --cursor.foreground "$PINK" \
      --selected.foreground "$CYAN" 2>/dev/null)" || return 0

    [[ -n "$selected" ]] || return 0

    action="$(choose_or_return "文件：$selected" \
      "👁 预览" \
      "✏️ 编辑" \
      "ℹ️ 文件信息" \
      "📋 复制路径" \
      "🗑 删除文件" \
      "↩ 重新选择" \
      "🏠 返回主菜单")" || return 0

    case "$action" in
      "👁 预览")
        preview_file "$selected"
        press_enter
        ;;
      "✏️ 编辑")
        edit_file "$selected"
        ;;
      "ℹ️ 文件信息")
        file_information "$selected"
        press_enter
        ;;
      "📋 复制路径")
        copy_text "$selected"
        press_enter
        ;;
      "🗑 删除文件")
        if gum confirm "确认删除这个文件？" \
          --affirmative "删除" \
          --negative "取消"; then
          if rm -- "$selected"; then
            success "文件已删除"
          else
            error "删除失败"
          fi
          press_enter
        fi
        ;;
      "↩ 重新选择")
        ;;
      *)
        return 0
        ;;
    esac
  done
}

# ---------- Notes ----------
note_label_for_file() {
  local file="$1" title
  title="$(sed -n '1s/^# //p' "$file" 2>/dev/null)"
  [[ -n "$title" ]] || title="无标题"
  printf '%s | %s' "$(basename "$file")" "$title"
}

select_note_file() {
  local -a files labels
  local f selected filename

  mapfile -t files < <(
    find "$NOTES_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort -r
  )

  if ((${#files[@]} == 0)); then
    warn "还没有便签"
    return 1
  fi

  labels=()
  for f in "${files[@]}"; do
    labels+=("$(note_label_for_file "$f")")
  done

  selected="$(printf '%s\n' "${labels[@]}" | gum filter \
    --height 15 \
    --placeholder "搜索便签…")" || return 1

  filename="${selected%% | *}"
  [[ -n "$filename" ]] || return 1
  printf '%s/%s' "$NOTES_DIR" "$filename"
}

create_note() {
  local title content file
  title="$(gum input \
    --prompt "标题 › " \
    --placeholder "例如：Termux 学习计划" \
    --width 60)" || return 0
  [[ -n "$title" ]] || title="无标题"

  content="$(gum write \
    --placeholder "输入正文；Ctrl+D 完成…" \
    --width 70 \
    --height 14)" || return 0

  file="$NOTES_DIR/$(date '+%Y%m%d-%H%M%S')-$RANDOM.md"
  {
    printf '# %s\n\n' "$title"
    printf '%s\n' "$content"
  } > "$file"

  success "便签已保存：$file"
}

view_note() {
  local file
  file="$(select_note_file)" || return 0
  gum format < "$file" | gum pager
}

edit_note() {
  local file
  file="$(select_note_file)" || return 0
  edit_file "$file"
}

delete_note() {
  local file
  file="$(select_note_file)" || return 0
  if gum confirm "删除便签 $(basename "$file")？" \
    --affirmative "删除" \
    --negative "取消"; then
    rm -f -- "$file"
    success "便签已删除"
  fi
}

notes_center() {
  while true; do
    safe_clear
    banner
    gum style --bold --foreground "$PURPLE" "📝 Markdown 便签"

    local action
    action="$(choose_or_return "便签存放在 $NOTES_DIR" \
      "➕ 新建便签" \
      "🔎 查找并查看" \
      "✏️ 编辑便签" \
      "🗑 删除便签" \
      "🏠 返回主菜单")" || return 0

    case "$action" in
      "➕ 新建便签") create_note; press_enter ;;
      "🔎 查找并查看") view_note ;;
      "✏️ 编辑便签") edit_note ;;
      "🗑 删除便签") delete_note; press_enter ;;
      *) return 0 ;;
    esac
  done
}

# ---------- Todo manager ----------
add_todo() {
  local text id
  text="$(gum input \
    --prompt "任务 › " \
    --placeholder "输入待办事项" \
    --width 70)" || return 0
  text="${text//$'\t'/ }"
  text="${text//$'\n'/ }"
  [[ -n "$text" ]] || return 0

  id="$(date '+%s')-$RANDOM"
  printf '%s\t%s\t%s\n' "$id" "TODO" "$text" >> "$TODO_FILE"
  success "待办已添加"
}

show_todos() {
  local tmp
  if [[ ! -s "$TODO_FILE" ]]; then
    warn "待办列表为空"
    return 0
  fi

  tmp="$(mktemp)"
  {
    printf '状态|任务|ID\n'
    awk -F '\t' '
      {
        status=($2=="DONE" ? "✓ 已完成" : "• 待处理")
        text=$3
        gsub(/\|/, "/", text)
        printf "%s|%s|%s\n", status, text, $1
      }
    ' "$TODO_FILE"
  } > "$tmp"

  gum table \
    --print \
    --separator "|" \
    --border rounded \
    --header.foreground "$PINK" \
    --border.foreground "$PURPLE" \
    < "$tmp"
  rm -f "$tmp"
}

select_todo_id() {
  local selected
  if [[ ! -s "$TODO_FILE" ]]; then
    warn "待办列表为空"
    return 1
  fi

  selected="$(
    awk -F '\t' '{
      icon=($2=="DONE" ? "✓" : "•")
      printf "%s %s [%s]\n", icon, $3, $1
    }' "$TODO_FILE" |
      gum filter --height 15 --placeholder "搜索任务…"
  )" || return 1

  selected="${selected##*[}"
  selected="${selected%]}"
  [[ -n "$selected" ]] || return 1
  printf '%s' "$selected"
}

toggle_todo() {
  local id tmp
  id="$(select_todo_id)" || return 0
  tmp="$(mktemp)"

  awk -F '\t' -v id="$id" '
    BEGIN { OFS=FS }
    {
      if ($1 == id) {
        $2=($2=="DONE" ? "TODO" : "DONE")
      }
      print
    }
  ' "$TODO_FILE" > "$tmp" && mv "$tmp" "$TODO_FILE"

  success "任务状态已更新"
}

delete_todo() {
  local id tmp
  id="$(select_todo_id)" || return 0

  if ! gum confirm "确认删除选中的任务？" \
    --affirmative "删除" \
    --negative "取消"; then
    return 0
  fi

  tmp="$(mktemp)"
  awk -F '\t' -v id="$id" '$1 != id' "$TODO_FILE" > "$tmp" &&
    mv "$tmp" "$TODO_FILE"
  success "任务已删除"
}

clear_done_todos() {
  if ! grep -q $'\tDONE\t' "$TODO_FILE" 2>/dev/null; then
    warn "没有已完成任务"
    return 0
  fi

  if gum confirm "清除全部已完成任务？" \
    --affirmative "清除" \
    --negative "取消"; then
    local tmp
    tmp="$(mktemp)"
    awk -F '\t' '$2 != "DONE"' "$TODO_FILE" > "$tmp" &&
      mv "$tmp" "$TODO_FILE"
    success "已完成任务已清除"
  fi
}

todo_center() {
  while true; do
    safe_clear
    banner
    gum style --bold --foreground "$PURPLE" "✅ 待办事项"

    show_todos
    printf '\n'

    local action
    action="$(choose_or_return "选择操作" \
      "➕ 添加任务" \
      "🔁 切换完成状态" \
      "🗑 删除任务" \
      "🧹 清除已完成" \
      "🏠 返回主菜单")" || return 0

    case "$action" in
      "➕ 添加任务") add_todo; press_enter ;;
      "🔁 切换完成状态") toggle_todo; press_enter ;;
      "🗑 删除任务") delete_todo; press_enter ;;
      "🧹 清除已完成") clear_done_todos; press_enter ;;
      *) return 0 ;;
    esac
  done
}

# ---------- Package manager ----------
package_search_install() {
  local query tmp package_name
  query="$(gum input \
    --prompt "关键词 › " \
    --placeholder "例如：python / git / openssh" \
    --width 60)" || return 0
  [[ -n "$query" ]] || return 0

  tmp="$(mktemp)"
  gum spin \
    --spinner dot \
    --title "正在搜索 Termux 软件包…" \
    -- bash -c 'pkg search "$1" >"$2" 2>&1' _ "$query" "$tmp"

  gum pager < "$tmp"
  rm -f "$tmp"

  package_name="$(gum input \
    --prompt "包名 › " \
    --placeholder "输入要安装的准确包名；留空取消" \
    --width 60)" || return 0
  [[ -n "$package_name" ]] || return 0

  if gum confirm "安装 $package_name？" \
    --affirmative "安装" \
    --negative "取消"; then
    gum spin \
      --show-output \
      --spinner globe \
      --title "正在安装 $package_name…" \
      -- pkg install -y "$package_name"
  fi
}

list_installed_packages() {
  pkg list-installed 2>&1 | gum pager
}

upgrade_packages() {
  if gum confirm "执行 pkg upgrade -y？" \
    --affirmative "升级" \
    --negative "取消"; then
    gum spin \
      --show-output \
      --spinner meter \
      --title "正在升级软件包…" \
      -- pkg upgrade -y
  fi
}

uninstall_package() {
  local package_name
  package_name="$(
    pkg list-installed 2>/dev/null |
      awk -F/ 'NF > 1 {print $1}' |
      gum filter --height 16 --placeholder "搜索已安装软件包…"
  )" || return 0

  [[ -n "$package_name" ]] || return 0

  if gum confirm "卸载 $package_name？" \
    --affirmative "卸载" \
    --negative "取消"; then
    gum spin \
      --show-output \
      --spinner points \
      --title "正在卸载 $package_name…" \
      -- pkg uninstall -y "$package_name"
  fi
}

package_center() {
  while true; do
    safe_clear
    banner
    gum style --bold --foreground "$PURPLE" "📦 Termux 软件包管理"

    local action
    action="$(choose_or_return "危险操作均会再次确认" \
      "🔎 搜索并安装" \
      "📚 查看已安装软件包" \
      "⬆️ 升级全部软件包" \
      "🗑 卸载软件包" \
      "🏠 返回主菜单")" || return 0

    case "$action" in
      "🔎 搜索并安装") package_search_install; press_enter ;;
      "📚 查看已安装软件包") list_installed_packages ;;
      "⬆️ 升级全部软件包") upgrade_packages; press_enter ;;
      "🗑 卸载软件包") uninstall_package; press_enter ;;
      *) return 0 ;;
    esac
  done
}

# ---------- Network tools ----------
ping_host() {
  local host
  host="$(gum input \
    --prompt "主机 › " \
    --value "github.com" \
    --width 60)" || return 0
  [[ -n "$host" ]] || return 0

  if command -v ping >/dev/null 2>&1; then
    gum spin \
      --show-output \
      --spinner pulse \
      --title "Ping $host…" \
      -- ping -c 4 "$host"
  else
    error "未找到 ping。可运行：pkg install iputils"
  fi
}

http_headers() {
  local url tmp
  if ! command -v curl >/dev/null 2>&1; then
    error "未找到 curl。可运行：pkg install curl"
    return 0
  fi

  url="$(gum input \
    --prompt "URL › " \
    --value "https://github.com" \
    --width 70)" || return 0
  [[ -n "$url" ]] || return 0

  tmp="$(mktemp)"
  gum spin \
    --spinner moon \
    --title "正在请求 HTTP 响应头…" \
    -- bash -c 'curl -fsSIL --max-time 15 "$1" >"$2" 2>&1' _ "$url" "$tmp"

  gum pager < "$tmp"
  rm -f "$tmp"
}

dns_lookup() {
  local host
  host="$(gum input \
    --prompt "域名 › " \
    --value "github.com" \
    --width 60)" || return 0
  [[ -n "$host" ]] || return 0

  if command -v getent >/dev/null 2>&1; then
    getent hosts "$host" | gum pager
  elif command -v nslookup >/dev/null 2>&1; then
    nslookup "$host" | gum pager
  else
    error "未找到 DNS 查询工具。可运行：pkg install dnsutils"
  fi
}

quick_network_diagnostic() {
  local tmp dns_result https_result ping_result
  tmp="$(mktemp)"

  gum spin \
    --spinner globe \
    --title "正在执行网络诊断…" \
    -- bash -c '
      host="$1"
      out="$2"

      if command -v getent >/dev/null 2>&1 &&
         getent hosts "$host" >/dev/null 2>&1; then
        dns="OK"
      else
        dns="失败或工具缺失"
      fi

      if command -v curl >/dev/null 2>&1; then
        code="$(curl -L -o /dev/null -sS --max-time 12 -w "%{http_code}" "https://$host" 2>/dev/null)"
        if [ -n "$code" ] && [ "$code" != "000" ]; then
          https="HTTP $code"
        else
          https="失败"
        fi
      else
        https="curl 未安装"
      fi

      if command -v ping >/dev/null 2>&1 &&
         ping -c 1 "$host" >/dev/null 2>&1; then
        ping_status="OK"
      else
        ping_status="失败或工具缺失"
      fi

      {
        printf "检查项|结果\n"
        printf "DNS|%s\n" "$dns"
        printf "HTTPS|%s\n" "$https"
        printf "Ping|%s\n" "$ping_status"
      } > "$out"
    ' _ "github.com" "$tmp"

  gum table --print --separator "|" --border rounded < "$tmp"
  rm -f "$tmp"
}

network_center() {
  while true; do
    safe_clear
    banner
    gum style --bold --foreground "$PURPLE" "🌐 网络工具"

    local action
    action="$(choose_or_return "所有参数都作为独立参数传递，不使用 eval" \
      "🩺 快速网络诊断" \
      "📡 Ping 主机" \
      "🌍 查看 HTTP 响应头" \
      "🔎 DNS 查询" \
      "🏠 返回主菜单")" || return 0

    case "$action" in
      "🩺 快速网络诊断") quick_network_diagnostic; press_enter ;;
      "📡 Ping 主机") ping_host; press_enter ;;
      "🌍 查看 HTTP 响应头") http_headers ;;
      "🔎 DNS 查询") dns_lookup; press_enter ;;
      *) return 0 ;;
    esac
  done
}

# ---------- Command builder ----------
show_generated_command() {
  local command="$1"
  printf '\n'
  gum style \
    --foreground "$CYAN" \
    --border-foreground "$PURPLE" \
    --border rounded \
    --padding "1 2" \
    --width "$(terminal_width)" \
    "$command"
  printf '\n'

  if gum confirm "复制这条命令？" \
    --affirmative "复制" \
    --negative "不复制"; then
    copy_text "$command"
  fi
}

command_builder() {
  local kind command=""
  safe_clear
  banner
  gum style --bold --foreground "$PURPLE" "🧩 安全命令生成器"

  kind="$(choose_or_return "仅生成并复制，不会自动执行" \
    "⬇️ curl 下载文件" \
    "🐙 git clone 仓库" \
    "🗜 创建 tar.gz 压缩包" \
    "🔍 find 查找文件" \
    "🐍 Python 临时 HTTP 服务" \
    "🔐 SSH 连接" \
    "🏠 返回主菜单")" || return 0

  case "$kind" in
    "⬇️ curl 下载文件")
      local url output
      url="$(gum input --prompt "URL › " --placeholder "https://example.com/file.zip" --width 70)" || return 0
      output="$(gum input --prompt "保存为 › " --placeholder "file.zip" --width 50)" || return 0
      [[ -n "$url" && -n "$output" ]] || return 0
      command="curl -fL $(shell_quote "$url") -o $(shell_quote "$output")"
      ;;
    "🐙 git clone 仓库")
      local repo directory
      repo="$(gum input --prompt "仓库 › " --placeholder "https://github.com/user/repo.git" --width 70)" || return 0
      directory="$(gum input --prompt "目录，可留空 › " --width 50)" || return 0
      [[ -n "$repo" ]] || return 0
      command="git clone $(shell_quote "$repo")"
      [[ -n "$directory" ]] && command+=" $(shell_quote "$directory")"
      ;;
    "🗜 创建 tar.gz 压缩包")
      local source archive
      source="$(gum input --prompt "源路径 › " --value "." --width 50)" || return 0
      archive="$(gum input --prompt "压缩包 › " --value "backup.tar.gz" --width 50)" || return 0
      [[ -n "$source" && -n "$archive" ]] || return 0
      command="tar -czf $(shell_quote "$archive") $(shell_quote "$source")"
      ;;
    "🔍 find 查找文件")
      local root pattern
      root="$(gum input --prompt "目录 › " --value "." --width 50)" || return 0
      pattern="$(gum input --prompt "名称模式 › " --value "*.sh" --width 50)" || return 0
      [[ -n "$root" && -n "$pattern" ]] || return 0
      command="find $(shell_quote "$root") -type f -name $(shell_quote "$pattern")"
      ;;
    "🐍 Python 临时 HTTP 服务")
      local port directory
      port="$(gum input --prompt "端口 › " --value "8000" --width 30)" || return 0
      directory="$(gum input --prompt "目录 › " --value "." --width 50)" || return 0
      [[ "$port" =~ ^[0-9]+$ ]] || {
        error "端口必须是数字"
        press_enter
        return 0
      }
      command="python -m http.server $(shell_quote "$port") --directory $(shell_quote "$directory")"
      ;;
    "🔐 SSH 连接")
      local user host port
      user="$(gum input --prompt "用户名 › " --placeholder "root" --width 40)" || return 0
      host="$(gum input --prompt "主机 › " --placeholder "192.168.1.10" --width 50)" || return 0
      port="$(gum input --prompt "端口 › " --value "22" --width 30)" || return 0
      [[ -n "$user" && -n "$host" && "$port" =~ ^[0-9]+$ ]] || return 0
      command="ssh -p $(shell_quote "$port") $(shell_quote "${user}@${host}")"
      ;;
    *)
      return 0
      ;;
  esac

  show_generated_command "$command"
  press_enter
}

# ---------- Gum showcase ----------
gum_showcase() {
  safe_clear
  banner

  gum spin \
    --spinner hamburger \
    --title "正在加载 Gum 组件…" \
    -- sleep 1

  local left right
  left="$(gum style \
    --border rounded \
    --border-foreground "$PINK" \
    --foreground "$CYAN" \
    --padding "1 2" \
    "choose" "input" "write" "filter")"

  right="$(gum style \
    --border double \
    --border-foreground "$PURPLE" \
    --foreground "$YELLOW" \
    --padding "1 2" \
    "table" "pager" "spin" "style")"

  gum join --horizontal --align center "$left" "$right"
  printf '\n'

  cat <<'EOF' | gum format
# Gum 功能展台

- **交互输入**：`input`、`write`
- **选择与过滤**：`choose`、`filter`、`file`
- **展示组件**：`style`、`join`、`table`、`format`
- **过程反馈**：`spin`、`log`、`confirm`

> 这些组件可以像普通 Unix 命令一样，通过管道和命令替换组合。
EOF

  printf '\n'
  gum log --level debug "DEBUG：开发调试信息"
  gum log --level info "INFO：普通状态消息"
  gum log --level warn "WARN：需要注意"
  gum log --level error "ERROR：错误展示，不代表脚本真的失败"

  printf '\n'
  printf '组件|本 Demo 中的用途\nchoose|主菜单与操作菜单\ninput|单行表单\nwrite|Markdown 便签正文\nfilter|搜索便签、任务和软件包\nfile|文件树选择器\ntable|系统信息和待办列表\npager|文件与命令输出预览\nspin|安装、网络请求等长任务\nstyle + join|标题和布局\nformat|Markdown 渲染\nlog|状态通知\nconfirm|危险操作确认\n' |
    gum table \
      --print \
      --separator "|" \
      --border rounded \
      --header.foreground "$PINK"

  press_enter
}

# ---------- About ----------
about_page() {
  safe_clear
  banner
  cat <<EOF | gum format | gum pager
# 关于这个 Demo

数据目录：

\`$APP_DIR\`

包含：

- Markdown 便签
- TSV 待办列表
- 剪贴板不可用时的文本备份
- Termux 软件包管理界面
- 文件浏览、预览、编辑与删除
- 网络诊断工具
- 安全命令生成器
- Gum 组件展示

## 建议安装

\`\`\`bash
pkg update
pkg install gum bash coreutils curl file nano
\`\`\`

可选增强：

\`\`\`bash
pkg install termux-api jq iputils dnsutils git openssh python
\`\`\`

使用 Termux:API 功能还需要安装与 Termux 来源匹配的 Termux:API Android 应用。
EOF
}

# ---------- Main ----------
main_menu() {
  while true; do
    safe_clear
    banner

    local choice
    choice="$(choose_or_return "选择一个模块；Esc 或选择退出均可结束" \
      "📊 系统信息" \
      "📁 文件中心" \
      "📝 Markdown 便签" \
      "✅ 待办事项" \
      "📦 软件包管理" \
      "🌐 网络工具" \
      "🧩 命令生成器" \
      "🎨 Gum 功能展台" \
      "ℹ️ 关于" \
      "🚪 退出")" || break

    case "$choice" in
      "📊 系统信息") system_dashboard ;;
      "📁 文件中心") file_center ;;
      "📝 Markdown 便签") notes_center ;;
      "✅ 待办事项") todo_center ;;
      "📦 软件包管理") package_center ;;
      "🌐 网络工具") network_center ;;
      "🧩 命令生成器") command_builder ;;
      "🎨 Gum 功能展台") gum_showcase ;;
      "ℹ️ 关于") about_page ;;
      *) break ;;
    esac
  done

  safe_clear
  gum style \
    --foreground "$PINK" \
    --border double \
    --border-foreground "$PURPLE" \
    --padding "1 3" \
    "感谢体验 $APP_NAME"
}

need_gum
main_menu

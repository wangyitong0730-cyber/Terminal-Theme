#!/bin/bash
# ============================================================
# 🎨 Terminal Theme — 多彩终端主题轮换系统 一键安装脚本
# 每个新终端窗口自动分配不同主题色，让多窗口工作一眼区分
# ============================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
info()  { echo -e "${BLUE}ℹ${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
err()   { echo -e "${RED}✗${NC} $1"; }

echo ""
echo -e "${PURPLE}🎨 Terminal Theme Installer${NC}"
echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================
# Step 1: 检查 Shell
# ============================================================
CURRENT_SHELL=$(basename "$SHELL")
if [[ "$CURRENT_SHELL" != "zsh" ]]; then
    err "当前默认 Shell 是 $CURRENT_SHELL，本主题系统需要 zsh"
    echo ""
    echo "  macOS 用户（默认就是 zsh，一般不需要操作）："
    echo "    chsh -s /bin/zsh"
    echo ""
    echo "  Linux 用户："
    echo "    sudo apt install zsh && chsh -s \$(which zsh)"
    echo ""
    exit 1
fi
ok "Shell: zsh ✓"

# ============================================================
# Step 2: 检测终端类型
# ============================================================
TERM_TYPE="unknown"
OSC11_SUPPORT=true
TAB_TITLE_SUPPORT=true
TERMINAL_DETECTION_CONFIDENCE="low"

detect_terminal() {
    if [[ -n "$TERM_PROGRAM" ]]; then
        TERMINAL_DETECTION_CONFIDENCE="high"
        case "$TERM_PROGRAM" in
            iTerm.app)
                TERM_TYPE="iterm2"
                OSC11_SUPPORT=true
                TAB_TITLE_SUPPORT=true
                ;;
            vscode|Qoder)
                TERM_TYPE="$TERM_PROGRAM"
                OSC11_SUPPORT=true
                TAB_TITLE_SUPPORT=true
                ;;
            Apple_Terminal)
                TERM_TYPE="terminal.app"
                OSC11_SUPPORT=false
                TAB_TITLE_SUPPORT=true
                ;;
            WezTerm)
                TERM_TYPE="wezterm"
                OSC11_SUPPORT=true
                TAB_TITLE_SUPPORT=true
                ;;
            *)
                TERM_TYPE="$TERM_PROGRAM"
                OSC11_SUPPORT=true
                TAB_TITLE_SUPPORT=true
                ;;
        esac
    elif [[ -n "$KITTY_PID" ]]; then
        TERM_TYPE="kitty"
        OSC11_SUPPORT=true
        TAB_TITLE_SUPPORT=true
        TERMINAL_DETECTION_CONFIDENCE="high"
    elif [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
        TERM_TYPE="ghostty"
        OSC11_SUPPORT=true
        TAB_TITLE_SUPPORT=true
        TERMINAL_DETECTION_CONFIDENCE="high"
    elif [[ -n "$ALACRITTY_WINDOW_ID" ]]; then
        TERM_TYPE="alacritty"
        OSC11_SUPPORT=true
        TAB_TITLE_SUPPORT=false
        TERMINAL_DETECTION_CONFIDENCE="high"
    elif [[ -n "$WEZTERM_EXECUTABLE" ]]; then
        TERM_TYPE="wezterm"
        OSC11_SUPPORT=true
        TAB_TITLE_SUPPORT=true
        TERMINAL_DETECTION_CONFIDENCE="high"
    fi
}

detect_terminal
ok "终端: $TERM_TYPE"

if [[ "$TERMINAL_DETECTION_CONFIDENCE" == "low" ]]; then
    warn "未能精确识别终端类型，将默认尝试启用动态背景色"
    warn "如果背景色没有变化，可重新运行脚本并手动禁用 OSC 11，或改用 iTerm2/Kitty/Ghostty/WezTerm 等终端"
    echo ""
elif [[ "$OSC11_SUPPORT" == false ]]; then
    warn "你的终端 ($TERM_TYPE) 不支持动态背景色切换"
    warn "主题提示符标签仍然可用，但背景色不会变化"
    echo ""
fi

# ============================================================
# Step 3: 检测/安装 Starship
# ============================================================
STARSHIP_PATH=""

find_starship() {
    # 按优先级查找
    if command -v starship &>/dev/null; then
        STARSHIP_PATH=$(command -v starship)
    elif [[ -x "$HOME/bin/starship" ]]; then
        STARSHIP_PATH="$HOME/bin/starship"
    elif [[ -x "/opt/homebrew/bin/starship" ]]; then
        STARSHIP_PATH="/opt/homebrew/bin/starship"
    elif [[ -x "/usr/local/bin/starship" ]]; then
        STARSHIP_PATH="/usr/local/bin/starship"
    fi
}

find_starship

if [[ -z "$STARSHIP_PATH" ]]; then
    warn "未检测到 Starship 提示符引擎"
    echo ""
    echo -e "  Starship 是一个轻量级跨平台提示符工具，用来显示主题标签。"
    echo ""
    read -p "  是否自动安装 Starship？(Y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        err "安装中止。请手动安装 Starship 后重试"
        echo "  安装命令: curl -sS https://starship.rs/install.sh | sh"
        exit 1
    fi

    info "正在安装 Starship..."
    if command -v brew &>/dev/null; then
        brew install starship
    else
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    find_starship
    if [[ -z "$STARSHIP_PATH" ]]; then
        err "Starship 安装失败，请手动安装后重试"
        exit 1
    fi
fi
ok "Starship: $STARSHIP_PATH"

# ============================================================
# Step 4: 可选插件（语法高亮 + 自动建议）
# ============================================================
ZSH_PLUGINS_DIR="$HOME/.zsh-plugins"
SYNTAX_HL=""
AUTOSUGG=""

# 检测已有插件
find_plugin() {
    local name=$1
    local paths=(
        "$ZSH_PLUGINS_DIR/$name/$name.zsh"
        "$HOME/zsh-plugins/$name/$name.zsh"
        "$HOME/.oh-my-zsh/custom/plugins/$name/$name.zsh"
        "/opt/homebrew/share/$name/$name.zsh"
        "/usr/local/share/$name/$name.zsh"
        "/usr/share/$name/$name.zsh"
    )
    for p in "${paths[@]}"; do
        if [[ -f "$p" ]]; then
            echo "$p"
            return
        fi
    done
}

SYNTAX_HL=$(find_plugin "zsh-syntax-highlighting")
AUTOSUGG=$(find_plugin "zsh-autosuggestions")

INSTALL_PLUGINS=false
if [[ -z "$SYNTAX_HL" || -z "$AUTOSUGG" ]]; then
    echo ""
    read -p "  是否安装 zsh 插件（语法高亮 + 自动建议）？推荐安装 (Y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        INSTALL_PLUGINS=true
        mkdir -p "$ZSH_PLUGINS_DIR"

        if [[ -z "$SYNTAX_HL" ]]; then
            info "安装 zsh-syntax-highlighting..."
            git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" 2>/dev/null
            SYNTAX_HL="$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        fi

        if [[ -z "$AUTOSUGG" ]]; then
            info "安装 zsh-autosuggestions..."
            git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_PLUGINS_DIR/zsh-autosuggestions" 2>/dev/null
            AUTOSUGG="$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
        fi
    fi
fi

[[ -n "$SYNTAX_HL" ]] && ok "语法高亮: $SYNTAX_HL"
[[ -n "$AUTOSUGG" ]] && ok "自动建议: $AUTOSUGG"

# ============================================================
# Step 4.5: 安全扫描 — 检查 .zshrc 中是否有明文密钥
# ============================================================
if [[ -f "$HOME/.zshrc" ]]; then
    SECRETS_FOUND=$(grep -niE '(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL|API_KEY)=' "$HOME/.zshrc" 2>/dev/null | grep -v '^#' | grep -v '# ')
    if [[ -n "$SECRETS_FOUND" ]]; then
        echo ""
        warn "检测到 .zshrc 中可能存在明文密钥："
        echo "$SECRETS_FOUND" | while IFS= read -r line; do
            LINE_NUM=$(echo "$line" | cut -d: -f1)
            KEY_NAME=$(echo "$line" | grep -oE '[A-Z_]*(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL)[A-Z_]*' | head -1)
            warn "  第 ${LINE_NUM} 行: ${KEY_NAME:-未知密钥}"
        done
        echo ""
        warn "建议：将密钥移到独立文件（如 ~/.env.secrets），zshrc 中改为 source ~/.env.secrets"
        read -p "  是否继续安装？(Y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            info "安装中止。请先处理密钥后重试"
            exit 0
        fi
    fi
fi

# ============================================================
# Step 5: 备份 .zshrc
# ============================================================
ZSHRC="$HOME/.zshrc"
BACKUP="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"

if [[ -f "$ZSHRC" ]]; then
    cp "$ZSHRC" "$BACKUP"
    ok "已备份 .zshrc → $BACKUP"
fi

# ============================================================
# Step 6: 检查是否已安装
# ============================================================
if grep -q "# === 彩色终端主题 START ===" "$ZSHRC" 2>/dev/null; then
    warn "检测到已安装过终端主题，将替换为最新版本"
    sed -i.bak '/# === 彩色终端主题 START ===/,/# === 彩色终端主题 END ===/d' "$ZSHRC"
    rm -f "$ZSHRC.bak"
elif grep -q "彩色终端主题" "$ZSHRC" 2>/dev/null; then
    warn "检测到旧版本终端主题配置，将迁移为带边界标记的新版本"
    sed -i.bak '/# === 彩色终端主题/,$d' "$ZSHRC"
    rm -f "$ZSHRC.bak"
fi

# ============================================================
# Step 7: 写入主题配置
# ============================================================
info "写入主题配置..."

# 根据终端类型生成配置
BG_COLOR_BLOCK=""
if [[ "$OSC11_SUPPORT" == true ]]; then
    BG_COLOR_BLOCK='# === 用主题色设置终端背景（深色版本） ===
_HEX=${_PROMPT_BG[$_IDX]}
_R=$(( 16#${_HEX:0:2} ))
_G=$(( 16#${_HEX:2:2} ))
_B=$(( 16#${_HEX:4:2} ))
# 混合比例：25% 主题色 + 75% 纯黑（可调整 25 这个数字）
_BR=$(( _R * 25 / 100 ))
_BG_G=$(( _G * 25 / 100 ))
_BB=$(( _B * 25 / 100 ))
_BG_HEX=$(printf "%02x%02x%02x" $_BR $_BG_G $_BB)
printf "\033]11;#${_BG_HEX}\007"'
else
    BG_COLOR_BLOCK='# === 终端背景色 ===
# 当前终端不支持 OSC 11 动态背景色，跳过背景色设置
# 如切换到 iTerm2/Kitty/Ghostty/WezTerm 等终端，重新运行安装脚本即可启用'
fi

cat >> "$ZSHRC" << 'THEME_START'

# === 彩色终端主题 START ===
# === 彩色终端主题 - 每个窗口轮流分配不同颜色 ===
# GitHub: 请将 README 中的仓库地址替换为你的实际 GitHub 仓库地址
_PROMPT_FG=(ffffff 1a1b26 1a1b26 ffffff ffffff 1a1b26 ffffff 1a1b26)
_PROMPT_BG=(f7768e 7aa2f7 9ece6a bb9af7 3d59a1 e0af68 db4b4b 73daca)
_PROMPT_TEXT=(f7768e 7aa2f7 9ece6a bb9af7 7aa2f7 e0af68 db4b4b 73daca)
_PROMPT_ICON=(🌸 🔵 🍀 💜 🌌 ✨ 🌹 🌊)
_PROMPT_NAME=("樱花粉" "天空蓝" "清新绿" "薰衣草" "深海靛" "琥珀金" "玫瑰红" "薄荷青")
# 用文件计数器保证每个窗口颜色不同
_CNT_FILE="/tmp/.zsh_prompt_counter_${UID}"
if [[ -f "$_CNT_FILE" ]]; then
  _CNT=$(<"$_CNT_FILE")
else
  _CNT=0
fi
echo $(( _CNT + 1 )) > "$_CNT_FILE"
_IDX=$(( _CNT % ${#_PROMPT_BG[@]} + 1 ))

THEME_START

# 写入背景色配置（根据终端类型）
echo "$BG_COLOR_BLOCK" >> "$ZSHRC"

# ANSI 调色板
cat >> "$ZSHRC" << 'ANSI_BLOCK'

# === 修改 ANSI 调色板让终端文字跟随主题色 ===
_TEXT_HEX=${_PROMPT_TEXT[$_IDX]}
_TR=$(( 16#${_TEXT_HEX:0:2} ))
_TG=$(( 16#${_TEXT_HEX:2:2} ))
_TB=$(( 16#${_TEXT_HEX:4:2} ))
_A15_R=$(( _TR + (255 - _TR) * 30 / 100 ))
_A15_G=$(( _TG + (255 - _TG) * 30 / 100 ))
_A15_B=$(( _TB + (255 - _TB) * 30 / 100 ))
_A15_HEX=$(printf "%02x/%02x/%02x" $_A15_R $_A15_G $_A15_B)
_A7_R=$(( _TR * 60 / 100 ))
_A7_G=$(( _TG * 60 / 100 ))
_A7_B=$(( _TB * 60 / 100 ))
_A7_HEX=$(printf "%02x/%02x/%02x" $_A7_R $_A7_G $_A7_B)
_A9_HEX=$(printf "%02x/%02x/%02x" $_TR $_TG $_TB)
printf "\033]4;15;rgb:${_A15_HEX}\007"
printf "\033]4;7;rgb:${_A7_HEX}\007"
printf "\033]4;9;rgb:${_A9_HEX}\007"

ANSI_BLOCK

# Tab 标题（根据终端类型）
cat >> "$ZSHRC" << 'TITLE_BLOCK'
# === Tab/窗口自动命名 ===
_THEME_LABEL="${_PROMPT_ICON[$_IDX]} ${_PROMPT_NAME[$_IDX]}"
_update_terminal_title() {
  local dir_name="${PWD##*/}"
  [[ "$dir_name" == "$USER" ]] && dir_name="~"
  print -Pn "\e]1;${_THEME_LABEL} — ${dir_name}\a"
  print -Pn "\e]2;${_THEME_LABEL} — %~\a"
}
_update_terminal_title

TITLE_BLOCK

# Starship 配置（使用检测到的路径）
# 写入一个 zsh 函数，在每次终端打开时动态生成 starship toml
cat >> "$ZSHRC" << 'STARSHIP_BLOCK'
# === Starship 提示符 ===
_THEME_COLOR="#${_PROMPT_TEXT[$_IDX]}"
_STARSHIP_CFG="$HOME/.config/starship-themed-$$.toml"
export STARSHIP_CONFIG="$_STARSHIP_CFG"
mkdir -p "$HOME/.config"
{
  echo "format = \"\"\""
  echo '$directory\\'
  echo '$git_branch\\'
  echo '$git_status\\'
  echo '$nodejs\\'
  echo '$python\\'
  echo '$cmd_duration\\'
  echo '$line_break\\'
  echo '$character'
  echo "\"\"\""
  echo ""
  echo "right_format = \"\"\"\\$time\"\"\""
  echo ""
  echo "[character]"
  echo "success_symbol = \"[❯](bold $_THEME_COLOR)\""
  echo "error_symbol = \"[❯](bold red)\""
  echo ""
  echo "[directory]"
  echo "style = \"bold $_THEME_COLOR\""
  echo "truncation_length = 3"
  echo 'truncation_symbol = "…/"'
  echo 'read_only = " 🔒"'
  echo ""
  echo "[git_branch]"
  echo 'symbol = " "'
  echo "style = \"bold $_THEME_COLOR\""
  echo 'format = "[$symbol$branch]($style) "'
  echo ""
  echo "[git_status]"
  echo "format = '([\$all_status\$ahead_behind](\$style) )'"
  echo 'style = "bold red"'
  echo ""
  echo "[nodejs]"
  echo 'symbol = " "'
  echo 'format = "[$symbol($version)]($style) "'
  echo 'style = "bold green"'
  echo ""
  echo "[python]"
  echo 'symbol = " "'
  echo 'format = "[$symbol($version)]($style) "'
  echo 'style = "bold yellow"'
  echo ""
  echo "[cmd_duration]"
  echo "min_time = 2_000"
  echo 'format = "[⏱ $duration]($style) "'
  echo 'style = "bold yellow"'
  echo ""
  echo "[time]"
  echo "disabled = false"
  echo 'format = "[$time]($style)"'
  echo 'style = "dimmed white"'
  echo 'time_format = "%H:%M"'
} > "$_STARSHIP_CFG"
trap "rm -f '$_STARSHIP_CFG'" EXIT

# 主题标签注入
precmd() { _update_terminal_title; }
STARSHIP_BLOCK

# eval 行需要插入实际的 starship 路径（不加引号的 heredoc）
cat >> "$ZSHRC" << STARSHIP_EVAL
eval "\$(${STARSHIP_PATH} init zsh)"
STARSHIP_EVAL

cat >> "$ZSHRC" << 'STARSHIP_TAG'
_theme_tag="%K{#${_PROMPT_BG[$_IDX]}}%F{#${_PROMPT_FG[$_IDX]}} ${_PROMPT_ICON[$_IDX]} ${_PROMPT_NAME[$_IDX]} %f%k "
starship_precmd_user_func() { PROMPT="${_theme_tag}${PROMPT}"; }
precmd_functions+=(starship_precmd_user_func)
STARSHIP_TAG

# 插件配置
cat >> "$ZSHRC" << PLUGIN_BLOCK

# === zsh 插件 ===
PLUGIN_BLOCK

if [[ -n "$SYNTAX_HL" ]]; then
    echo "source \"$SYNTAX_HL\" 2>/dev/null" >> "$ZSHRC"
fi
if [[ -n "$AUTOSUGG" ]]; then
    cat >> "$ZSHRC" << 'AUTOSUGG_BLOCK'
source "$AUTOSUGG" 2>/dev/null
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
AUTOSUGG_BLOCK
    # 修正路径
    sed -i.bak "s|\"\$AUTOSUGG\"|\"$AUTOSUGG\"|" "$ZSHRC"
    rm -f "$ZSHRC.bak"
fi

# 美化（区分 macOS 和 Linux）
if [[ "$(uname)" == "Darwin" ]]; then
cat >> "$ZSHRC" << 'LS_BLOCK'

# === ls 美化 ===
export CLICOLOR=1
export LSCOLORS="GxFxCxDxBxegedabagaced"
alias ls='ls -G'
alias ll='ls -lhG'
alias la='ls -lahG'
LS_BLOCK
else
cat >> "$ZSHRC" << 'LS_BLOCK_LINUX'

# === ls 美化 ===
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lah --color=auto'
LS_BLOCK_LINUX
fi

cat >> "$ZSHRC" << 'THEME_END'

# === 彩色终端主题 END ===
THEME_END

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ 安装完成！${NC}"
echo ""
echo -e "  终端: ${CYAN}$TERM_TYPE${NC}"
echo -e "  背景色: $([ "$OSC11_SUPPORT" == true ] && echo "${GREEN}支持${NC}" || echo "${YELLOW}不支持（仅提示符标签生效）${NC}")"
echo -e "  主题数: ${CYAN}8 个${NC}（樱花粉/天空蓝/清新绿/薰衣草/深海靛/琥珀金/玫瑰红/薄荷青）"
echo -e "  备份: ${CYAN}$BACKUP${NC}"
echo ""
echo -e "  ${YELLOW}👉 打开一个新终端窗口即可看到效果${NC}"
echo -e "  ${YELLOW}👉 多开几个窗口，每个都是不同颜色${NC}"
echo ""
echo -e "  卸载: ${CYAN}bash uninstall.sh${NC}"
echo ""

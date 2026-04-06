#!/bin/bash
# ============================================================
# 🎨 Terminal Theme — 卸载脚本
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}ℹ${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }

echo ""
echo -e "${RED}🗑  Terminal Theme Uninstaller${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ZSHRC="$HOME/.zshrc"

# 检查是否安装过
HAS_MARKED_CONFIG=false
HAS_LEGACY_CONFIG=false

if grep -q "# === 彩色终端主题 START ===" "$ZSHRC" 2>/dev/null; then
    HAS_MARKED_CONFIG=true
elif grep -q "彩色终端主题" "$ZSHRC" 2>/dev/null; then
    HAS_LEGACY_CONFIG=true
else
    warn "未检测到终端主题配置，无需卸载"
    exit 0
fi

# 备份
BACKUP="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
cp "$ZSHRC" "$BACKUP"
ok "已备份 .zshrc → $BACKUP"

# 删除主题配置
if [[ "$HAS_MARKED_CONFIG" == true ]]; then
    sed -i.bak '/# === 彩色终端主题 START ===/,/# === 彩色终端主题 END ===/d' "$ZSHRC"
    rm -f "$ZSHRC.bak"
    ok "已移除主题配置"
else
    warn "检测到旧版本配置，将按旧版方式移除（可能删除主题配置后追加的内容）"
    sed -i.bak '/# === 彩色终端主题/,$d' "$ZSHRC"
    rm -f "$ZSHRC.bak"
    ok "已移除旧版主题配置"
fi

# 清理临时文件
rm -f /tmp/.zsh_prompt_counter_* 2>/dev/null
rm -f "$HOME/.config/starship-themed-"*.toml 2>/dev/null
ok "已清理临时文件"

# 重置终端背景色为默认
printf "\033]11;#000000\007" 2>/dev/null
ok "已重置终端背景色"

echo ""
echo -e "${GREEN}✓ 卸载完成${NC}"
echo ""
echo -e "  备份文件: ${BLUE}$BACKUP${NC}"
echo -e "  如需恢复: cp \"$BACKUP\" ~/.zshrc"
echo ""
echo -e "  ${YELLOW}👉 打开新终端窗口即可恢复默认样式${NC}"
echo ""

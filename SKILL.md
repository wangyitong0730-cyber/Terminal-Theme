---
name: terminal-theme
description: 配置和管理终端多彩主题轮换系统 — 添加/修改/删除主题、调整颜色和背景混合比例、排查显示问题。当用户提到终端主题、终端颜色、终端配色、prompt颜色、tab颜色时触发。
user-invocable: true
argument-hint: "[add/modify/remove/list/reset/troubleshoot]"
---

# Terminal Theme - 多彩终端主题轮换系统

为 zsh + Starship 打造的多主题轮换系统，兼容主流终端（iTerm2/Kitty/Ghostty/WezTerm/Alacritty/VS Code/Qoder/Windows Terminal）。每个新终端窗口自动分配不同主题色，包括提示符标签、终端背景色（深色混合）和 Tab 标题，让多窗口工作时一眼区分。

## 终端兼容性

| 终端 | 背景色(OSC 11) | 提示符标签 | Tab 标题 |
|------|---------------|-----------|---------|
| iTerm2 | ✅ | ✅ | ✅ |
| Kitty | ✅ | ✅ | ✅ |
| Ghostty | ✅ | ✅ | ✅ |
| WezTerm | ✅ | ✅ | ✅ |
| Alacritty | ✅ | ✅ | ❌ |
| VS Code 终端 | ✅ | ✅ | ✅ |
| Qoder 终端 | ✅ | ✅ | ✅ |
| Windows Terminal | ✅ | ✅ | ✅ |
| macOS Terminal.app | ❌ | ✅ | ✅ |

不支持 OSC 11 的终端会自动降级为仅显示彩色提示符标签。

## 意图路由

根据用户的话判断走哪个流程：

| 用户可能说的话 | 对应流程 |
|---------------|----------|
| "加个新主题"、"来个紫色"、"再加一个颜色"、"多一个主题" | → 流程 A: 添加 |
| "改一下颜色"、"把XX换成XX"、"换个图标"、"改个名字" | → 流程 B: 修改 |
| "删掉XX"、"去掉这个主题"、"不要XX了" | → 流程 C: 删除 |
| "有哪些主题"、"看看当前配色"、"列出主题" | → 流程 D: 查看 |
| "背景太暗/太亮"、"调一下比例"、"背景色调不明显" | → 流程 E: 调比例 |
| "颜色乱了"、"都一个颜色"、"重置一下" | → 流程 F: 重置 |
| "主题不显示"、"背景没变"、"终端有问题" | → 流程 G: 排查 |

---

### 流程 A: 添加新主题

#### Step 1: 确认新主题信息

向用户确认（如果未提供）：
- **主题名称**：中文名，2-4 个字（如"樱花粉"、"极光紫"）
- **主题颜色**：HEX 色值（如 `#ff6b9d`），或描述颜色让 AI 推荐
- **图标 emoji**：一个能代表这个颜色/氛围的 emoji

**如果用户没指定颜色**，从以下推荐色中选一个（避免与现有主题撞色）：

| 推荐色 | HEX | 适合名称 | 来源 |
|--------|-----|----------|------|
| 玫瑰红 | `#f7768e` 附近已有，跳过 | - | - |
| 靛蓝 | `#3d59a1` | 深海蓝 | Tokyo Night |
| 品红 | `#ff007c` | 霓虹粉 | Neon |
| 翡翠 | `#2ac3de` | 翡翠青 | Tokyo Night |
| 酒红 | `#914c54` | 酒红 | 暖调 |
| 柠檬 | `#e0d68a` | 柠檬黄 | 暖调 |
| 深紫 | `#6c3483` | 暗夜紫 | 冷调 |

撞色检查：新色与现有 8 色的色相差应 > 30°，避免太接近。

#### Step 2: 确定前景色

根据背景色亮度自动判断前景色：
- 将 HEX 转为 RGB，计算亮度 `(R×299 + G×587 + B×114) / 1000`
- **> 128** → 浅色背景 → 深色字 `1a1b26`
- **≤ 128** → 深色背景 → 白色字 `ffffff`

#### Step 3: 编辑 ~/.zshrc

1. 用 Grep 搜索 `_PROMPT_FG=` 定位到主题数组区域
2. 找到 5 个数组：`_PROMPT_FG`、`_PROMPT_BG`、`_PROMPT_TEXT`、`_PROMPT_ICON`、`_PROMPT_NAME`
3. 在每个数组的**末尾元素后、右括号前**追加新值

```zsh
_PROMPT_FG=(... "新前景色")     # ffffff 或 1a1b26
_PROMPT_BG=(... "新背景色")     # 6位 hex，不带 #
_PROMPT_TEXT=(... "新主题色")    # 同背景色，ANSI 调色基准
_PROMPT_ICON=(... "新图标")     # emoji
_PROMPT_NAME=(... "新名称")     # 中文名
```

**关键**：5 个数组必须同步，新值都在同一索引位置。

#### Step 4: 验证

运行验证命令确认数组长度一致：

```bash
zsh -c 'source ~/.zshrc 2>/dev/null; echo "FG=${#_PROMPT_FG[@]} BG=${#_PROMPT_BG[@]} TEXT=${#_PROMPT_TEXT[@]} ICON=${#_PROMPT_ICON[@]} NAME=${#_PROMPT_NAME[@]}"'
```

5 个数字必须相同，否则说明编辑有误。

#### Step 5: 更新文档 & 通知用户

1. 更新本 skill 文档中的"当前主题列表"表格
2. 告诉用户：打开新终端窗口即可看到新主题

---

### 流程 B: 修改现有主题

#### Step 1: 确认修改内容

向用户确认：
- 要修改哪个主题（名称或序号）
- 要改什么（颜色/图标/名称）

#### Step 2: 编辑 ~/.zshrc

1. 用 Grep 搜索 `_PROMPT_FG=` 定位到主题数组区域
2. 根据序号确定索引位置（序号 = 数组中第几个元素）
3. 替换目标元素

如果改了背景色，需要重新判断前景色（参考流程 A Step 2）。

#### Step 3: 验证

运行流程 A Step 4 的验证命令。

#### Step 4: 更新文档

更新本 skill 文档中的"当前主题列表"表格。

---

### 流程 C: 删除主题

#### Step 1: 确认要删除的主题

#### Step 2: 编辑 ~/.zshrc

1. 用 Grep 搜索 `_PROMPT_FG=` 定位到主题数组区域
2. 从 5 个数组中同步删除对应索引位置的值

#### Step 3: 重置计数器 & 验证

```bash
rm -f /tmp/.zsh_prompt_counter
```

运行流程 A Step 4 的验证命令。

#### Step 4: 更新文档

更新本 skill 文档中的"当前主题列表"表格。

---

### 流程 D: 查看当前主题列表

直接展示下方"当前主题列表"表格给用户。

---

### 流程 E: 调整背景混合比例

#### Step 1: 确认新比例

当前是 25%（经验最佳值）。参考：
- **20-25%** → 推荐值，平衡色调辨识和阅读舒适
- **8-12%** → 更接近纯黑，色调微弱
- **30%+** → 色调更明显，但背景更亮

#### Step 2: 编辑 ~/.zshrc

用 Grep 搜索 `_R * 25` 定位到混合计算代码，将 3 行中的 `25` 替换为新比例值。

#### Step 3: 验证

提示用户打开新终端窗口查看效果。

---

### 流程 F: 重置计数器

当所有窗口颜色相同或顺序混乱时：

```bash
rm -f /tmp/.zsh_prompt_counter
```

提示用户重新打开终端窗口。

---

### 流程 G: 排查问题

| 症状 | 诊断步骤 | 解决方案 |
|------|----------|----------|
| 所有窗口颜色一样 | `cat /tmp/.zsh_prompt_counter` 检查计数器 | `rm -f /tmp/.zsh_prompt_counter` 后重开终端 |
| 背景色不变 | `echo $TERM_PROGRAM` 确认终端类型 | 如果是 Terminal.app 则不支持 OSC 11，换用 iTerm2/Kitty/Ghostty/WezTerm 等终端 |
| 主题标签不显示 | `which starship` 确认是否安装 | 运行 `curl -sS https://starship.rs/install.sh \| sh` 或 `brew install starship` |
| Claude Code 输入区没变色 | 确认终端支持 OSC 4 调色板修改 | 升级终端到最新版，大多数现代终端都支持 |
| 新主题不生效 | 运行流程 A Step 4 的验证命令 | 确保 4 个数组元素数量相同 |
| `source ~/.zshrc` 报错 | 检查数组语法（引号、空格） | 用 `zsh -n ~/.zshrc` 语法检查 |

---

## 当前主题列表

| 序号 | 名称 | 前景色 | 背景色 | 图标 |
|------|------|--------|--------|------|
| 1 | 樱花粉 | `#ffffff` | `#f7768e` | 🌸 |
| 2 | 天空蓝 | `#1a1b26` | `#7aa2f7` | 🔵 |
| 3 | 清新绿 | `#1a1b26` | `#9ece6a` | 🍀 |
| 4 | 薰衣草 | `#ffffff` | `#bb9af7` | 💜 |
| 5 | 深海靛 | `#ffffff` | `#3d59a1` | 🌌 |
| 6 | 琥珀金 | `#1a1b26` | `#e0af68` | ✨ |
| 7 | 玫瑰红 | `#ffffff` | `#db4b4b` | 🌹 |
| 8 | 薄荷青 | `#1a1b26` | `#73daca` | 🌊 |

前景色规则：浅色背景用深色字 `#1a1b26`，深色背景用白色字 `#ffffff`。

配色来源：Tokyo Night 主题色板。

## ANSI 调色映射

每次主题轮换时，除了背景色和 Starship 标签，还会同步修改终端 ANSI 调色板，让 Claude Code 的文字颜色也跟着主题走。

基准色来自 `_PROMPT_TEXT` 数组（通常与 `_PROMPT_BG` 相同），自动计算 3 个 ANSI 槽位：

| ANSI 槽位 | 用途 | 计算方式 |
|-----------|------|----------|
| ANSI 15 (whiteBright) | 主文字 | 基准色 + (255 - 基准色) × 30%，即提亮 30% |
| ANSI 7 (white) | 边框/次要文字 | 基准色 × 60%，即压暗到 60% |
| ANSI 9 (redBright) | Claude 指示点 | 基准色原色，不做变换 |

通过 OSC 4 转义序列设置：`\033]4;槽位号;rgb:RR/GG/BB\007`

**注意**：这些颜色会自动跟随 `_PROMPT_TEXT` 变化，添加/修改主题时无需额外配置。

## 技术架构（供参考）

```
~/.zshrc 底部配置
├── 主题定义：5 个并行数组（_PROMPT_FG / _PROMPT_BG / _PROMPT_TEXT / _PROMPT_ICON / _PROMPT_NAME）
├── 窗口计数器：/tmp/.zsh_prompt_counter（每个新窗口 +1，取模轮换）
├── 背景色混合：25% 主题色 + 75% 纯黑（通过 OSC 11 转义序列设置）
├── ANSI 调色：基于 _PROMPT_TEXT 自动映射 ANSI 15/7/9（通过 OSC 4 转义序列设置）
├── Starship 提示符：precmd hook 注入带色标签到 PROMPT 变量
├── iTerm2 标题：OSC 1（Tab 标题）+ OSC 2（窗口标题）联动目录名
└── zsh 插件：语法高亮 + 自动建议
```

**定位代码的搜索关键词**：`_PROMPT_FG=`（数组定义区）、`_PROMPT_TEXT=`（ANSI 调色基准）、`_R * 25`（混合比例）、`OSC 4`（ANSI 槽位设置）、`starship_precmd`（提示符注入）、`_update_iterm_title`（标题联动）

## 安全检查（每次编辑 .zshrc 前必须执行）

在读取或编辑用户的 `~/.zshrc` 前，必须扫描是否存在明文密钥/凭证：

```bash
grep -niE '(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL|API_KEY)=' ~/.zshrc | grep -v '^#'
```

如果发现明文密钥：
1. **立即警告用户**：告知哪一行存在风险
2. **建议迁移**：将密钥移到独立文件（如 `~/.env.secrets`），zshrc 中改为 `source ~/.env.secrets`
3. **设置权限**：`chmod 600 ~/.env.secrets`
4. **不要在对话中展示密钥内容**：只报告"第 X 行存在 XXX_KEY"，不输出值

**Why**：用户可能将 .zshrc 分享到 GitHub 或截图发社交媒体，明文密钥泄露后果严重。

## 依赖项

| 依赖 | 用途 | 路径检测方式 |
|------|------|-------------|
| Starship | 提示符引擎 | `which starship` 或 `~/bin/starship` 或 `/opt/homebrew/bin/starship` |
| 支持 OSC 的终端 | 背景色切换 | iTerm2/Kitty/Ghostty/WezTerm/Alacritty/VS Code/Qoder 等 |
| zsh-syntax-highlighting | 命令语法高亮（可选） | 自动搜索 `~/.zsh-plugins/`、`~/zsh-plugins/`、oh-my-zsh、homebrew |
| zsh-autosuggestions | 历史命令建议（可选） | 同上 |

## 一键安装/卸载

项目提供了安装和卸载脚本，位于 GitHub 仓库：

```bash
bash install.sh   # 自动检测环境、安装依赖、注入配置
bash uninstall.sh  # 清理配置、还原 zshrc
```

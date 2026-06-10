# Emacs 配置文件

## 项目定位

本项目从原先的多语言编程 IDE 配置（2015-2024），转型为以**文本编辑与笔记管理**为核心的 Emacs 配置文件。

> **当前分支**：`emacs30-upgrade` — 目标 Emacs 30+，已完成编程功能裁剪、现代化补全替换和笔记系统集成。

## 变更历史

### v2.0 — Emacs 30 升级（emacs30-upgrade 分支）

- **移除**：C/C++、PHP、Python、Java、Common Lisp 等编程语言专属配置
- **移除**：GNU GLOBAL（GTAGS）、CEDET、ECB、Eclim、Flycheck、Company 等开发工具
- **新增**：Vertico + Consult + Marginalia + Orderless + Embark 现代补全方案（替代 Helm）
- **新增**：Denote + Org-roam + Org-crypt 笔记管理系统
- **新增**：inline-crypt 内联文本加密（段落内部分文本加密）
- **迁移**：全部 `defadvice` 替换为 `advice-add`
- **精简**：配置文件从 ~2000 行缩减为 ~1200 行

### v1.x — 多语言 IDE（master 分支，存档）

- 基于 tuhdo 配置修改
- 支持 C/C++、PHP、Python、Java、Common Lisp
- Helm + GTAGS 代码导航
- Company 代码补全

---

## 当前特性

### 文本编辑增强

| 特性 | 包 | 说明 |
|------|----|------|
| 结构化编辑 | smartparens | 括号、引号自动配对和结构化操作 |
| 代码片段 | yasnippet | 文本扩展和模板 |
| 增量搜索 | isearch + anzu | 搜索计数和替换预览 |
| 多光标编辑 | iedit | 同时编辑多处相同文本 |
| 区域扩展 | expand-region | 按语义逐步扩大选区 |
| 智能缩进 | dtrt-indent + clean-aindent | 自动检测和修正缩进 |
| 注释 | comment-dwim-2 | 智能注释/取消注释 |
| 历史粘贴 | consult-yank | 浏览 kill-ring 历史 |
| 重复行 | duplicate-thing | 快速复制当前行或选区 |

### 笔记管理

| 特性 | 包 | 说明 |
|------|----|------|
| 笔记管理 | Denote | 基于文件命名规范的笔记系统 |
| 双向链接 | Org-roam | 类 Roam Research 的知识图谱 |
| 条目加密 | Org-crypt | GPG 加密整条 org heading |
| 内联加密 | inline-crypt | GPG 加密段落内任意文本片段 |
| 现代化显示 | Org-modern | 美化 org-mode 的视觉呈现 |
| 快速捕获 | Org-capture | 快速记录想法和待办事项 |
| Markdown 编辑 | markdown-mode | 完整的 Markdown 编辑支持 |

### 现代补全（替代 Helm）

| 包 | 用途 |
|---|------|
| Vertico | 垂直补全 UI |
| Consult | 增强命令（buffer、文件、搜索、register） |
| Marginalia | 补全候选的注解信息 |
| Orderless | 灵活的多关键词模糊匹配 |
| Embark | 上下文操作菜单和批量操作 |

### 文件与窗口管理

| 特性 | 包 |
|------|-----|
| 文件管理 | Dired + Dired-X + Wdired + Recentf |
| 目录对比 | ztree-diff |
| 大文件查看 | vlf |
| 窗口布局 | winner-mode + windmove + golden-ratio |
| 终端 | Eshell + shell-pop |
| 版本控制 UI | diff-hl |

### UI/UX

- 主题：grandshell（dark）
- 光标处符号高亮（highlight-symbol）
- 自动编码识别（unicad）
- UTF-8 默认编码
- macOS 兼容（自动读取 shell PATH）

---

## 快速开始

### 安装

```bash
cd ~
git clone https://github.com/quanyufang/emacs-config-files .emacs.d
cd .emacs.d
git checkout emacs30-upgrade
```

### 前置依赖

```bash
# macOS（推荐）
brew install gnupg          # 内联加密 + org 笔记加密
brew install ripgrep        # consult-ripgrep 全文搜索

# 创建笔记目录
mkdir -p ~/notes
```

### 生成 GPG 密钥（加密笔记用）

```bash
gpg --full-generate-key     # 按提示操作
gpg --list-keys             # 确认密钥存在
```

> 配置完成后，选中敏感文本按 `C-c e` 即可加密，按 `C-c d` 解密查看。
> 详见 [GPG-Guide.md](GPG-Guide.md) 了解 GPG 密钥备份、恢复和日常使用。
> 新手请先看 [GPG-Tutorial.md](GPG-Tutorial.md) 逐步操作。

### 首次启动

启动 Emacs 后等待包自动安装（约 3-5 分钟）。安装完成后即可正常使用。

---

## 常用快捷键

### 加密

| 按键 | 功能 | 说明 |
|------|------|------|
| `C-c n c` | org-crypt：解密条目查看 | 编辑后保存自动加密 |
| `C-c e` | inline-crypt：加密选区 | 选中文本 → 替换为 GPG 加密块 |
| `C-c d` | inline-crypt：解密当前块 | 光标在加密块上 → 就地解密编辑 |
| — | 保存时自动重加密 | 被 `C-c d` 解开的块，保存时自动恢复加密 |

> **区别**：`org-crypt` 处理整条 org heading，`inline-crypt` 处理段落内的任意文本片段。两者可同时使用。

### 核心操作

| 按键 | 功能 |
|------|------|
| `M-x` | 执行命令（Vertico 垂直补全） |
| `C-x b` | 切换 buffer（consult-buffer） |
| `C-x C-f` | 打开文件 |
| `M-y` | 浏览 kill-ring 历史（consult-yank） |
| `C-c s` | 搜索当前 buffer（consult-line） |
| `C-c S` | 全文递归搜索（consult-ripgrep） |
| `C-x r j` | 跳转到 register（consult-register） |
| `C-.` | 上下文操作菜单（embark-act） |
| `C-h C-f` | 搜索命令和函数（consult-apropos） |

### 编辑操作

| 按键 | 功能 |
|------|------|
| `C-a` | 智能行首（缩进位置/行首切换） |
| `C-o` | 智能开行（下方插入空行并缩进） |
| `M-o` | 上方开行 |
| `C-c i` | 格式化整个 buffer 或选区 |
| `M-;` | 注释/取消注释 |
| `M-c` | 重复当前行/选区 |
| `M-m` | 按语义扩展选区 |
| `C-;` | iedit 多光标编辑 |
| `C-c w` | 显示/隐藏空白字符 |

### 笔记管理（C-c n 前缀）

| 按键 | 功能 |
|------|------|
| `C-c n d` | 新建笔记（Denote） |
| `C-c n f` | 查找或创建笔记 |
| `C-c n r` | 重命名笔记文件 |
| `C-c n k` | 添加关键词 |
| `C-c n l` | 创建链接 |
| `C-c n o` | 查找 Org-roam 节点 |
| `C-c n i` | 插入双向链接 |
| `C-c n t` | 添加标签 |
| `C-c n g` | 显示知识图谱 |
| `C-c n c` | 解密当前条目 |
| `C-c c` | 快速捕获 |

### 窗口管理

| 按键 | 功能 |
|------|------|
| `C-x 1` | 智能关闭其他窗口（可恢复） |
| `C-x 5 2` | 新建 Frame |
| `C-x w f` | 全屏切换 |
| `S-<left>` / `S-<right>` 等 | 在窗口间移动光标（windmove） |
| `C-c t` | 弹出/隐藏终端（shell-pop） |

---

## 目录结构

```
~/.emacs.d/
├── init.el                           # 主配置文件
├── custom/                           # 模块化配置
│   ├── custom-built-in-functions.el  # 通用编辑增强
│   ├── mylib.el                      # 工具函数
│   ├── setup-editing.el              # 编辑核心配置
│   ├── setup-vertico.el              # Vertico+Consult 补全
│   ├── setup-denote.el               # 笔记系统
│   ├── setup-inline-crypt.el          # 内联文本加密
│   ├── setup-files.el                # 文件管理
│   ├── setup-faces-and-ui.el         # 主题/UI
│   ├── setup-convenience.el          # 便捷功能
│   ├── setup-environment.el          # 环境设置
│   ├── setup-help.el                 # 帮助系统
│   ├── setup-external.el             # 终端/Shell
│   ├── setup-applications.el         # Eshell
│   ├── setup-communication.el        # 通信
│   ├── setup-data.el                 # 数据保存
│   ├── setup-text.el                 # 文本模式
│   └── setup-local.el                # 本地配置（不提交）
├── EmacsCommand.md                   # 详细命令文档
└── EmacsEssential.md                 # Emacs 基础知识
```

---

## 注意事项

- **Emacs 版本**：需要 Emacs 29+（推荐 30+）
- **首次启动**：需等待包下载安装
- **macOS**：自动从 shell 读取 PATH
- **备份文件**：自动保存在 `~/.backups/`
- **加密笔记**：需要安装 GPG 并生成密钥

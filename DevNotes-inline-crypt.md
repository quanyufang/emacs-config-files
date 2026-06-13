# 笔记方案与加密 — 开发笔记

> 记录 Emacs 笔记系统（Denote + Org-roam + 加密）的设计、组件说明，以及 inline-crypt 开发过程中的问题与修复。  
> 笔记配置：`custom/setup-denote.el`  
> 内联加密：`custom/setup-inline-crypt.el`  
> 最后更新：2026-06-12

---

## 0. 笔记方案总览

### 0.1 设计思路

本配置以 **纯文本、本地优先、可版本管理** 为原则，把笔记能力拆成三层：

| 层次 | 组件 | 解决的问题 |
|------|------|------------|
| **文件组织** | Denote | 笔记放哪、怎么命名、怎么按关键词浏览 |
| **知识关联** | Org-roam | 笔记之间如何链接、如何看反向引用和图谱 |
| **内容结构** | Org-mode | heading、列表、待办、捕获（capture） |
| **敏感内容** | org-crypt + inline-crypt | 整条 entry 或段落内片段的 GPG 加密 |
| **编辑体验** | Org-modern、Vertico 栈 | 视觉与补全 |

所有笔记默认存放在 **`~/notes/`**，与 `init.el` 中 `ensure-directory "~/notes/"` 一致。Denote 与 Org-roam **共用同一目录**，文件名规范由 Denote 主导，链接与索引由 Org-roam 维护。

### 0.2 典型工作流

```
新建笔记          C-c n d / C-c n f     → Denote 命名规范创建 .org
写内容 + 链接     C-c n i / C-c n l     → Org-roam / Denote 插入链接
查找已有笔记      C-c n o               → Org-roam 节点搜索
看反向引用        C-c n b               → Denote backlink
看知识图谱        C-c n g               → Org-roam graph
快速捕获          C-c c                 → org-capture → inbox/journal
重命名/改关键词   C-c n r / C-c n k     → Denote 重命名（同步文件名）
加密整条 entry    heading 加 :crypt:     → 保存自动加密；C-c n c 解密编辑
加密段落片段      C-c e / C-c d         → inline-crypt
```

### 0.3 Denote 与 Org-roam 如何配合

两者**不互斥**，分工如下：

- **Denote** 管「文件是什么」：文件名含日期、关键词、标题；重命名文件时 buffer 名跟随更新（`denote-rename-buffer-mode`）。
- **Org-roam** 管「文件之间什么关系」：解析 `[[id:...]]` / `[[file:...]]` 链接，维护 SQLite 数据库，提供节点查找、backlink、图谱。
- 一篇 Denote 笔记（如 `20250612T143000--emacs_project_my-note.org`）同时是一个 Org-roam **节点**（通常以 `#+title:` 或文件名作为节点标题）。
- Org-roam 的 capture 模板会创建**非 Denote 命名**的文件（时间戳-slug.org）；日常笔记推荐优先用 **`C-c n d`** 保持命名一致；Roam capture 适合快速/结构化模板（如 bibliography）。

### 0.4 目录与特殊文件

| 路径 | 说明 |
|------|------|
| `~/notes/` | 笔记根目录 |
| `~/notes/inbox.org` | org-capture「Inbox」模板目标 |
| `~/notes/journal.org` | org-capture「Journal」按日期树 |
| `~/notes/org-roam.db` | Org-roam 索引库（排除在 roam 扫描之外） |

Org-roam 排除目录：`data/`、`archive/`、`.git/`、`.sync/`、`org-roam.db`（见 `org-roam-file-exclude-regexp`）。

---

## 1. Denote 功能说明

Denote（Protesilaos Stavrou）是 **基于文件名编码元数据** 的笔记系统，不依赖专有数据库；任何文件管理器、grep、git 都能直接读懂文件名。

### 1.1 文件命名规范

默认格式（ISO 8601 日期）：

```
TIMESTAMP--KEYWORDS_TITLE.ext
```

示例：

```
20250612T143000--emacs_project_inline-crypt-design.org
│                │     │       │
│                │     │       └── 标题（连字符分隔）
│                │     └── 关键词（下划线连接多个）
│                └── 双连字符分隔符
└── 创建时间戳
```

本配置：`denote-file-type` 为 `nil`，**同时支持 `.org` 与 `.md`**。

### 1.2 本配置的 Denote 选项

| 变量 | 值 | 含义 |
|------|-----|------|
| `denote-directory` | `~/notes/` | 笔记目录 |
| `denote-known-keywords` | emacs, notes, writing, reading, project, idea | 补全提示的预设关键词 |
| `denote-infer-keywords` | t | 从已有文件名推断关键词供补全 |
| `denote-sort-keywords` | t | 关键词字母序排列 |
| `denote-prompts` | title, keywords | 新建时只问标题和关键词 |
| `denote-rename-confirmations` | nil | 重命名时不二次确认 |
| `denote-rename-buffer-mode` | 1 | 文件重命名后 buffer 名自动更新 |

### 1.3 Denote 命令（`C-c n` 前缀）

| 按键 | 命令 | 功能 |
|------|------|------|
| `C-c n d` | `denote-create-note` | 新建笔记：提示 title + keywords，生成规范文件名 |
| `C-c n f` | `denote-open-or-create` | 按标题/关键词查找已有笔记，找不到则创建 |
| `C-c n l` | `denote-link-or-create` | 插入指向某笔记的链接；目标不存在则创建 |
| `C-c n r` | `denote-rename-file` | 重命名当前文件（改 title/keywords/日期等） |
| `C-c n k` | `denote-keywords-add` | 给当前笔记增加关键词（会触发重命名） |
| `C-c n b` | `denote-find-backlink` | 查找链接到当前笔记的其它文件 |
| `C-c n m` | `denote-region` | 对选区做 Denote 相关操作（如转为链接等，依上下文） |

### 1.4 Denote 适用场景

- 需要 **稳定、可读的文件名**，方便 `git diff`、备份、Spotlight 搜索。
- 用 **关键词** 做轻量分类（非强制 tag 体系）。
- 重命名即改元数据，无需单独维护 front matter 数据库。

### 1.5 Denote 局限（选型时需知）

- 链接格式以 **文件路径 / Denote 链接** 为主；与 Org-roam 的 `id:` 链接是两套机制，混用时靠 Org-roam 索引统一检索。
- 文件名变更是 **重命名文件**；外部硬链接或手动改文件名需自己保持一致。

---

## 2. Org-roam 功能说明

Org-roam（Noboru Hayama 等，v2）在 Org-mode 上提供 **Roam/Obsidian 风格** 的网络化笔记：每个 org 文件是一个节点，链接可双向追溯。

### 2.1 核心概念

| 概念 | 说明 |
|------|------|
| **Node（节点）** | 通常一个 `.org` 文件对应一个 roam 节点，由 `#+title:` 或文件属性标识 |
| **Link** | `[[id:UUID][显示文字]]` 或文件链接；Org-roam 解析后写入数据库 |
| **Backlink** | 哪些节点链接到了当前节点 |
| **Database** | `org-roam.db`（SQLite），缓存标题、链接、标签，加速查询 |
| **Graph** | 节点与边的可视化 |

### 2.2 本配置的 Org-roam 选项

| 变量 | 值 | 含义 |
|------|-----|------|
| `org-roam-directory` | `~/notes/` | 与 Denote 同目录 |
| `org-roam-db-location` | `~/notes/org-roam.db` | 索引库路径 |
| `org-roam-db-gc-threshold` | 极大值 | 实质禁用自动 GC，减少意外重建 |
| `org-roam-db-autosync-mode` | 1 | 文件变更后自动同步数据库 |
| `org-roam-node-display-template` | title + tags | 节点列表显示标题与 tag |
| `org-roam-file-exclude-regexp` | 见上 | 排除非笔记目录和 db 文件 |

**Capture 模板**（`org-roam-capture` 类命令使用）：

- `d` default：通用笔记，`#+title` + `#+date` + `#+filetags`
- `b` bibliography：带 `:reading:` tag，预置 Source / Summary / Key points 结构

### 2.3 Org-roam 命令（`C-c n` 前缀）

| 按键 | 命令 | 功能 |
|------|------|------|
| `C-c n o` | `org-roam-node-find` | 模糊搜索节点并跳转（最常用入口之一） |
| `C-c n i` | `org-roam-node-insert` | 插入指向某节点的链接（可创建新节点） |
| `C-c n t` | `org-roam-tag-add` | 给当前节点加 tag（`#+filetags:`） |
| `C-c n a` | `org-roam-alias-add` | 给节点加别名（多名称指向同一节点） |
| `C-c n g` | `org-roam-graph` | 打开当前节点/全局知识图谱 |
| `C-c n s` | `org-roam-db-sync` | 手动全量同步数据库（autosync 一般够用） |

### 2.4 Org-roam 适用场景

- 写笔记时频繁 **「链到已有概念」**，需要 backlink 发现关联。
- 从 **图谱** 探索主题簇。
- 用 **tag / alias** 做柔性分类，与 Denote 文件名关键词互补。

### 2.5 Org-roam 局限（选型时需知）

- 依赖 **SQLite 索引**；极端情况下需 `C-c n s` 重建。
- 与 Denote 混用时：Denote 重命名文件后，Org-roam autosync 会更新路径，但文内旧路径链接可能需要手动修。
- 加密 entry 内的链接文本在解密前不可读；索引通常仍基于文件名与 `#+title:`。

---

## 3. 其它笔记相关组件（简述）

### 3.1 Org-mode 增强

- `org-startup-indented`、`org-pretty-entities`：缩进与符号美化。
- `org-capture`（`C-c c`）：Inbox / Journal / Quick note 快速写入。
- `org-display-inline-images`：内联图片。

### 3.2 Org-modern

美化标题星号、列表等 UI；不改变文件语义。

### 3.3 加密（org-crypt + inline-crypt）

见本文 **§5 技术组件** 与 **§6 两套加密对比**；开发问题见 **§4**。

---

## 4. 开发过程中遇到的问题（inline-crypt）

### 4.1 括号不平衡 / 函数未定义

| 现象 | `load-file` 失败、`void-function`、`listp` 报错、prepare 逻辑嵌套错乱 |
|------|------------------------------------------------------------------------|
| 根因 | 多次增量修改 `setup-inline-crypt.el` 时括号不匹配，部分 `defun` 体被嵌进其它函数 |
| 修复 | 逐段核对 paren depth；补全 `inline-crypt--opening-delimiter-at-point` 等待定义函数 |
| 教训 | 每次大改后用脚本检查 `( ` / `)` 平衡；优先小步提交 |

### 4.2 `prepare` 扫描 PGP 块时死循环

| 现象 | 保存或 idle collapse 时 Emacs 卡死 |
|------|-----------------------------------|
| 根因 | `while (re-search-forward "-----BEGIN PGP MESSAGE-----")` 找到同一块后未前进 |
| 修复 | 每轮处理后 `goto-char (max bend (1+ hit))`；非 inline 的 org-crypt armor 用 `skip-non-inline-pgp-armor` 跳过 |

### 4.3 `C-c d` 找不到 inline 块

| 现象 | 光标在加密区域，`C-c d` 报 *No encrypted block at point* |
|------|-----------------------------------------------------------|
| 根因 | org 模式下要求 `#+BEGIN_gpg` … `#+END_gpg` 包裹；delimiter 在标题行内（如 `* sec #+BEGIN_gpg`）时旧逻辑只查「整行开头」 |
| 修复 | 新增 `inline-crypt--find-delimiter-block-bounds`；`opening-delimiter-at-point` 支持当前行与上一行；支持无 armor 的二进制密文解密路径（历史脏数据） |

### 4.4 `C-c e` 无选区时报错

| 现象 | 未选中 region 时 `C-c e` 直接 `user-error` |
|------|---------------------------------------------|
| 根因 | 仅支持 active region |
| 修复 | `inline-crypt--bounds-for-encrypt`：无选区时加密 org 段落或当前行 |

### 4.5 org-crypt 条目不加密（`:crpyt:` 拼写）

| 现象 | 第二个 heading 保存后仍明文 |
|------|----------------------------|
| 根因 | 标签写错；`org-crypt-tag-matcher` 为 `"crypt"`，匹配 `:crypt:` 而非 `:crpyt:` |
| 修复 | 用户修正 org 标签；非代码 bug |

### 4.6 保存时弹出 coding system 选择（UTF-8 无法编码）

| 现象 | `C-c e` 后 `C-x C-s`，Warning 里出现 `\204`、`\333` 等字节，提示选 `raw-text` |
|------|--------------------------------------------------------------------------------|
| 根因 | **`inline-crypt-encrypt-region`（C-c e）直接调 `epg-encrypt-string`，未 `(epg-context-set-armor context t)`**，插入的是二进制 OpenPGP，不是 ASCII armor |
| 修复 | `C-c e` 统一走 `inline-crypt--encrypt-plaintext`；加密后校验含 `-----BEGIN PGP MESSAGE-----` |
| 注意 | **不要选 `raw-text` 保存**，会进一步损坏 `.org`；应 `C-g` 取消后 revert 脏块 |

### 4.7 保存时报 `Text is read-only`

| 现象 | 加密后 `C-x C-s` → `save-buffer: Text is read-only` |
|------|-----------------------------------------------------|
| 根因 | 折叠块带 `read-only`；`before-save-hook`（inline 重加密 / org-crypt 加密）需改 buffer；旧版 `prepare` 先 expand 再 `protect-armor-region` 又重新设 read-only |
| 修复 | 保存前 `inline-crypt--unprotect-all-inline-blocks-for-save` 只解除保护、不展开；整个 `reencrypt-before-save` 包在 `inhibit-read-only` 内；hook 顺序：inline **-100** → org-crypt **100** |

### 4.8 加密后无法在块后继续输入

| 现象 | `C-c e` 后按字符或回车，报 read-only 或无法插入 |
|------|------------------------------------------------|
| 根因 | 界面只显示 🔐，但 buffer 内密文仍占很长区间；光标常落在 `[beg,end)` 内；`protect` overlay 的 `insert-behind-hooks` 在块**后**也拦截插入 |
| 修复 | 折叠块加 `cursor-intangible`、`rear-nonsticky`、`front-nonsticky`；加密后 `goto-char` 到块尾；`pre-command-hook` 在输入前跳出折叠区；移除 `insert-behind-hooks`；`deny-insert` 仅在 overlay 内部报错 |

### 4.9 macOS GPG 口令提示

| 现象 | `Inappropriate ioctl for device` |
|------|----------------------------------|
| 根因 | pinentry 与终端/Emacs 交互问题 |
| 修复 | `(setq epa-pinentry-mode 'loopback)`（`setup-denote.el`） |

---

## 5. 加密与技术组件

### 5.1 架构总览

```
┌─────────────────────────────────────────────────────────────┐
│                     Emacs 30+ (init.el)                      │
├─────────────────────────────────────────────────────────────┤
│  笔记层                                                      │
│    Denote          — 文件命名、关键词、重命名                  │
│    Org-roam        — 双向链接、图谱、org-roam.db              │
│    Org-mode        — 结构化文档、capture、indent              │
│    Org-modern      — 视觉美化                                │
├─────────────────────────────────────────────────────────────┤
│  加密层（两套互补）                                           │
│    org-crypt        — 整条 heading（:crypt: 标签）            │
│    inline-crypt     — 段落内任意片段（#+BEGIN_gpg 块）         │
├─────────────────────────────────────────────────────────────┤
│  密码学栈                                                    │
│    GnuPG (gpg)     — 实际加解密                                │
│    EPA / EPG       — Emacs 调用 GPG（epg-encrypt-string 等）   │
│    ASCII armor     — 磁盘上可 UTF-8 保存的 PGP 文本格式       │
├─────────────────────────────────────────────────────────────┤
│  UI / 编辑层（inline-crypt 实现）                             │
│    text properties — read-only, cursor-intangible, face       │
│    overlays          — display 🔐、protect、evaporate          │
│    minor mode        — inline-crypt-mode（org/md/text 自动开）  │
├─────────────────────────────────────────────────────────────┤
│  补全 / 导航                                                 │
│    Vertico + Consult + Marginalia + Orderless + Embark        │
└─────────────────────────────────────────────────────────────┘
         数据目录：~/notes/     本地密钥：~/.gnupg/
         密钥配置：custom/setup-local.el（gitignore）
```

### 5.2 各组件职责

| 组件 | 类型 | 作用 | 配置入口 |
|------|------|------|----------|
| **Denote** | ELPA 包 | `DATE--KEYWORDS_TITLE.org` 命名；`C-c n d/f/r/...` | `setup-denote.el` |
| **Org-roam** | ELPA 包 | 节点、backlink、graph；DB 在 `~/notes/org-roam.db` | `setup-denote.el` |
| **Org-crypt** | Emacs 内置 | 匹配 `:crypt:` 的 heading，保存时加密整条 entry body | `setup-denote.el` |
| **inline-crypt** | 自研模块 | 选区/段落级 GPG；`#+BEGIN_gpg` 包裹；🔐 折叠显示 | `setup-inline-crypt.el` |
| **EPA/EPG** | Emacs 内置 | 密钥枚举、`epg-context-set-armor`、加解密 API | 两模块共用 |
| **GnuPG** | 系统依赖 | 密钥环、算法实现 | `brew install gnupg` |
| **Org-modern** | ELPA 包 | 标题、列表等现代样式 | `setup-denote.el` |

## 6. 两套加密对比（org-crypt vs inline-crypt）

| 维度 | org-crypt | inline-crypt |
|------|-----------|--------------|
| 粒度 | 整个 org heading（含 body） | heading 内任意文本片段 |
| 标记 | heading 标签 `:crypt:` | `#+BEGIN_gpg` … `#+END_gpg` |
| 解密 | `C-c n c`（`org-decrypt-entry`） | `C-c d`（`inline-crypt-decrypt-at-point`） |
| 加密触发 | 保存时 `org-encrypt-entries` | 手动 `C-c e`；解密编辑后保存自动重加密 |
| 磁盘格式 | PGP armor（org-crypt 标准输出） | PGP armor + org 块 delimiter |
| 显示 | org-fold 折叠整条 entry | overlay `display` 为 🔐 |
| 可组合 | 可在已解密的 `:crypt:` entry 内再用 inline 加密子片段 | 同左 |

### 6.1 inline-crypt 内部机制

**加密流程（C-c e）**

1. `inline-crypt--bounds-for-encrypt` 确定 region / org 段落 / 当前行  
2. `inline-crypt--encrypt-plaintext` → EPG + **armor** → ASCII 密文  
3. 插入 `#+BEGIN_gpg` + 密文 + `#+END_gpg`  
4. `inline-crypt--collapse-block`：overlay 显示 🔐，底层保留完整 armor（可保存）  
5. 光标移到块尾  

**解密编辑（C-c d）**

1. 若在 🔐 上，先 expand（可选）  
2. 提取 armor / 二进制 payload → `epg-decrypt-string`  
3. 替换为明文，注册 `inline-crypt--decrypted-blocks`（含 original-armor）  
4. 明文可编辑；`C-c r` 可恢复未改动的 original-armor  

**保存 hook 顺序**

```
before-save-hook (-100)  inline-crypt--reencrypt-before-save
  ├─ unprotect 所有 inline 块（去 read-only）
  ├─ 对已解密块：未改 → restore original-armor；已改 → 重新 encrypt
  └─ inhibit-read-only 包裹

before-save-hook (100)   org-encrypt-entries（仅 org-mode + 有效 GPG key）
  └─ 处理带 :crypt: 的 heading

after-save-hook          org-crypt--protect-encrypted-blocks
  └─ org 级 PGP 块设 read-only（跳过 inline 块内的 armor）
```

**org 与 inline 的识别规则**

- inline：`#+BEGIN_gpg` … `#+END_gpg` 包裹（`inline-crypt--mode-requires-delimiter-p`）  
- org-crypt：heading 带 `:crypt:`，PGP 块**无** inline delimiter 包裹  
- `prepare` / collapse 扫描 PGP begin 时，用 `find-block-bounds` 区分，避免把 org-crypt 条目当 inline 处理  

### 6.2 关键自定义变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `inline-crypt-gpg-key` | nil | nil = 默认密钥 |
| `inline-crypt-org-delimiter-begin/end` | `#+BEGIN_gpg` / `#+END_gpg` | org inline 边界 |
| `inline-crypt-collapse-encrypted` | t | 是否折叠为 🔐 |
| `inline-crypt-collapsed-indicator` | ` 🔐 ` | 折叠显示字符 |
| `org-crypt-key` | `setup-local.el` | 40 位指纹 |
| `org-crypt-tag-matcher` | `"crypt"` | 匹配 `:crypt:` |
| `epa-pinentry-mode` | `'loopback` | macOS 口令输入 |

### 6.3 文件与目录

| 路径 | 用途 |
|------|------|
| `~/notes/` | Denote + Org-roam 笔记根目录 |
| `~/notes/org-roam.db` | Roam 图谱数据库 |
| `custom/setup-inline-crypt.el` | inline-crypt 全部逻辑 |
| `custom/setup-denote.el` | Denote、Org-roam、org-crypt |
| `custom/setup-local.el` | `my-org-crypt-key`（不提交） |
| `GPG-Guide.md` / `GPG-Tutorial.md` | 用户向 GPG 文档 |

---

## 7. 已知限制与后续可分析点

1. **嵌套场景**：在已解密的 `:crypt:` entry 内做 inline 加密，保存时 org-crypt 会加密整个 body（含 inline 密文），逻辑上可行但语义需用户自己规划。  
2. **历史脏数据**：曾用无 armor 的 `C-c e` 或误选 `raw-text` 保存的块，需手动 revert 或删除后重加密。  
3. **debug 插桩**：`.cursor/debug-c9fe51.log` 与 `inline-crypt--debug-log` 仍保留，稳定后可删。  
4. **测试脚本**：`.cursor/*-test.el`、`*-flow.el` 为开发期临时脚本，非正式测试套件。  
5. **性能**：大文件多次 `re-search-forward` PGP begin；笔记规模极大时可考虑优化或限制 scan 范围。

---

## 8. 快捷键速查

### 8.1 笔记（Denote / Org-roam / Capture）

| 按键 | 模块 | 功能 |
|------|------|------|
| `C-c n d` | Denote | 新建笔记 |
| `C-c n f` | Denote | 查找或创建 |
| `C-c n l` | Denote | 链接或创建 |
| `C-c n r` | Denote | 重命名文件 |
| `C-c n k` | Denote | 添加关键词 |
| `C-c n b` | Denote | 反向链接 |
| `C-c n o` | Org-roam | 查找节点 |
| `C-c n i` | Org-roam | 插入节点链接 |
| `C-c n t` | Org-roam | 添加 tag |
| `C-c n a` | Org-roam | 添加 alias |
| `C-c n g` | Org-roam | 知识图谱 |
| `C-c n s` | Org-roam | 同步数据库 |
| `C-c c` | org-capture | 快速捕获 |

### 8.2 加密

| 按键 | 模块 | 功能 |
|------|------|------|
| `C-c n c` | org-crypt | 解密当前 `:crypt:` 条目 |
| `C-c e` | inline-crypt | 加密选区 / 段落 |
| `C-c v` | inline-crypt | 🔐 ↔ 显示密文（不解密） |
| `C-c d` | inline-crypt | 解密 inline 块编辑 |
| `C-c r` | inline-crypt | 未改 plaintext 时重新加锁 |
| `C-x C-s` | 两者 | inline 重加密 + org-crypt 条目加密 |

---

## 9. 相关文档

- [README.md](README.md) — 项目概览与快捷键  
- [GPG-Guide.md](GPG-Guide.md) — GPG 密钥与备份  
- [GPG-Tutorial.md](GPG-Tutorial.md) — 新手逐步配置  

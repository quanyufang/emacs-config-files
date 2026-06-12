# inline-crypt 与笔记加密 — 开发笔记

> 记录 inline-crypt 与 org-crypt 联调过程中的问题、根因与修复。  
> 主实现：`custom/setup-inline-crypt.el`  
> 条目级加密：`custom/setup-denote.el`  
> 最后更新：2026-06-12

---

## 1. 开发过程中遇到的问题

### 1.1 括号不平衡 / 函数未定义

| 现象 | `load-file` 失败、`void-function`、`listp` 报错、prepare 逻辑嵌套错乱 |
|------|------------------------------------------------------------------------|
| 根因 | 多次增量修改 `setup-inline-crypt.el` 时括号不匹配，部分 `defun` 体被嵌进其它函数 |
| 修复 | 逐段核对 paren depth；补全 `inline-crypt--opening-delimiter-at-point` 等待定义函数 |
| 教训 | 每次大改后用脚本检查 `( ` / `)` 平衡；优先小步提交 |

### 1.2 `prepare` 扫描 PGP 块时死循环

| 现象 | 保存或 idle collapse 时 Emacs 卡死 |
|------|-----------------------------------|
| 根因 | `while (re-search-forward "-----BEGIN PGP MESSAGE-----")` 找到同一块后未前进 |
| 修复 | 每轮处理后 `goto-char (max bend (1+ hit))`；非 inline 的 org-crypt armor 用 `skip-non-inline-pgp-armor` 跳过 |

### 1.3 `C-c d` 找不到 inline 块

| 现象 | 光标在加密区域，`C-c d` 报 *No encrypted block at point* |
|------|-----------------------------------------------------------|
| 根因 | org 模式下要求 `#+BEGIN_gpg` … `#+END_gpg` 包裹；delimiter 在标题行内（如 `* sec #+BEGIN_gpg`）时旧逻辑只查「整行开头」 |
| 修复 | 新增 `inline-crypt--find-delimiter-block-bounds`；`opening-delimiter-at-point` 支持当前行与上一行；支持无 armor 的二进制密文解密路径（历史脏数据） |

### 1.4 `C-c e` 无选区时报错

| 现象 | 未选中 region 时 `C-c e` 直接 `user-error` |
|------|---------------------------------------------|
| 根因 | 仅支持 active region |
| 修复 | `inline-crypt--bounds-for-encrypt`：无选区时加密 org 段落或当前行 |

### 1.5 org-crypt 条目不加密（`:crpyt:` 拼写）

| 现象 | 第二个 heading 保存后仍明文 |
|------|----------------------------|
| 根因 | 标签写错；`org-crypt-tag-matcher` 为 `"crypt"`，匹配 `:crypt:` 而非 `:crpyt:` |
| 修复 | 用户修正 org 标签；非代码 bug |

### 1.6 保存时弹出 coding system 选择（UTF-8 无法编码）

| 现象 | `C-c e` 后 `C-x C-s`，Warning 里出现 `\204`、`\333` 等字节，提示选 `raw-text` |
|------|--------------------------------------------------------------------------------|
| 根因 | **`inline-crypt-encrypt-region`（C-c e）直接调 `epg-encrypt-string`，未 `(epg-context-set-armor context t)`**，插入的是二进制 OpenPGP，不是 ASCII armor |
| 修复 | `C-c e` 统一走 `inline-crypt--encrypt-plaintext`；加密后校验含 `-----BEGIN PGP MESSAGE-----` |
| 注意 | **不要选 `raw-text` 保存**，会进一步损坏 `.org`；应 `C-g` 取消后 revert 脏块 |

### 1.7 保存时报 `Text is read-only`

| 现象 | 加密后 `C-x C-s` → `save-buffer: Text is read-only` |
|------|-----------------------------------------------------|
| 根因 | 折叠块带 `read-only`；`before-save-hook`（inline 重加密 / org-crypt 加密）需改 buffer；旧版 `prepare` 先 expand 再 `protect-armor-region` 又重新设 read-only |
| 修复 | 保存前 `inline-crypt--unprotect-all-inline-blocks-for-save` 只解除保护、不展开；整个 `reencrypt-before-save` 包在 `inhibit-read-only` 内；hook 顺序：inline **-100** → org-crypt **100** |

### 1.8 加密后无法在块后继续输入

| 现象 | `C-c e` 后按字符或回车，报 read-only 或无法插入 |
|------|------------------------------------------------|
| 根因 | 界面只显示 🔐，但 buffer 内密文仍占很长区间；光标常落在 `[beg,end)` 内；`protect` overlay 的 `insert-behind-hooks` 在块**后**也拦截插入 |
| 修复 | 折叠块加 `cursor-intangible`、`rear-nonsticky`、`front-nonsticky`；加密后 `goto-char` 到块尾；`pre-command-hook` 在输入前跳出折叠区；移除 `insert-behind-hooks`；`deny-insert` 仅在 overlay 内部报错 |

### 1.9 macOS GPG 口令提示

| 现象 | `Inappropriate ioctl for device` |
|------|----------------------------------|
| 根因 | pinentry 与终端/Emacs 交互问题 |
| 修复 | `(setq epa-pinentry-mode 'loopback)`（`setup-denote.el`） |

---

## 2. 当前笔记方案 — 技术组件

### 2.1 架构总览

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

### 2.2 各组件职责

| 组件 | 类型 | 作用 | 配置入口 |
|------|------|------|----------|
| **Denote** | ELPA 包 | `DATE--KEYWORDS_TITLE.org` 命名；`C-c n d/f/r/...` | `setup-denote.el` |
| **Org-roam** | ELPA 包 | 节点、backlink、graph；DB 在 `~/notes/org-roam.db` | `setup-denote.el` |
| **Org-crypt** | Emacs 内置 | 匹配 `:crypt:` 的 heading，保存时加密整条 entry body | `setup-denote.el` |
| **inline-crypt** | 自研模块 | 选区/段落级 GPG；`#+BEGIN_gpg` 包裹；🔐 折叠显示 | `setup-inline-crypt.el` |
| **EPA/EPG** | Emacs 内置 | 密钥枚举、`epg-context-set-armor`、加解密 API | 两模块共用 |
| **GnuPG** | 系统依赖 | 密钥环、算法实现 | `brew install gnupg` |
| **Org-modern** | ELPA 包 | 标题、列表等现代样式 | `setup-denote.el` |

### 2.3 两套加密的区别（分析用）

| 维度 | org-crypt | inline-crypt |
|------|-----------|--------------|
| 粒度 | 整个 org heading（含 body） | heading 内任意文本片段 |
| 标记 | heading 标签 `:crypt:` | `#+BEGIN_gpg` … `#+END_gpg` |
| 解密 | `C-c n c`（`org-decrypt-entry`） | `C-c d`（`inline-crypt-decrypt-at-point`） |
| 加密触发 | 保存时 `org-encrypt-entries` | 手动 `C-c e`；解密编辑后保存自动重加密 |
| 磁盘格式 | PGP armor（org-crypt 标准输出） | PGP armor + org 块 delimiter |
| 显示 | org-fold 折叠整条 entry | overlay `display` 为 🔐 |
| 可组合 | 可在已解密的 `:crypt:` entry 内再用 inline 加密子片段 | 同左 |

### 2.4 inline-crypt 内部机制（便于二次分析）

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

### 2.5 关键自定义变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `inline-crypt-gpg-key` | nil | nil = 默认密钥 |
| `inline-crypt-org-delimiter-begin/end` | `#+BEGIN_gpg` / `#+END_gpg` | org inline 边界 |
| `inline-crypt-collapse-encrypted` | t | 是否折叠为 🔐 |
| `inline-crypt-collapsed-indicator` | ` 🔐 ` | 折叠显示字符 |
| `org-crypt-key` | `setup-local.el` | 40 位指纹 |
| `org-crypt-tag-matcher` | `"crypt"` | 匹配 `:crypt:` |
| `epa-pinentry-mode` | `'loopback` | macOS 口令输入 |

### 2.6 文件与目录

| 路径 | 用途 |
|------|------|
| `~/notes/` | Denote + Org-roam 笔记根目录 |
| `~/notes/org-roam.db` | Roam 图谱数据库 |
| `custom/setup-inline-crypt.el` | inline-crypt 全部逻辑 |
| `custom/setup-denote.el` | Denote、Org-roam、org-crypt |
| `custom/setup-local.el` | `my-org-crypt-key`（不提交） |
| `GPG-Guide.md` / `GPG-Tutorial.md` | 用户向 GPG 文档 |

---

## 3. 已知限制与后续可分析点

1. **嵌套场景**：在已解密的 `:crypt:` entry 内做 inline 加密，保存时 org-crypt 会加密整个 body（含 inline 密文），逻辑上可行但语义需用户自己规划。  
2. **历史脏数据**：曾用无 armor 的 `C-c e` 或误选 `raw-text` 保存的块，需手动 revert 或删除后重加密。  
3. **debug 插桩**：`.cursor/debug-c9fe51.log` 与 `inline-crypt--debug-log` 仍保留，稳定后可删。  
4. **测试脚本**：`.cursor/*-test.el`、`*-flow.el` 为开发期临时脚本，非正式测试套件。  
5. **性能**：大文件多次 `re-search-forward` PGP begin；笔记规模极大时可考虑优化或限制 scan 范围。

---

## 4. 快捷键速查（加密相关）

| 按键 | 模块 | 功能 |
|------|------|------|
| `C-c n c` | org-crypt | 解密当前 `:crypt:` 条目 |
| `C-c e` | inline-crypt | 加密选区 / 段落 |
| `C-c v` | inline-crypt | 🔐 ↔ 显示密文（不解密） |
| `C-c d` | inline-crypt | 解密 inline 块编辑 |
| `C-c r` | inline-crypt | 未改 plaintext 时重新加锁 |
| `C-x C-s` | 两者 | inline 重加密 + org-crypt 条目加密 |

---

## 5. 相关文档

- [README.md](README.md) — 项目概览与快捷键  
- [GPG-Guide.md](GPG-Guide.md) — GPG 密钥与备份  
- [GPG-Tutorial.md](GPG-Tutorial.md) — 新手逐步配置  

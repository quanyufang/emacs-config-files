# 笔记方案 — 开发笔记

> Denote + Org-roam + **org-crypt**（Emacs 内置）。  
> 配置：`custom/setup-denote.el`  
> 最后更新：2026-06-12

---

## 0. 笔记方案总览

| 层次 | 组件 | 作用 |
|------|------|------|
| 文件组织 | Denote | 命名、关键词、重命名 |
| 知识关联 | Org-roam | 双向链接、图谱 |
| 内容结构 | Org-mode | heading、capture |
| 敏感内容 | **org-crypt** | 整条 heading 的 GPG 加密（Emacs 内置） |
| 编辑体验 | Org-modern、Vertico 栈 | UI 与补全 |

笔记目录：**`~/notes/`**（Denote 与 Org-roam 共用）。

典型流程：``C-c n d`` 新建 → 写作 / ``C-c n i`` 链到其它笔记 → 敏感 heading 加 ``:crypt:`` → ``C-x C-s`` 自动加密 → ``C-c n c`` 解密编辑。

> **说明**：曾实验过的自研 inline-crypt（``C-c e`` 段落级加密）已停用，不再从 ``init.el`` 加载。

---

## 1. Denote

文件名格式：``TIMESTAMP--KEYWORDS_TITLE.org``。

| 按键 | 功能 |
|------|------|
| `C-c n d` | 新建 |
| `C-c n f` | 查找或创建 |
| `C-c n l` | 链接或创建 |
| `C-c n r` | 重命名 |
| `C-c n k` | 加关键词 |
| `C-c n b` | 反向链接 |

---

## 2. Org-roam

| 按键 | 功能 |
|------|------|
| `C-c n o` | 查找节点 |
| `C-c n i` | 插入链接 |
| `C-c n g` | 知识图谱 |
| `C-c n s` | 同步数据库 |

索引库：``~/notes/org-roam.db``。

---

## 3. org-crypt（Emacs / Org 内置）

**org-crypt** 是 GNU Emacs 自带的库（``lisp/org-crypt.el``），不是第三方包。底层用 **EPA/EPG**（Emacs 内置）调用系统 **GnuPG**（``brew install gnupg``）。

### 用法

```org
* 银行账号 :crypt:
卡号：6222 XXXX
```

- 标题行加 **``:crypt:``**（``org-crypt-tag-matcher`` 默认为 ``"crypt"``）
- **``C-x C-s``** 保存 → 标题**下方正文**变为 PGP 密文（标题本身不加密）
- **``C-c n c``** → 解密当前 entry 编辑；再保存自动重加密
- 打开文件时已加密 entry 会自动折叠

### 本机配置要点（``setup-denote.el``）

| 项 | 说明 |
|----|------|
| ``org-crypt-key`` | 来自 ``custom/setup-local.el``（``M-x emacs-setup-gpg`` 配置） |
| ``epa-pinentry-mode`` | ``'loopback``（macOS 口令在 Emacs 内输入） |
| ``org-tags-exclude-from-inheritance`` | ``("crypt")``（避免 tag 继承导致重复加密） |
| ``before-save-hook`` | 保存前 ``org-encrypt-entries`` |

### 常见问题

- **标签拼写**：必须是 ``:crypt:``，不是 ``:crpyt:``
- **加密范围**：从该 heading 到**下一个同级 heading** 之间的内容
- **密钥**：``org-crypt-key`` 须为有效 GPG 指纹，见 [GPG-Tutorial.md](GPG-Tutorial.md) §6.1

---

## 4. 相关文档

- [README.md](README.md)
- [GPG-Guide.md](GPG-Guide.md)
- [GPG-Tutorial.md](GPG-Tutorial.md)

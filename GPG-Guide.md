# GPG 使用详解

> 本文档讲解 GPG 在 Emacs 加密笔记场景下的完整用法，包含备份、恢复和日常操作。
>
> 如果你还没生成 GPG 密钥，先看 [GPG-Tutorial.md](GPG-Tutorial.md)。

---

## 1. 基本概念

| 概念 | 说明 | 类比 |
|------|------|------|
| **私钥 (secret key)** | 你独有的，用于解密和签名 | 你的私人印章 |
| **公钥 (public key)** | 可以公开，别人用它加密信息给你 | 你的公开地址 |
| **ECC / RSA** | 两种主流密钥算法。ECC（椭圆曲线）更快更安全，是 GPG 2.3+ 的默认选择 | 两种锁的品牌 |
| **Curve 25519** | 最广泛使用的椭圆曲线，事实标准 | 锁的型号 |
| **指纹 (fingerprint)** | 密钥的完整唯一标识（40 位十六进制） | 密钥的身份证号 |
| **密钥 ID (key ID)** | 指纹的最后 16 位简写 | 身份证号的后几位 |
| **子密钥 (sub key)** | 从主密钥派生，专门用于加密 | 保险箱的专用钥匙 |
| **撤销证书 (revocation certificate)** | 一段特殊签名的文本，导入后永久作废密钥 | 挂失声明 |

---

## 2. 撤销证书详解

### 2.1 为什么需要撤销证书？

密钥泄露了不能"撤回"——已经分发出去的公钥无法远程删除。你只能**公开声明**"这把密钥作废了，别再用了"。撤销证书就是这份声明。

### 2.2 它是什么？

撤销证书是 GPG 在生成密钥时**自动创建**的一个小文件，用你的主密钥签名，内容大意是：

> "密钥持有者声明：指纹为 XXXX... 的密钥自即日起作废。"

任何拿到这份证书的人，都可以验证签名确实来自你，然后确认密钥已作废。

### 2.3 存放在哪里？

```bash
ls ~/.gnupg/openpgp-revocs.d/
# → XXXX1234ABCD5678.rev
```

文件内容长这样（不可伪造，因为有你的主密钥签名）：

```
-----BEGIN PGP PUBLIC KEY BLOCK-----
Comment: This is a revocation certificate

iQG2BCABCgAgFiEE...  ← 一段签过名的二进制数据
-----END PGP PUBLIC KEY BLOCK-----
```

### 2.4 它的工作方式

```
┌─────────────────────────────────────────────────────┐
│ 生成密钥时  →  自动创建 .rev 文件并存到              │
│               ~/.gnupg/openpgp-revocs.d/             │
├─────────────────────────────────────────────────────┤
│ 密钥泄露后  →  gpg --import 导入 .rev 文件            │
│               →  密钥本地标记为 [revoked]             │
│               →  gpg --send-keys 通知密钥服务器       │
├─────────────────────────────────────────────────────┤
│ 别人看到    →  "公钥已作废，不能用来加密了"           │
└─────────────────────────────────────────────────────┘
```

### 2.5 为什么提前备份它？

因为撤销证书需要**主密钥**来生成。如果你私钥丢了（`~/.gnupg/` 被误删），没有私钥就再也生成不了撤销证书——密钥将永远"活着"但你再也不能控制它。

备份撤销证书不需要密码——它本身就是一段签名声明，无关机密。和私钥备份一起保存即可。

### 2.6 别人能用撤销证书恶化作废我的密钥吗？

不能——撤销证书需要**你的私钥签名**来生成。没有私钥的人无法伪造。

但反过来：**任何拿到撤销证书文件的人都可以导入它，让你的密钥作废。** 所以撤销证书虽然不包含秘密信息，也不应该公开发布。备份到安全位置就行。

## 3. 密钥 ID 与指纹

`YOUR_KEY_ID` 指的是你的 **GPG 密钥 ID**。运行：

```bash
gpg --list-keys --keyid-format LONG
```

你的输出：

```
pub   rsa3072/XXXX1234ABCD5678  2026-06-10 [SC]
      AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555
uid                 [ultimate] Your Name (用来加密笔记等信息) <your@email.com>
sub   rsa3072/YYYY8888ZZZZ9999  2026-06-10 [E]
```

> **你的密钥 ID**：`XXXX1234ABCD5678`
> **你的完整指纹**：`AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555`

这两个值都可以用来替代文档中的 `YOUR_KEY_ID`，指纹更精确。

---

## 4. 密钥的备份

### 3.1 导出私钥（这是唯一不能丢的数据）

```bash
# 导出为 ASCII 文本文件
gpg --export-secret-keys --armor XXXX1234ABCD5678 > ~/gpg-private-key.asc
```

⚠️ 这个 `.asc` 文件是你的**明文私钥**，任何人拿到就能解密你全部笔记。别晾在磁盘上——**立刻执行下一步**把它用密码再加密，然后删掉：

### 3.2 用密码二次加密备份文件

```bash
cd ~
gpg --symmetric --cipher-algo AES256 gpg-private-key.asc
# 输入一个好记但足够强的密码
# → 生成 gpg-private-key.asc.gpg
rm gpg-private-key.asc           # 删除未加密的中间文件
```

### 3.3 多处保存

```bash
# 存到 iCloud / Dropbox / 加密 U 盘
cp ~/gpg-private-key.asc.gpg /path/to/backup/location/

# 也可以打印成 QR 码（如果文件不大的话）
# brew install qrencode
# cat ~/gpg-private-key.asc.gpg | base64 | qrencode -o gpg-backup-qr.png
```

### 3.4 同时备份公钥

```bash
gpg --export --armor XXXX1234ABCD5678 > ~/gpg-public-key.asc
```

公钥可以随便放——它只能加密，不能解密。

### 3.5 记下恢复信息（打印或用纸笔）

```
密钥 ID:  XXXX1234ABCD5678
邮箱:     your@email.com
UID:      Your Name (用来加密笔记等信息)
备份密码: [你上面设的那个]
备份文件所在位置: [你存的位置]
```

---

## 5. 新机器上恢复密钥

```bash
# 1. 在新机器上安装 GPG
brew install gnupg

# 2. 把 gpg-private-key.asc.gpg 拷贝到新机器

# 3. 解密备份文件
gpg --decrypt gpg-private-key.asc.gpg > gpg-private-key.asc
# 输入备份密码

# 4. 导入私钥
gpg --import gpg-private-key.asc
# 输入密钥本身的密码（如果没有设过，就是生成时设的）

# 5. 验证
gpg --list-keys --keyid-format LONG

# 6. 删除中间文件
rm gpg-private-key.asc
```

---

## 6. 日常命令速查

### 查看

```bash
gpg --list-keys                       # 列出所有公钥
gpg --list-keys --keyid-format LONG   # 列出公钥 + 完整 ID
gpg --list-secret-keys                # 列出所有私钥
gpg --fingerprint                     # 显示所有密钥指纹
```

### 加密 / 解密

```bash
# 用你的公钥加密一个文件
gpg --encrypt --recipient XXXX1234ABCD5678 file.txt
# → 生成 file.txt.gpg

# 解密
gpg --decrypt file.txt.gpg > file.txt

# 对一段文本直接加密（不生成文件）
echo "secret text" | gpg --encrypt --armor --recipient XXXX1234ABCD5678
```

### 密钥管理

```bash
gpg --delete-key XXXX1234ABCD5678         # 删除公钥
gpg --delete-secret-key XXXX1234ABCD5678  # 删除私钥
gpg --edit-key XXXX1234ABCD5678           # 交互式管理（设过期时间、添加子钥等）
```

---

## 7. 在 Emacs 中使用

### 6.1 你的配置已就绪

```elisp
;; setup-denote.el — org-crypt 条目加密
(setq org-crypt-key nil)   ; nil = 使用 GPG 默认密钥

;; setup-inline-crypt.el — 内联文本片段加密
;; 同样使用默认密钥
```

因为 `org-crypt-key` 和 `inline-crypt-gpg-key` 都设为 `nil`，Emacs 会自动使用你的默认密钥（就是你生成的那个）。

### 6.2 如果需要指定密钥

```elisp
;; 如果想显式指定（在 setup-denote.el 中修改）：
(setq org-crypt-key "XXXX1234ABCD5678")      ; 用密钥 ID
;; 或
(setq org-crypt-key "AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555")  ; 用完整指纹（推荐）
```

### 6.3 操作步骤

| 场景 | 操作 |
|------|------|
| 加密整条笔记 | org heading 加 `:crypt:` 标签，Ctrl-S 保存即自动加密 |
| 解密整条笔记 | `C-c n c`，再次运行恢复加密 |
| 加密笔记内片段 | 选中文本 → `C-c e` → 密文自动折叠为 🔐 指示器 |
| 解密查看片段 | 光标在 🔐 上 → `C-c d`（解密后绿色背景显示原文） |
| 编辑后自动加密 | Ctrl-S 保存，所有解开的片段自动重新加密并折叠回 🔐 |

> **新特性**：加密后的 PGP 密文块会自动折叠为一个紧凑的 🔐 图标，大幅减少屏幕占用。光标移到 🔐 上按 `C-c d` 即可解密查看。如需恢复显示完整密文，在 `setup-inline-crypt.el` 中将 `inline-crypt-collapse-encrypted` 设为 `nil`。

---

## 8. 安全注意事项

| 做的 | 不要做的 |
|------|----------|
| 导出私钥并加密存档 | 把私钥明文存在云盘 |
| 密码管理器中记下备份密码 | 把密钥密码写在笔记里 |
| 定期验证备份文件可解密 | 只在本地保留唯一一份 |
| 换电脑前确保备份已导出 | 删除 GPG 密钥前不备份 |

### 密码分层建议

```
┌─────────────────────────────┐
│  你的 GPG 密钥密码           │  ← 离线记（纸笔 / 密码管理器）
│  (生成密钥时设的那个)         │
├─────────────────────────────┤
│  gpg-private-key.asc.gpg     │  ← 云存储，有密码保护
│  密码（你设的备份密码）        │  ← 记在密码管理器
├─────────────────────────────┤
│  macOS 登录密码               │  ← 日常使用
└─────────────────────────────┘
```

---

## 9. 密钥文件存放位置

GPG 数据全部在 `~/.gnupg/` 目录下：

```
~/.gnupg/
├── private-keys-v1.d/       ← 私钥目录（权限 700，只有你能读）
│   ├── xxxx...xxxx.key      ←   密钥文件（权限 600，有密码加密）
│   └── yyyy...yyyy.key
├── public-keys.d/           ← 公钥目录（明文，可安全分享）
├── openpgp-revocs.d/        ← 撤销证书（提前生成并安全保存）
├── S.gpg-agent              ← gpg-agent 的 Unix socket（密码缓存中继）
├── S.keyboxd                ← 密钥存储后端的 socket
└── trustdb.gpg              ← 信任数据库
```

**私钥安全的关键**：`.key` 文件虽然受文件权限保护且本身有密码加密，但一旦 `gpg-agent` 缓存了密码（默认缓存 10 分钟），任何以你身份运行的进程都可以通过 `S.gpg-agent` socket 请求解密操作而无需再输入密码。

## 10. 威胁模型

GPG 的保护边界是**同一用户**：

| 场景 | 私钥文件暴露 | 能否解密 |
|------|:--:|:--:|
| 不知道你的 macOS 密码 | 否 | 否 |
| 登录了你的账户但 gpg-agent 未缓存密码 | 能读到文件 | 不能——私钥有密码保护 |
| 登录了你的账户且 gpg-agent 正在缓存密码 | 同上 | **能**——通过 socket 直接调用解密 |
| 木马/病毒以你的身份运行代码 | 能 | 能，同时可键盘记录密码 |

**结论**：GPG 防的是加密文件泄露后在外部被破解，不防本机已被控制。如果攻击者能以你的 User ID 执行代码，它不需要破解 GPG——直接读明文笔记或等你输入密码即可。

## 11. 删除密钥 vs 作废密钥

| 场景 | 做法 | 命令 |
|------|------|------|
| 密钥从未使用过（未加密过任何数据） | 直接删除 | `gpg --delete-secret-key 密钥ID` 然后 `gpg --delete-key 密钥ID` |
| 已经加密过笔记或文件 | 先作废再保留（解密旧数据） | 走下方作废流程 |
| 公钥已经给过别人 | 作废并通知密钥服务器 | 走下方作废流程 |

> **判断标准**：有没有数据是用这个密钥加密的？没有 → 直接删。有 → 撤销。

## 12. 作废密钥

### 场景一：提前准备了撤销证书（推荐）

生成密钥时 GPG 会在 `~/.gnupg/openpgp-revocs.d/` 下自动创建撤销证书。如果你提前备份了它：

```bash
gpg --import ~/.gnupg/openpgp-revocs.d/XXXX1234ABCD5678.rev
gpg --send-keys XXXX1234ABCD5678        # 通知密钥服务器
```

### 场景二：没有撤销证书，但私钥还在

```bash
gpg --gen-revoke XXXX1234ABCD5678 > revoke.asc
gpg --import revoke.asc
gpg --send-keys XXXX1234ABCD5678
rm revoke.asc
```

### 场景三：私钥也没了

无法作废。这也是为什么建议提前导出撤销证书并和私钥备份一起保存。

### 作废后

```bash
# 作废的密钥仍然保留在本地（用于解密旧内容），但标记为作废
gpg --list-keys             # [revoked] 标记会出现

# 后续生成新密钥
gpg --full-generate-key
```

---

## 13. 故障排查

```bash
# 加密时报 "No public key"
gpg --list-keys                         # 检查密钥是否存在

# 解密时报 "No secret key"
gpg --list-secret-keys                  # 检查私钥是否存在

# 忘记密钥密码 → 无法恢复
# 这就是为什么要备份：至少你还保有私钥文件本身
# 可以生成新密钥，但用旧密钥加密的数据永远无法解密

# 在 Emacs 中 `C-c e` 报错 "GPG not found"
which gpg                               # 确认 gpg 在 PATH 中
brew list gnupg                         # 确认已安装
```

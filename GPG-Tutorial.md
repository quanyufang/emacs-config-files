# GPG 从零开始操作教程

> 跟着走一遍，约 10 分钟。

---

## 第一步：安装 GPG

```bash
brew install gnupg
```

验证：

```bash
gpg --version | head -1
# → gpg (GnuPG) 2.x.x
```

---

## 第二步：生成密钥

```bash
gpg --full-generate-key
```

交互式问答，每一步这样选：

```
请选择你要使用的密钥类型：
   (1) RSA and RSA
   (4) RSA (仅签名)
   (14) Existing key from card
你的选择？ 1                    ← 选 1，加密+签名都能用

RSA 密钥的长度应在 1024 位和 4096 位之间。
你要使用的密钥长度？(3072) 4096  ← 输入 4096，更安全

请指定密钥的有效期。
  0 = 永不过期
你的选择？ 0                    ← 选 0，一直用。也可以设 2y（两年）

以上正确吗？(y/N) y              ← 确认

GnuPG 需要构建用户标识以辨认你的密钥。

真实姓名：Your Name            ← 你的名字（任意）
电子邮件地址：your@email.com    ← 你的邮箱
注释：用来加密笔记等信息         ← 备注用途
你选定的用户标识：
  "Your Name (用来加密笔记等信息) <your@email.com>"

更改姓名(N)、注释(C)、电子邮件地址(E)或确定(O)/退出(Q)？ O  ← 确认

```

随后弹出密码输入框，设一个你能记住但别人猜不到的密码。**这个密码无法找回，务必记牢。**

完成后看到：

```
[keyboxd]
---------
pub   rsa4096/XXXX1234ABCD5678  2026-06-10 [SC]
      AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555
uid           [ultimate] Your Name (用来加密笔记等信息) <your@email.com>
sub   rsa4096/YYYY8888ZZZZ9999  2026-06-10 [E]
```

逐行解释：

| 行 | 字段 | 含义 |
|----|------|------|
| `[keyboxd]` | — | GPG 的存储后端，忽略即可 |
| `pub` | 主密钥 | 你的身份凭证 |
| `rsa4096` | 算法与长度 | RSA 算法，4096 位 |
| `XXXX1234ABCD5678` | 密钥 ID | 指纹的最后 16 位，日常引用用这个 |
| `2026-06-10` | 创建日期 | 生成日期 |
| `[SC]` | 主密钥用途 | **S**ign 签名、**C**ertify 签发子密钥 |
| 第二行 | 完整指纹 | 40 位十六进制，全球唯一的身份标识 |
| `uid` | 用户标识 | 你的名字 + 邮箱 |
| `[ultimate]` | 信任级别 | 这是你自己的密钥，完全信任 |
| `sub` | 子密钥 | 从主密钥派生，日常加密用这个 |
| `[E]` | 子密钥用途 | **E**ncrypt 加密 |

**结构关系：**

```
主密钥 [SC]  ← 你的身份，用于签名和签发子密钥（不参与加密）
  ├── 指纹    ← 身份证号
  ├── UID     ← 名字 + 邮箱
  └── 子密钥 [E] ← 日常加密解密干活的就是它
```

> 这是 GPG 的安全设计：主密钥只管身份，子密钥干活。万一子密钥泄露，用主密钥可以撤销它而不影响身份。

生成成功。

---

## 第三步：查看密钥 ID（日常引用用）

> **密钥 ID 只是标识符，不能用来恢复密钥。** 要恢复丢失的密钥，唯一方法是第四步的备份文件。

```bash
gpg --list-keys --keyid-format LONG
```

输出中 `pub` 行 `/` 后面的那串就是你的密钥 ID。它的用途是：在命令行中替代 40 位完整指纹，方便你日常操作。

```
密钥 ID  : XXXX1234ABCD5678      ← 日常简写（非敏感，但不能恢复密钥）
完整指纹 : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  ← 完整身份（非敏感）
```

> ⚠️ 记下密钥 ID ≠ 备份密钥。密钥 ID 就像身份证号——只能指出"是哪把密钥"，无法代替密钥本身。

---

## 第四步：备份私钥（防丢失，非防泄露）

### 这一步是做什么的？

这一步不防别人偷看——它纯粹是为了**防止你自己丢失数据**。

你的私钥此刻只存在一个地方：`~/.gnupg/private-keys-v1.d/` 目录下。如果哪天：

- 硬盘坏了
- 误删了 `~/.gnupg/` 目录
- 换新电脑但没迁移

结果都一样：**所有加密的笔记永远无法解密**。

### 为什么导出后"立刻处理"？

`gpg --export-secret-keys` 导出的 `.asc` 文件是 **明文私钥** ——没有密码保护。任何人拿到它就能解密你全部笔记。所以：

```
导出 → 立刻用密码加密它 → 立刻删除明文版
```

三步必须在同一次操作中完成，不留明文文件在磁盘上。

### 不做备份，别人能拿到我的私钥吗？

**不能**。你的私钥存储在本机 `~/.gnupg/` 中，受文件系统权限保护，且有密钥密码加密。跳过这一步不会把私钥暴露给任何人。

**但如果别人能物理接触你的电脑呢？** 那他们确实可以读取 `~/.gnupg/` 目录下的密钥文件。不过密钥本身有密码保护——对方拿到文件也打不开。真正危险的场景是：

- 别人登录你的用户账户
- 你的 Emacs 正在运行且已输入过密钥密码（此时密钥在内存中解密状态）
- 或者你设了一个弱密码被暴力破解

> 总结：备份这一步解决的是"丢了怎么办"，不是"被偷了怎么办"。

### 撤销证书（随密钥自动生成）

GPG 在生成密钥时，还会自动在 `~/.gnupg/openpgp-revocs.d/` 下创建一个 `.rev` 撤销证书文件。它是**提前准备好的"作废声明"**——万一将来密钥泄露，导入它就能立刻标记密钥作废。不需要密码就能用，所以要和私钥备份一起安全存放。别丢了，也别公开发布。

### 操作

```bash
# 1. 导出
gpg --export-secret-keys --armor XXXX1234ABCD5678 > ~/gpg-private-key.asc

# 2. 再加密一次
gpg --symmetric --cipher-algo AES256 ~/gpg-private-key.asc
# 输入一个备份密码（可以和密钥密码不同）

# 3. 清理
rm ~/gpg-private-key.asc
```

现在你有一个 `~/gpg-private-key.asc.gpg` 文件——这就是你的救命稻草。

把它复制到：

- iCloud / Dropbox
- 另一台电脑
- 加密 U 盘

```bash
cp ~/gpg-private-key.asc.gpg ~/Library/Mobile\ Documents/com~apple~CloudDocs/
```

---

## 第五步：测试加密解密

### 5.1 加密一段文本

```bash
echo "Hello, 这是一条秘密消息" > test.txt
gpg --encrypt --armor --recipient XXXX1234ABCD5678 test.txt
# → 生成 test.txt.asc
cat test.txt.asc
```

看到乱码一样的 PGP MESSAGE 块就是成功了。

### 5.2 解密

```bash
gpg --decrypt test.txt.asc
# 输入密钥密码
# → Hello, 这是一条秘密消息
```

### 5.3 清理测试文件

```bash
rm test.txt test.txt.asc
```

---

## 第六步：在 Emacs 中试试

### 6.1 加密一条 org 条目

在任意 `.org` 文件中：

```org
* 我的日记
这不是秘密内容。

* 银行账号信息              :crypt:
卡号：6222 XXXX XXXX XXXX
密码：123456
```

按 `C-x C-s` 保存。标题含 `:crypt:` 标签的条目自动加密成乱码。

光标放在那条标题上，按 `C-c n c` 解密查看。再按一次恢复加密。

### 6.2 加密段落内的片段

在任意文本文件中：

```
这是一篇正常笔记。我的 API key 是 sk-abc123xyz，请妥善保管。
继续写其他内容……
```

1. 选中 `sk-abc123xyz` → 按 `C-c e`
2. 文本变成紫色加密块

光标放在加密块上 → 按 `C-c d` → 显示原文（绿色背景）。编辑完后按 `C-x C-s`，自动重新加密。

---

## 第七步：作废密钥（需要时）

如果你怀疑密钥泄露了（比如密钥 ID 出现在聊天记录里），可以作废它。

### 原理

密钥如果**从未使用过**（没加密过任何数据、没发送过公钥给别人），可以直接 `gpg --delete-secret-key` 删掉。但如果已经用过了，就不能简单删除——只能发布一份**撤销证书**告诉所有人"这个密钥不再有效"。证书一般在生成密钥时就自动创建好了，放在 `~/.gnupg/openpgp-revocs.d/` 下。

### 操作

```bash
# 1. 如果 openpgp-revocs.d/ 下有撤销证书
ls ~/.gnupg/openpgp-revocs.d/
gpg --import ~/.gnupg/openpgp-revocs.d/XXXX1234ABCD5678.rev

# 2. 如果撤销证书丢了但私钥还在，现场生成
gpg --gen-revoke XXXX1234ABCD5678 > ~/revoke.asc
gpg --import ~/revoke.asc
rm ~/revoke.asc

# 3. 验证
gpg --list-keys     # 应出现 [revoked]
```

作废后旧密钥仍可用于解密旧数据，但不应再用于加密新内容。然后重新走第二步生成新密钥即可。

### 密钥生命周期

```
生成 → 备份私钥 + 撤销证书（第四步）
     → 日常使用（第五、六步）
     → 泄露 / 弃用 → 撤销（本步）
     → 重复
```

## 第八步：日常备忘

```bash
# 查看密钥还在不在
gpg --list-keys

# 确认备份还能用
gpg --decrypt ~/gpg-private-key.asc.gpg > /dev/null && echo "备份完好"
```

---

## 哪天换了新电脑

```bash
# 1. 安装 GPG
brew install gnupg

# 2. 拿到备份文件 gpg-private-key.asc.gpg

# 3. 解密 → 导入
gpg --decrypt gpg-private-key.asc.gpg | gpg --import

# 4. 验证
gpg --list-keys

# 5. 删除中间文件
# 不需要删除什么——decrypt 的输出直接管道给 import，没落盘
```

---

## 故障排查

| 问题 | 解决 |
|------|------|
| `C-c e` 提示 "GPG not found" | `brew install gnupg` |
| 加密时提示 "No public key" | `gpg --list-keys` 确认密钥存在 |
| 解密时提示 "No secret key" | `gpg --list-secret-keys` 确认私钥存在 |
| 解密时提示 "Bad passphrase" | 密码输错了，再试一次 |
| 完全忘记密码 | 无解——只能用备份密钥生成新密钥，旧数据永久丢失 |
| IDEA 窗口没有密码输入框 | 终端里 `export GPG_TTY=$(tty)` 然后重启 Emacs |

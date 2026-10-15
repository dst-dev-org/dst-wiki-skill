# 准备本地 DST 源码

仅需准备源码、使用历史快照或处理准备失败时读取；普通查询按 [查询规则](../query/query.md) 执行，无需先读本文件。这里说明常规准备命令及其语义、显式路径、历史快照用法和失败处理。PowerShell 是可选方式，不依赖 Python 或 Rust。

## 当前安装

K／S 已确认则复用，仅缺所需值时才读 [路径约定](paths.md)。以本 Skill 的绝对脚本路径执行，下面 S／K／安装路径须替换为实际绝对路径；三者可以位于不同盘符。`-GamePath` 优先于 `-SteamPath`，只检查实际采用的安装路径。

游戏／Steam 安装路径未明确时，先用只传 K 的命令，让脚本按 Steam 注册表与库记录尝试定位；定位失败才集中询问安装路径，不扫描磁盘。显式安装路径无效时报告该路径问题，不自动改用其他位置。

```powershell
& "<S>/scripts/setup_raw.ps1" -KnowledgeRoot "<K>"
& "<S>/scripts/setup_raw.ps1" -KnowledgeRoot "<K>" -GamePath "<本机 DST 安装目录>"
& "<S>/scripts/setup_raw.ps1" -KnowledgeRoot "<K>" -SteamPath "<Steam 根目录>"
```

- 从本地 Steam 安装定位 `scripts.zip` 与 Steam buildid，不下载游戏或把远程分支当游戏版本。
- 同 build 且必需源码可用时跳过解压；同会话已检查且安装未变化时可复用，不逐条问题重复运行。
- 无需更新时只输出一行 Skip，定位路径与版本检查细节用 `-Verbose` 查看。
- 缺失或版本变化时先在临时目录完成解压与结构检查，再归档旧快照并切换 `raw/current/`。归档在 `raw/archive/`，同名冲突保留两份；失败保留可用旧快照。
- `-Force` 用于修复同 build 的损坏源码，也先归档旧快照；不作为查询默认参数。安装版本无法识别时记录 `unknown`，不能声称版本已核验或凭同名跳过。
- 实际解压后，按 [日志维护](../maintain/maintain-log.md) 在 `wiki/log.md` 追加日期、准备版本和旧快照位置；Skip 不写日志，不更改知识页核验版本、fork pin 或 Wiki 索引。游戏脚本是证据，不能在其中实现模组修改。

## 已有与历史快照

用户明确指定历史版本时，使用其目录与版本记录，不自动替换为当前安装；技术引用写实际路径。人工准备须有 `scripts/` 和 `BUILD.txt`，版本说明编号体系，不能把 Steam buildid 与其他 DST build 号混用。

可选只读定位使用本次明确的 scripts 目录及父级 BUILD.txt，不切换 current：

```powershell
& "<S>/scripts/resolve_paths.ps1" -KnowledgeRoot "<K>" -SourceRoot "<历史快照>/scripts"
```

定位结果的 `source_available` 只检查必要结构，版本也只是快照记录，不证明与本机安装一致或所有证据有效。其他环境直接检查同样的目录与 BUILD.txt，无需 PowerShell。

非 Windows 或不执行 PowerShell 时，从用户已有合法本地安装的 `scripts.zip` 解压到知识根的临时目录，确认其 `scripts/` 含 `class.lua`、`entityscript.lua`、`components/`、`prefabs/`，且后两个目录各含至少一个 `.lua` 文件，避免形成重复的 `scripts/scripts/`。在同级 `BUILD.txt` 记录实际版本：Steam 可写纯数字 buildid，其他来源写 `编号体系:版本`；无法确认写 `unknown`。本版本记录不证明知识页已复核。

只有临时快照检查完成后才将旧 `raw/current/` 保留到 `raw/archive/` 的不冲突目录，再切换新快照；失败保留或恢复旧 current。实际切换后追加日志；不改解压出的 Lua、不以下载游戏源码补缺口。无需为人工准备建立 output 或 AST 缓存。

找不到 Steam、安装或压缩包时，继续使用已有可读快照并说明版本与未完成的安装检查；快照也缺失时可读 Wiki，但必须说明源码兜底不可用及不能核验的结论。需要本机路径时再询问，不反复执行同一失败命令。

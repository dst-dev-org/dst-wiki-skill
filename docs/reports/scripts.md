# 脚本与隔离检查检视

日期：2026-10-15。范围：`scripts/resolve_paths.ps1`、`scripts/setup_raw.ps1`、`tests/verify_paths.ps1` 及文档中对它们的描述，对照 `dst-mod-dev-skill` 分发副本与 `bundled-helpers.json`。只做只读检视与隔离测试；未改脚本行为，未触碰真实知识根、游戏安装或用户配置。

## 本轮证据

- 哈希链一致（sha256）：`resolve_paths.ps1`＝`860ead01aa0b5c93310431118332a0a5ee23f1d3a617c737a614f3529bf87888`，`setup_raw.ps1`＝`dbf470869d8f80bce7d0287cec7a2432a49cb4ab5bb604561c83923af14d5cdf`，`maintain-log.md`＝`34b1af6ca4fb28566ee0d070e067cc22087ecb7d125377d50edca3f423729676b`，三处（本包原件、`dst-mod-dev-skill` 副本、清单）完全相同。
- 三个 `.ps1` 均为纯 ASCII、无 BOM，符合各自的 5.1 兼容声明。
- 本机实测（Windows PowerShell 5.1）：`tests/verify_paths.ps1` 14/14 通过并安全清理临时目录；`DST_SETUP_SCRIPT` 指向本包 `setup_raw.ps1` 时，工具箱 `scripts/tests/python/test_setup_raw.py` 7/7 通过（11.4 秒）。本机无 pwsh，未复跑 PowerShell 7。
- 文档契约核对：`prepare-source.md`／`first-use.md`／`paths.md`／`query.md`／README 对跳过条件、临时解压后归档、失败保留旧快照、`unknown` 不按同名跳过、不创建目录／不写配置、输出字段名（`knowledge_root`、`wiki_available`、`source_directory_exists`、`source_available`、`source_version`、`toolbox_warning` 等）的描述与实现一致，未发现行为性偏差。未发现 P0／P1 缺陷。

## 发现

| 编号 | 位置 | 问题 | 建议 |
|---|---|---|---|
| S-1 | `README.md:73` | “轻量 helper 改动用 `verify_paths.ps1` 验证”未说明该测试只覆盖 `resolve_paths.ps1`；测试脚本仅复制并执行定位 helper（`verify_paths.ps1:49`），对 `setup_raw.ps1` 零覆盖。按此句维护写快照脚本会得到“14 项通过”的误导性结论 | 补一句指向工具箱 `test_setup_raw.py`（`DST_SETUP_SCRIPT` 指向本包脚本，见工具箱 README 的运行命令）；如希望不依赖工具箱，则后续再考虑在包内补 setup_raw 隔离用例 |
| S-2 | `setup_raw.ps1:18` | 用 `IsPathRooted` 判绝对，实测 `D:foo`、`\foo` 均返回 True；驱动器相对／根相对根会按进程当前目录解析，与 `resolve_paths.ps1:28` 的严格检查及 `verify_paths.ps1:82` 的既有断言不一致。这是会移动／归档目录的写入脚本 | 复用 `resolve_paths` 的同款正则检查（含非 Windows 回退 `IsPathRooted`）；两脚本本就独立分发，允许小段重复 |
| S-3 | `setup_raw.ps1:15,137,142,182` | `$ErrorActionPreference='Stop'` 下 `Write-Error` 直接抛终止错误（实测捕获为 `WriteErrorException`），其后 `exit 1` 为死代码；CLI 退出码仍非零，工具箱失败用例依赖此点并通过。错误输出带 cmdlet 前缀与分类信息 | 三处改为 `throw`，消息文字不变；或明确采用 `Write-Error -ErrorAction Continue` 保留原意图 |
| S-4 | `setup_raw.ps1:28,136` | `Find-SteamPath -Hint` 无任何调用点传值，分支为死代码；显式传入但无效的 `-SteamPath` 会跳过发现流程，最终报“DST not found. Please specify with -GamePath.”，未指出实际是 Steam 路径问题，也未校验其存在／绝对性 | 主流程对显式 `-SteamPath` 先校验目录存在并抛“Steam path not found: …”，随后删除 `-Hint` 参数 |
| S-5 | 工具箱 `test_setup_raw.py:24` | 合成安装布局仍是旧路径 `scripts/tools/setup/setup_raw.ps1`；脚本头部注释已改回 `scripts/setup_raw.ps1`，测试未同步（脚本不依赖自身位置，仅布局失真） | 改为 `<project>/scripts/setup_raw.ps1`（工具箱侧一行） |
| S-6 | `prepare-source.md:34` | 人工准备清单列了四项结构，未提 `components/`／`prefabs/` 还需至少一个 `.lua`（`Test-ScriptsLayout` 更严格）。行为自愈（下次运行会重解压修复），仅为提示缺口 | 可加半句“两个目录均含 `.lua` 文件” |

## 覆盖缺口（补充性，非缺陷）

- `verify_paths.ps1` 未覆盖：显式有效 `-ToolboxRoot`（配置提供与显式失效均已覆盖）、绝对但不存在的 `-SourceRoot`（`source_directory_exists=false`）、`-AllowUninitialized` 与 `-SourceRoot` 组合。
- `test_setup_raw.py` 未覆盖：`-SteamPath` 直达、`steamapps/libraryfolders.vdf` 库发现、注册表回退（各用例均传 `-GamePath`）；`unknown` 与 `unknown` 不跳过仅有文档约定、无直接断言（现有 `build-unidentified` 归档用例部分接近）。

## 尚未验收

本轮只在 Windows PowerShell 5.1 复跑；PowerShell 7／非 Windows 沿用上轮与工具箱记录，未在本轮复验。真实 Steam 安装、大体积 zip 解压与并发两次运行的竞争未测；合成 zip 与固定 fixture 不证明真实安装路径全部可达。

## 修复与复验（2026-10-15）

以下为原检视后的追加记录，不改写上文的历史结论与旧哈希。

| 编号 | 处理结果 |
|---|---|
| S-1 | README 区分定位脚本与源码准备脚本的检查；增加工具箱测试链接、`DST_SETUP_SCRIPT` 和定向测试命令，说明如何选择 PowerShell 版本 |
| S-2 | `KnowledgeRoot` 采用与定位脚本一致的绝对路径判定；Windows 拒绝驱动器相对、根相对及普通相对路径；实际采用的 `GamePath`／`SteamPath` 也要求绝对目录且存在 |
| S-3 | 三处 `Write-Error` 后接 `exit 1` 改为 `throw`，保持原错误消息和非零失败退出 |
| S-4 | 删除未使用的 `Find-SteamPath -Hint`；Steam 路径无效时给出对应参数错误；显式 `GamePath` 优先，不校验未使用的 `SteamPath`；自动发现候选也只接受绝对目录 |
| S-5 | 工具箱合成安装布局改为 `scripts/setup_raw.ps1`；增加路径拒绝、安装目录错误、Steam 直达、`libraryfolders.vdf`、优先级、unknown 与跨盘回归 |
| S-6 | 人工准备说明补充 `components/` 和 `prefabs/` 各含至少一个 `.lua` 的条件；两 Skill 的安装路径说明同步绝对路径、跨盘支持和参数优先级 |

复验结果：Windows PowerShell 5.1 与 PowerShell 7.6.5 各自通过路径定位 14/14、源码准备 14/14；跨盘用例已启用，无跳过。源码准备耗时分别为 25.899 秒和 30.520 秒。修改后的脚本仍为纯 ASCII、无 BOM；两包 Skill 基础校验与三仓 `git diff --check` 通过。

跨盘使用隔离合成安装：脚本在 C 盘，游戏压缩包与 manifest 在 D 盘，分别将知识根放在 C／D 盘，验证直接指定 `GamePath` 的准备、旧快照归档和同版本跳过；C 盘 Steam 的 `libraryfolders.vdf` 指向 D 盘库时，也完成了发现与强制重建。逐字节比对游戏输入文件，保持不变。临时解压、归档与切换只在所选知识根内进行，因此无需跨盘移动游戏目录。测试目录全部清理，未操作真实游戏安装、正式知识快照或用户配置。

通过工具箱同步器更新 `dst-mod-dev-skill` 脚本副本和 `bundled-helpers.json`；`setup_raw.ps1` 新 sha256 为 `561ecaa5e3c87e25274f2abdd6098407b8c518fe85187b3c3e1eb83483774ecb`。三项分发资源的原件、副本和清单逐项一致，另外两项哈希未变。测试输出、修复前备份和哈希核对保存在本地 `migration-local/scripts-review-fixes-20261015/`。

剩余范围：注册表回退、真实 Steam 安装和大体积压缩包、并发准备及非 Windows 本轮未测；定位测试的两个可选路径覆盖缺口仍保留。未提交或推送，无需新增日常依赖或用户决策。

## 独立复跑（同日，另一会话）

在本工作副本上以 Windows PowerShell 5.1 复跑：`tests/verify_paths.ps1` 14/14；`test_setup_raw.py` 14 项通过（未设 `DST_TEST_OTHER_DRIVE_TEMP`，跨盘 1 项按预期跳过，上节记录为已启用）；README 新记载的 `python -m unittest discover -s "<工具箱>/scripts/tests/python" -p test_setup_raw.py` 命令实测可执行。新 `setup_raw.ps1` 仍为纯 ASCII、无 BOM；本包 29 份 Markdown 的相对链接与锚点检查 0 问题；三仓 `git diff --check` 干净；工具箱默认分支 `master` 与 README 外链一致；`hashes.json` 与 `bundled-helpers.json`、两包副本逐项相同。PowerShell 7 未在本会话复跑，沿用上节记录。

## 提示处理与覆盖补充（2026-10-16）

- README 结尾的检视入口补上指向本记录（脚本检视）的链接；PLAN.md 的 S01 完成项与 design.md 的 S01 状态同步注明补充后的计数（现 16 项），历史报告 `first-use.md` 的“14 项”按当时结论保留。
- `tests/verify_paths.ps1` 补两个可选用例：显式有效 `-ToolboxRoot`（成功且无警告），以及绝对但不存在的 `-SourceRoot`（目录／结构／版本均按缺失报告，current 快照不变）。套件由 14 项扩展到 16 项，文件仍为纯 ASCII、无 BOM。
- 同日复跑（Windows PowerShell 5.1）：路径定位 16/16；源码准备 14 项通过且跨盘用例已启用、无跳过（`DST_TEST_OTHER_DRIVE_TEMP` 指向 D 盘临时父目录，已清理），上节“跨盘 1 项跳过”的差异已消除。PS 7 不在本机，仍沿用前节记录。
- 本次改动不涉及哈希同步的三项分发资源；README 相对链接与锚点全包检查 0 问题。

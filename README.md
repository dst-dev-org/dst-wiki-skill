# DST Wiki Skill

用于查询共享 DST 知识、提炼模组经验、增修 cookbook／机制知识，以及版本复查和索引审校。

整个目录是安装包，根 [SKILL.md](SKILL.md) 是 AI 入口。规则、模板和必要辅助脚本随包提供，知识库与游戏源码由外部路径定位。

## 安装与配置

1. **安装完整目录。** 将本仓库复制到宿主支持的 Skill 路径，安装目录名使用 `dst-wiki-skill`，与 SKILL.md 的 `name` 及仓库名一致。不要只复制 SKILL.md；保留 `references/`、`assets/` 和 `scripts/` 等随包文件。Codex 可安装到项目 `.agents/skills/dst-wiki-skill/` 或用户 `~/.agents/skills/dst-wiki-skill/`，见 [官方说明](https://developers.openai.com/codex/skills/)。其他宿主按其 Skill 安装约定放置。

2. **选择知识库。** 使用已有知识目录，或取得 [dst-wiki 知识仓](https://github.com/dst-dev-org/dst-wiki)。放在宿主可访问的位置即可，无需与 Skill 或工具箱相邻。

3. **指定知识路径。** 本次请求直接给出知识根的绝对路径即可。首次选定并检查通过后，AI 自动保存到用户主目录 `.dst-wiki/config.json` 并告知；临时使用可明确说“不保存配置”。已有默认路径不会被本次另指定路径覆盖，需明确要求切换默认位置。配置示例：

   ```json
   {
     "knowledge_root": "D:/DSTKnowledge/dst-wiki"
   }
   ```

更新 Skill 不覆盖个人配置。完整保存规则见 [保存配置](references/setup/first-use.md#保存配置)，可选 `toolbox_root` 与定位优先级见 [路径约定](references/setup/paths.md)。

如需编写或调试目标模组，可另行安装模组开发 Skill [dst-mod-dev-skill](https://github.com/dst-dev-org/dst-mod-dev-skill)。两者共用知识路径配置，也可各自独立使用。

## 首次使用

安装后让 AI 从 [SKILL.md](SKILL.md) 选择当前任务流程。例如：

> 用知识库 D:/DSTKnowledge/dst-wiki 查询工具按次消耗。

操作通过自然语言选择，具体发现与触发由宿主决定，无需注册斜杠命令。首次取得知识资产、保存配置或明确创建空库时，读取 [首次使用说明](references/setup/first-use.md)；仅需定位工具或处理异常时，直达 [定位工具与异常处理](references/setup/first-use.md#定位工具与异常处理)。

普通查询、知识生成与案例维护无需 Python、Rust、LuaLS、fork 或工具箱。生成技术内容仍需定向核验源码；缺少源码时可查询已有 Wiki，并说明当前版本的核验缺口。

查询直接使用现有知识，不自动核对游戏是否更新或执行版本／哈希对比；需要跟进版本时，明确提出版本核验或知识库维护请求。

## 按需准备源码

源码解压不是安装前置。需要查询源码、核验当前版本或生成知识时，再准备本地快照；本包不分发游戏脚本。

Windows／Steam 可使用随包的 [setup_raw.ps1](scripts/setup_raw.ps1)，执行时必须传入实际 `KnowledgeRoot`。其他平台按 [快照约定](references/setup/prepare-source.md) 人工准备；没有 PowerShell 仍可直接读取配置和 Markdown。

## 目录结构

```text
SKILL.md                         # AI 意图入口，直接链接流程文件
references/
├── setup/                       # 定位、首次使用、源码准备
├── query/                       # 查询规则与可选查询工具
└── maintain/                    # 模组提炼、骨架／版本／知识／索引／日志维护、按需校验、格式与类型选择
assets/templates/                # 实际生成时按需读取的模板
assets/prompts/                  # 实际派发／交接新页或版本维护任务时才用的提示词骨架
scripts/
├── resolve_paths.ps1            # 只读定位知识／源码／可选工具箱
└── setup_raw.ps1                # 按需准备本地源码快照
tests/
└── verify_paths.ps1             # 定位 helper 的隔离检查
docs/
├── design.md                    # 本包工程设计
└── reports/                     # 历史检视记录
AGENTS.md / CLAUDE.md            # 本包工程维护入口
README.md / PLAN.md              # 安装说明／工程任务与进度
LICENSE                          # CC BY-SA 4.0 完整法律文本
NOTICE                           # 授权范围、署名与例外
CONTRIBUTING.md                  # 贡献与授权声明
.gitignore                       # 本地缓存与个人配置忽略
```

AI 从 SKILL.md 直达任务规则，路径、模板、格式及工具说明按条件读取。日常查询与知识维护不加载 README／PLAN、工程设计或历史报告。references 子目录不另设 README 或 index。

生成模板为 component／prefab／mechanism 三份，新建或重组时只选所需一份。非组件差异见 [类型选择](references/maintain/source-types.md)，模板检视范围见 [记录](docs/reports/source-templates.md)。

## 维护本包

本节仅用于维护 Skill 包。修改前读所改文件全文，按影响检查内部引用、配置约定、路径／helper 行为和独立安装。组件覆盖在知识仓维护，工具与类型工程在工具箱维护。

行数、字节和链接数量仅在专项检视或读取成本对比时记带日期的快照，日常修改不要求重记；链接方向与数量不作为质量门槛，按实际发现／读取用途保留必要入口。结构统计不等于模型加载量或 token 收益。

- 本包是配置定位、源码准备脚本与共享日志规则的权威源。`dst-mod-dev-skill` 的分发副本由 [dst-toolbox](https://github.com/dst-dev-org/dst-toolbox) 中的 `scripts/tools/maintenance/sync_skill_helpers.py` 显式同步，并更新 `bundled-helpers.json` 哈希清单；安装后的本包不依赖模组开发 Skill 或工具箱。
- 页面格式、标签与大小规则只在 [write-format.md](references/maintain/write-format.md) 维护，工具箱通过 `--format` 读取；源码知识页可按复杂度选择 `size_class`，未标注的已有页保持标准档，无需迁移。[维护校验](references/maintain/verify-wiki.md#按变更选择) 只留检查选择、常用命令与结果判断；[工程专项](references/maintain/verify-engineering.md) 仅工程任务读取。工具箱维护参数、输出和实际范围：`references/wiki-validation.md`、`references/source-baseline.md` 与 `references/source-link-migration.md`，接口核验与机器格式同样留在那里。
- 定位脚本 `resolve_paths.ps1` 改动用 [verify_paths.ps1](tests/verify_paths.ps1) 在隔离目录验证：`pwsh -NoProfile -File tests/verify_paths.ps1`。Windows PowerShell 5.1 可用 `powershell` 执行同一测试；此测试不覆盖源码准备脚本。
- 源码准备脚本 `setup_raw.ps1` 改动用工具箱的 [test_setup_raw.py](https://github.com/dst-dev-org/dst-toolbox/blob/master/scripts/tests/python/test_setup_raw.py) 验证。以下命令显式选定本包脚本；`DST_TEST_POWERSHELL` 可指定 `powershell` 或 `pwsh` 的绝对路径以分别验证 5.1／7。测试环境不是日常使用前置。

```powershell
$env:DST_SETUP_SCRIPT = "<dst-wiki-skill绝对路径>/scripts/setup_raw.ps1"
python -m unittest discover -s "<工具箱绝对路径>/scripts/tests/python" -p test_setup_raw.py -v
```

Windows 跨盘测试可将 `DST_TEST_OTHER_DRIVE_TEMP` 设为与默认临时目录不同盘符、已存在且可写的绝对目录；未设置则跳过跨盘用例。测试只在该目录内创建临时子目录并清理，不使用真实游戏安装。

公共 helper 或日志规则修改后，用以下维护命令同步两份脚本、日志规则与哈希清单；将占位符替换为实际绝对路径。此同步步骤需要 Python，仅用于包维护：

```powershell
python "<工具箱绝对路径>/scripts/tools/maintenance/sync_skill_helpers.py" --source-skill "<dst-wiki-skill绝对路径>" --development-skill "<dst-mod-dev-skill绝对路径>"
```

工程进度见 [PLAN.md](PLAN.md)，包内职责见 [工程设计](docs/design.md)。安装发现与定位见 [宿主基础检视](docs/reports/host-basic.md)，自主路由与读取成本见 [独立使用检视](docs/reports/runtime-20261016.md)，脚本与隔离检查见 [脚本检视](docs/reports/scripts.md)。各报告只覆盖实际记录的范围，不代表所有宿主的自主流程均已通过。

## 授权

原创内容采用 [CC BY-SA 4.0](LICENSE)：可商用、可修改，须署名并以同一许可共享改作；授权范围、署名方式与例外见 [NOTICE](NOTICE)。本包不含游戏源码，游戏中立性与第三方来源遵循其原授权，不随本仓授权转授。外部贡献按 [贡献约定](CONTRIBUTING.md) 接收。

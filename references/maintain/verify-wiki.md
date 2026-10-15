# DST Wiki 维护校验

仅写页收尾或明确检查任务时读取；普通查询不加载。

## 按变更选择

复用已确认的 K／S／T，只读命中行、对应小节与结果处理；同会话未变说明不重读，不读脚本实现。仅在参数不足或结果异常时读对应工具箱说明（下述路径相对 T），不先读整份 README。工具／依赖未就位时，按[路径约定](../setup/paths.md#t可选工具箱根)的顺序定位一次（含当前工作区自查），确认没有再人工核对并报告未检项，不安装环境。

| 本次范围 | 检查 |
|---|---|
| 检视需自建机械基线 | 页面与导航、源码引用、源码哈希基线、覆盖自查四项一次跑完，输出当待解释清单；见[检视开检](#检视开检) |
| 新建／修改知识页，或检查格式、链接 | [页面与导航](#页面与导航) |
| 新页登记／导航变化 | 同上，追加 `--check-indexes` |
| 覆盖自查：别名归属、返回链、索引预算 | 自建检视机械基线时必跑；普通写页按需；工具箱缺失时按上述顺序定位，仍无则人工核验 |
| 新 Prefab 或主名称变更，需定位简中译文 | [Prefab 译名定位](#prefab-译名定位) |
| 改页含本地 Lua／`.po` 链接，或检查源码锚点 | [源码引用](#源码引用) |
| 旧新快照间迁移引用行号 | [源码锚点迁移](#源码锚点迁移) |
| 需建／刷新基线，或明确版本／来源检查 | [源码哈希基线](#源码哈希基线) |
| 新增／修改完整 Lua 示例 | [Lua 示例](#lua-示例) |

占位符执行前替换为实际绝对路径；传给校验／迁移脚本的页面参数统一使用绝对路径，派发清单中相对 `K/wiki` 的路径先转换再调用。写页默认只查改页与受影响入口，不自动扫全库；检查任务按用户范围执行，不自动修页。

## 检视开检

四项依次为：

1. 页面与导航（登记后追加 `--check-indexes`）：看 `passed`／`issues`／`navigation`。
2. 严格源码链接：`errors` 必须为 0，`warnings` 按引用意图判断。
3. 源码哈希基线：`stale_entries`／`affected_pages` 非空先退回重写，不带过期基线做语义核验。
4. 覆盖自查：别名归属与返回链；新建页的返回行要指向登记它的叶索引，否则登记后立刻产生 `backlink-mismatch`。

命令与参数分别见本页[页面与导航](#页面与导航)、[源码引用](#源码引用)、[源码哈希基线](#源码哈希基线)、[覆盖自查](#覆盖自查)。谁在什么时点跑这四项由调用方决定，本文件只管命令与判据。工具缺失时报告缺口并人工核验，不另写一次性统计脚本代替可复现命令。

## 页面与导航

`python "<T>/scripts/tools/verify/validate_page.py" --wiki-root "<K>/wiki" --source-root "<本页所用scripts根>" --format "<S>/references/maintain/write-format.md" "<页面绝对路径>"`

看 `passed`／所选页 `issues`，涉及导航时另看 `navigation`；问题修复后重查命中项。具体范围／参数见 `references/wiki-validation.md#页面与导航`。

共享索引登记前先只查草稿页、不加 `--check-indexes`（此时不检查导航），登记完成后追加该参数再验收。`registration: ... got 0` 表示尚无叶级表格登记，最终导航验收不能忽略。

## 覆盖自查

需要时运行 `python "<T>/scripts/tools/verify/verify_page_coverage.py" --wiki-root "<K>/wiki" --format "<S>/references/maintain/write-format.md" [--scope prefab|all] [--registrations <清单.json>] [--changed <变更清单.txt>] [--json]`。

默认 `--scope prefab` 只报 Prefab 页：返回链与 confirmed 别名归属；索引预算、非 Prefab 返回链、短语别名只在 `--scope all` 输出。注册清单只作候选／backlog；字面 `Prefab("...")` 会漏变量、循环、`MakePlacer` 与拼接名，动态名先定位 `file:line` 或成族记录，不猜。FX 命名豁免与注册名归属见 [页面格式](write-format.md#标签)、[类型指引](source-types.md#prefab)，不要对 FX 缺口用 `--strict`。confirmed 按精确 aliases 匹配，大小写变体只出 info；D 只统计非 archived Prefab 页，组件／归档页不算覆盖；HTML 注释不提供返回链。参数、`--missing-scope`／`--fail-on`、退出码与发现码清单以工具箱 `dst-toolbox` 的 `references/wiki-validation.md` 覆盖自查节为准，本包不复制。

全库有问题时，可用 `--page` 按 Wiki 相对路径筛对象范围内的明细。总计和退出码仍按全库判定。报告分别写全库结果与对象范围结论，查冲突时核对明细的全部涉及页。判定该范围零命中前确认 `truncated=false` 且目标级别或发现码已展开。无归属页的注册缺口按注册名与同版清单对账。

## Prefab 译名定位

`python "<T>/scripts/tools/verify/inspect_prefab_names.py" --source-root "<本页所用scripts根>" "<本批页面绝对路径>"`

查看候选译文、行号和 `review_visible_name`。单页用 `--key` 查实际键或 `--display-name` 比对已核实的游戏名；多页用 `--page-key`／`--page-name` 按页绑定，可保存报告供 `--reuse` 复审。参数见 T 的 `references/wiki-validation.md`。

## 源码引用

`python "<T>/scripts/tools/verify/validate_source_links.py" --wiki-root "<K>/wiki" "<页面绝对路径>"`

看 `counts.errors/warnings` 与对应 `issues`；error 未处理不能称通过，warning 按引用意图判断，不机械挪行。见 `references/wiki-validation.md#源码引用`。

## 源码锚点迁移

`python "<T>/scripts/tools/maintenance/plan_source_link_updates.py" --wiki-root "<K>/wiki" --old-source-root "<旧scripts根>" --new-source-root "<新scripts根>" "<页面绝对路径>"`

看 `proposals/issues`，只定向处理待判断项；补丁格式／应用基准见 `references/source-link-migration.md`，采用条件见[局部修订](maintain-version.md#核验影响与局部修订)，机械通过不批准升版。

## 源码哈希基线

`python "<T>/scripts/tools/verify/validate_source_hashes.py" check --knowledge-root "<K>" --fresh-hours 0 "<页面绝对路径>"`

`python "<T>/scripts/tools/verify/validate_source_hashes.py" record --knowledge-root "<K>" --write "<页面绝对路径>"`

检查先看 `counts/affected_pages`，写入看 `refreshed/recorded` 与跳过／异常；是否需要刷新按[版本维护](maintain-version.md)，新页／整页核验按[知识维护](maintain-wiki.md#证据与状态)。缓存、输出与 record 细节见 `references/source-baseline.md`。

## Lua 示例

`& "<T>/scripts/fullmoon-dst/target/debug/examples/parser_probe.exe" --syntax-only "<临时完整示例.lua>"`

新增或修改完整示例时，把原样代码按声明的文件边界分别放进临时文件，用已有解析器检查。保留文件顶层的 `return`、作用域和装载边界。复验可在逐段比对代码内容一致后复用原解析结果，并注明复用来源。解析、静态接入核验和游戏运行分别记录，工具不可用时记语法未检，结束清理临时文件。替代路径与范围见 `references/wiki-validation.md#lua-示例`。

## 结果处理

只读计数和命中详情；输出不完整先缩范围或按对应说明补查，运行失败／输入损坏不能当通过。仅修本次范围的明确问题，重跑受影响检查；同一缺失目标的重复报告合并。报告分别列出机械检查、逐项源码核验、抽样和未检范围。结构、链接、哈希与语法检查通过均不能证明断言正确或游戏效果成立。

## 工程专项入口

仅 facts／类型／LuaCATS／LSP 等工程改动才读[工程专项校验](verify-engineering.md)，普通写页不加载。

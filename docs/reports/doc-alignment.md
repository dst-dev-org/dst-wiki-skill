# 工程设计文档对齐检视

日期：2026-10-16。范围：`docs/design.md`、`PLAN.md` 与 `README.md`、六份 `docs/reports/` 记录、SKILL.md／references 现状之间的相互引用与事实一致性。只读核对与计数抽查；未改包行为，未触碰知识仓页面、游戏源码或工具实现。

## 核对证据

- 路由与描述：SKILL.md 现为 7 条路由且空库初始化单列；design.md 的“7 条”“空库初始化单列”、description 三项覆盖（经验提炼／空库初始化／版本复查）、按需加载路径与日志入口均与现状一致。
- 计数抽查：PLAN 的 12 项工具调用（与 query.md 一致）、42 项工具箱检查（与 source-templates.md 一致）、六份隔离草稿、正式 56 页／9 导航、4,030 Lua／821 组件／3,209 其他（分项相加吻合）。
- 安装基线：`migration-local/s04-basic-20261014/package-manifest-initial.json` 恰为 25 个条目（含 `.gitignore`），与 host-basic.md 的“首次复制 25 个包文件”及 PLAN 的“25 个安装文件”一致；同目录 `package-manifest.json` 为 26 条，唯一新增是 host-basic.md 自身。保留的安装副本仍是 references 扁平化时期的布局，报告已注明任务前须同步实际包版本并重新登记。
- 跨仓：知识仓 `docs/design.md` 存在且记录跨仓关系（design.md:9 的引述成立）；工具箱 design.md 的“功能冻结”与 PLAN 一致。
- 报告入口：六份报告均可从 PLAN 到达；design.md 从 5 份可达，S04 句缺 host-basic.md 链接（见 D-2）。

## 发现

| 编号 | 位置 | 问题 | 建议 |
|---|---|---|---|
| D-1 | PLAN.md:59 | “SKILL.md 同步 6 条操作路由”与现状 7 条不一致（空库初始化已单列，design.md 也写 7 条）。作为当日交付记录本身无误，但作为计划内表述已过期 | 补“（空库初始化后单列，现为 7 条）”或改写为现行计数 |
| D-2 | docs/design.md:29 | S01／S02／S03 句均带对应报告链接，S04 句没有 host-basic.md 链接 | S04 句末补“，见宿主基础检视（`reports/host-basic.md`）” |
| D-3 | PLAN.md:3 | “最后更新：2026-10-15”未反映 10-16 的 S01 计数与链接修订 | 更新为 2026-10-16 |
| D-4 | README.md 目录结构 | 顶层 `.gitignore` 未列入（LICENSE 等均已列出，安装清单也包含它） | 可选补一行，或注明结构图只列主要条目 |

## 尚未验收

本轮只做文本与计数一致性核对；未评估 PLAN 待办项（S04 自主验收、S05 试建、两条维护流程与 S03-A 代表任务的隔离检视）本身的执行。历史报告的当时数字（first-use.md 的 14 项、安装基线 25 文件等）按其日期保留，未改写。

## 处理（2026-10-16）

- D-1：PLAN.md 的“同步 6 条操作路由”补注“（空库初始化后续单列，现为 7 条）”。
- D-2：docs/design.md 的 S04 句补上指向 host-basic.md 的链接。
- D-3：PLAN.md 头部“最后更新”更新为 2026-10-16。
- D-4：README 目录结构补 `.gitignore` 一行（本地缓存与个人配置忽略）。

复验：本包 30 份 Markdown 的相对链接与锚点检查 0 问题；`git diff --check` 干净。本次未改脚本、模板或哈希同步资源。

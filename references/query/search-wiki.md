# 可选 Wiki 查询工具

仅使用 Python 知识检索或章节读取时加载，沿用已读取的查询证据规则；无环境／缓存时直接用 `rg` 和 Markdown，不为查询安装依赖或重建索引。

K／T 已确认则复用，仅缺所需值时按 [路径约定](../setup/paths.md) 定位；Python 路径按实际环境调整，命令可以从任意工作目录调用：

```powershell
python "<T>/scripts/tools/wiki/query_wiki.py" --wiki-root "<K>/wiki" search SetMaxUses
python "<T>/scripts/tools/wiki/query_wiki.py" --wiki-root "<K>/wiki" search "工具耐久" "装备加速"
python "<T>/scripts/tools/wiki/query_wiki.py" --wiki-root "<K>/wiki" read "reference/components/finiteuses#典型接入"
```

`search` 在工具内读缓存、筛名称／路径、摘要／别名、章节标题和明确标识符／条件。需求分为少量子目标，各用一个带引号的参数；骨架与机制共用默认 **5 个候选、16,000 UTF-8 输出字节**（整份 JSON 含换行）。`--limit` 范围 1～50，在 search 后；默认仍用 5 个候选。`--max-bytes` 最小 2048，适用于 search/read，与 `--wiki-root`、`--build` 一样放在子命令前。摘要最多 200 字符，条件最多 3 条／每条 300 字符，省略／裁剪有标记，不能据摘要直接生成实现。

默认缓存为 `K/output/wiki/index.json`，可在 search 后用 `--index` 指定。返回路径／章节及行区间、页类型、显式条件、状态、核验版本／程度、页面级证据入口和匹配依据；`--path reference/components/`、`--type cookbook` 筛范围，`--history` 才包含归档页。中文双字关键词是轻量匹配，排序分数不是适用概率；`matched_goals` 仅表示词汇命中，`uncovered_goals` 仅表示未返回词汇候选，已命中仍须核对功能和前提。

缓存检查覆盖所用知识分类的页面与导航新增／删除／内容哈希变化；stale 拒用旧候选。仅用户明确指定版本过滤时追加 `--build "<编号体系:用户指定版本>"`；普通查询省略，不为填参数核对游戏最新版本。该参数只比较版本字符串，不证明游戏或知识是否最新。工具不核验源码行号／哈希或游戏行为，自动证据影响分析尚未实现。无命中／低覆盖／歧义／截断不是“没有实现”，缩小措辞、直查 Markdown 或定向查源码。

`read` 不依赖缓存，读取当前 Markdown，只输出 `path#anchor` 的真实行区间、元数据、适用条件／快速判断、父章节前提及验证记录／边界；最多 5 个目标共用字节预算，同页目标合并去重元数据和重叠区间。不自动跟读相关链接、其他案例或陷阱，需要时单独选其章节。超预算整项不返回并报告 omitted/truncated，保留代码完整性；状态信息也超预算时仍会报错，需缩小请求或显式增大预算。非索引页须有二级“验证记录”或“边界与验证”章节，否则报错并回读整页核对；索引页不要求验证章节，但目标锚点仍须存在。修改页面仍先读原页全文。

退出 0 表示工具已执行（仍可能无命中／截断），1 为 stale 拒用，2 为缺缓存／格式／路径／参数等工具错误。stale 或工具错误时优先回到当前 Markdown／必要源码；查询不自动重建，不把 next 字段的 rebuild 提示当重建授权。只有明确维护缓存时才读 [查询缓存重建](../maintain/maintain-index.md#可选查询缓存重建)。

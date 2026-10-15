# DST 工程专项校验

仅明确维护对应工程数据或工具时读取；普通查询、知识页／cookbook 写入不加载。复用已确认的 K／S／T，以下路径相对 T，只读命中行与其权威说明，再按脚本 --help 取参数；工具箱缺失时报告该能力不可用，不为普通知识任务安装环境。

| 触发范围 | 工具箱脚本 | 工具箱权威说明 |
|---|---|---|
| JSON reference bundle／契约数据 | `scripts/tools/verify/validate_examples.py` | `references/output-format.md`；不检查 Wiki Lua 示例 |
| 提取器／facts 人工基准 | `scripts/tools/verify/check_baselines.py` | `references/baselines.md` |
| 历史提取阶段投影复核 | `scripts/tools/verify/verify_extraction.py` | `references/baselines.md`；不代替完整基准 |
| 解析器／Lua 方言兼容 | `scripts/tools/verify/verify_parser.py` | `references/environment.md` |
| LuaCATS 既有正反例 | `scripts/tools/verify/verify_luacats.py` | `references/environment.md`；不泛化成任意 Wiki 示例类型检查 |
| lsp-dst pin／正式证据 | `scripts/tools/maintenance/maintain_lsp_dst.py check` | `references/lsp-dst.md`；不自动 setup／clone |

正式接口数据的采用要求只在工具箱 `references/verify-interfaces.md` 维护。工具／helper 测试仅在改动对应实现时，按各包工程入口执行；Wiki 缓存重建仍按[索引维护](maintain-index.md#可选查询缓存重建)，不混入只读检查。报告实际范围和未覆盖项，不以工程检查替代游戏运行或源码语义核验。

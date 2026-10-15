# 源码定义与反向引用查询

仅需使用可选源码索引时读取；普通源码兜底按已读取的查询规则直接定位。源码位于所选 scripts 根、可选工具位于 T；T 已确认则复用，尚未确认时才按 [路径约定](../setup/paths.md#t可选工具箱根) 定位。Python、工具或索引不可用时定向查源码，不为一次查询重建全量缓存。

## 查询已有索引

使用本次提供或此前确认的 facts／索引快照，至少有 manifest.json、coverage-report.json 与 source-index/；未知缓存位置则直接查源码，不扫描所有 output 或套用验收目录名。以下 `<facts快照根>` 和 `<所选scripts根>` 都须替换为实际绝对路径；只读取 manifest 的 snapshot／producer 等必要字段来确认版本与输入范围，索引 JSON 交给工具筛选，不能把整份 index 发给模型。

```powershell
python "<T>/scripts/tools/source/source_index.py" query definition Use --path components/finiteuses.lua --snapshot-root "<facts快照根>" --source-root "<所选scripts根>"
python "<T>/scripts/tools/source/source_index.py" query component finiteuses --kind component_access --snapshot-root "<facts快照根>" --source-root "<所选scripts根>"
```

| 类别 | 精确 key | 返回 |
|---|---|---|
| `definition` | 符号名或完整 symbol ID | 定义、owner、参数与原字节定位 |
| `call` | callee 原表达式；冒号调用用方法名 | 所属函数、receiver、全部参数与 guards |
| `target` | 完整 symbol ID | 调用／属性回调／别名／Prefab 工厂的候选引用及 resolution |
| `component` | 字面组件名或 `<dynamic>` | read／add／remove 的语法观察与条件 |
| `event` | 字面事件名或 `<dynamic>` | emit／listen；完整监听来源见同位置 call |
| `prefab` | 字面注册名或 `<dynamic>` | 注册与工厂引用；包装调用另查 call／target |

`--path` 精确筛来源文件，`--kind` 筛 symbol／record kind。默认最多 5 项、总计 16,000 输出字节；`--limit` 最大 20，`--max-bytes` 范围 1024～64000。长字段以 `{text,truncated,original_chars}` 报告展示截断；不能把截断文本当完整表达式。

## 结果与兜底

- 检查实际版本、覆盖 complete／partial／failed，以及 total／returned／ambiguous／truncated。语法观察与有限 resolution 不证明运行调用图或对象类型；仍需读实现和关键分支。
- 重名不自动选择；按 owner、路径与调用条件区分。无命中不能证明没有实现；缺口依据本次 coverage／failed_paths／截断状态定位，必要时查 `<dynamic>` 或定向源码，不沿用旧快照的固定失败文件名单。
- 工具重查来源与选中数据哈希；stale／损坏时停止使用候选，改查实际源码。查询期间源码变化时重新检查，不静默采用旧结果。
- LLM 只接收限量结果，再读取必要源码区间；不加载全份 index、facts 或 AST。退出 0 仍须检查 status／total／truncated，1 表示 stale 拒用，2 表示工具错误；先回到实际源码，不因查询失败安装环境。只有明确缓存维护任务才读工具箱的 `references/source-index.md`。

# 非组件模板检视

日期：2026-10-14。范围是模板／选择规则、代表源码结构和隔离草稿，未发布知识页；同作者共享上下文，不是独立模型评测、完整模组交付或游戏测试。独立评测继续按用户安排等待人工 review。

## 本轮交付

- 保留 component.md；新增 prefab.md 与 mechanism.md。Prefab 是原版工厂／组装入口，增加“注册与构造／关联机制导航”；其他主题沿用轻量布局，按需选择关键接口／数据约束或关键流程，不强造案例。
- source-types.md 提供选型表和 Prefab、SG、Brain／行为、API、UI、世界生成、数据的短差异；新建／重组才读所选模板和相关小节，查询、已有经验增修与 cookbook 不默认读。SKILL.md 原字节保持。
- 新增 mechanism → reference/mechanisms 归属，子主题按实际内容建立；公共接入仍归 API。格式／标签／大小保持单一来源，索引与两 Skill 查询规则同步；正式知识仓没有新增分类／空目录。
- 工具箱仅改类型分类和 CLI 筛选兼容；inventory／缓存／章节读取复用原实现。未改 AST、facts Schema、正式 reviews、helper 或个人配置。

## 代表源码观察

本轮只使用本地 raw/current，BUILD.txt 为 25643519，编号注明 steam-buildid；下表不是整模块行为审校。

| 类型 | 所查实现／必要宿主或消费者 | 对模板的要求 |
|---|---|---|
| Prefab | prefabs/icebox.lua:46 fn、:100 返回；standardcomponents.lua:842 MakeSnowCovered、:887 MakeLunarHailBuildup、:1554 AddHauntableDropItemOrWork；components/perishable.lua:60 Update、:81 fridge 分支 | 列共同／服务端分界、helper 间接组件、内容物标签消费，不能只统计 AddComponent 或只给泛化相关链接 |
| Prefab 变体 | prefabs/pigman.lua:310 SetNormalPig、:421 SetGuardPig、:512 SetWerePig、:830 moon 的 SetBrain／SetStateGraph，文件末尾返回 pigman／pigguard／moonpig | 注册名、工厂与运行时形态分开；此轮只用于差异选择，未建完整猪人关系草稿 |
| Replica | entityreplica.lua:9 登记 container、:34 ReplicateComponent、:75 ReplicateEntity；entityscript.lua:610 AddComponent、:631 复制；components/container_replica.lua:3 构造 | 实际注册／构造／消费者支撑关系；同名文件不直接证明可用 |
| API | modutil.lua:593 AddPrefabPostInit → mainfunctions.lua:362 构造、:368 回调；modutil.lua:431 环境分界 | 接口暴露与执行位置分别核验，记录 env、回调对象、端／阶段及追加语义 |
| SG／Brain | stategraphs/SGpig.lua:13 DROP handler、:265 dropitem、:276 时间线、:360 返回；brains/pigbrain.lua:333 day、:382 root、:420 BT；behaviours/follow.lua:76 Visit；behaviourtree.lua:582 PriorityNode.Visit；entityscript.lua:1078～1117 调度／安装 | 用状态／决策流程代替组件方法表；记录帧单位、优先级／节点状态、宿主和启动条件，不抄全图／全树 |
| UI | widgets/widget.lua:1 构造、:34 暂停调度、:124 OnControl、:300 AddChild、:325 Kill、:485 更新；widgets/controls.lua:55 构造与 AddChild 调用 | 说明 UI 对象／父节点、焦点、更新及销毁；不假定联网实体或前端有玩家 |
| 地图／数据 | map/layouts.lua:214 MushroomRingSmall、:1388 返回 → map/object_layout.lua:142 LayoutForDefinition；modutil.lua:298 AddTask、:302 AddRoom；mods.lua:443 前端加载 worldgen 入口 | 数据实例值与约束分开，追消费者，区分内部 local helper 与公开 API、生成／运行阶段；不强造方法或 worldgen demo |

Prefab 关联检查还确认 collapse_small 实际在 prefabs/structure_collapse_fx.lua:95 注册，不能从注册名直接猜同名文件；Asset 声明／使用位置不证明本轮检查了资源文件可用性。

## 隔离草稿与兼容检查

草稿及机器结果仅保存在开发区 migration-local/noncomponent-templates-20261014，不随 Skill 分发。复制正式 Wiki 与其定向链接的必要源码输入；正式 raw 只读。首次隔离检查缺少相对源码输入，补齐后再次运行；再次运行的重复登记由校验器拒绝，改为每次从原索引读取再插入，最终通过。未因此修改正式导航或放宽校验。

| 隔离主题 | 使用类型／布局 | 行数／UTF-8 字节 |
|---|---|---:|
| icebox 工厂与关联 | prefab 专用 | 57／3,758 |
| Prefab PostInit | api／通用机制，含 modmain 接入 | 51／1,989 |
| 猪人 DROP 执行 | stategraph／关键流程 | 42／1,693 |
| 猪人白天跟随 | mechanism／ai | 40／2,083 |
| Widget 父子／输入／清理 | mechanism／ui | 44／2,025 |
| layout 数据定义与读取 | mechanism／worldgen | 40／2,120 |

六份均通过生产格式下的元数据／标签、实际 sources 文件存在、大小、Wiki 链接、唯一登记与父级导航；名称直查和选定章节读取通过，未运行边界随章节返回。隔离库共 62 知识页、14 导航（原 56／9 加本轮草稿与实际导航），根 Top 30 未扩张；字节是体积记录，不换算 token。

工具箱执行 test_page.py（10 项）与 test_wiki.py（32 项），共 42 项通过；新增检查 mechanism 子主题登记／检索／错类拒用／stale，以及 Prefab 关系表不计跨分类叶级登记、章节读取不自动跟读关系目标。缓存格式不变，当前正式缓存未重建。

## 尚未验收

草稿只覆盖表内实际片段，SG／Brain 全链路动作与打断、新 UI 的数据同步、世界生成注册到产物及 runtime scenario 的任务级接入还未检视；没有完整新生物／HUD／worldgen 工程或游戏运行记录。多变体 Prefab 关系表超限拆分尚未用真实大页检视。

源码路径／数值行号检查只确认定位存在，行为仍按实际读到的实现／宿主判断；结构工具不证明语义。少量样本适用不代表所有非组件 Lua 文件已能可靠生成，规则短和章节读取通过也不证明 token 收益。详细后续工作留 PLAN 的 S03-A，基础宿主自主验收与正式扩库时序不变。

---
name: dst-wiki-skill
description: 查询《饥荒联机版》（DST）的骨架、机制 Wiki 与源码；从模组提炼通用经验，初始化共享知识库，生成、增修和审校共享知识及版本更新影响说明，按游戏版本或模组改动复查相关内容。适用于 DST 知识查询与共享知识库维护。
license: CC-BY-SA-4.0
metadata:
  author: YingSP
  version: "1.0.0"
  category: game-modding
---

# DST Wiki

本 Skill 独立负责共享知识查询与维护；模组开发由 `dst-mod-dev-skill` 处理，当前流程无需加载。所需 K／S／T 尚未确认时才读 [路径约定](references/setup/paths.md)，已确认值复用。链接是条件入口，仅在条件命中且所需信息尚缺时读取；已读且未变化则复用。普通查询和单页维护不读 README／PLAN 或工程历史。

| 意图 | 读取                                                           |
|---|----------------------------------------------------------------|
| 查询骨架、机制或源码 | [查询规则](references/query/query.md)                          |
| 初始化空知识库，仅建立导航 | [空库初始化](references/setup/first-use.md#明确新建空库)       |
| 生成／增修机制知识、案例或陷阱 | [知识维护](references/maintain/maintain-wiki.md#ingest)   |
| 从模组提炼通用经验 | [模组经验提炼](references/maintain/extract-mod.md)             |
| 增补共享 cookbook 骨架 | [骨架维护](references/maintain/maintain-skeleton.md)           |
| 游戏版本更新或模组改动后的知识复查 | [版本增量维护](references/maintain/maintain-version.md)        |
| 生成／增修／审校版本更新影响说明 | [更新报告](references/maintain/write-update.md)              |
| 判断模组是否需要为游戏版本更新适配 | [版本适配查询](references/query/read-update.md)                |
| 检查／整理知识页与索引 | [知识状态检查](references/maintain/maintain-wiki.md#lint) |

自然语言选择流程，不依赖已注册斜杠命令。规则、模板与轻量源码准备随目录分发；Wiki／源码由配置定位。Markdown 查询与增修不要求工具箱、Python、Rust、LuaLS 或 fork，不以安装工程环境或全量提取／索引为前提。

游戏源码与输入模组只读；共享知识只在用户要求维护时写入。模组开发和源码更新不自动触发增补或版本迁移。

需要设置或调整页面状态／验证等级时，按需读取 [证据与状态](references/maintain/maintain-wiki.md#证据与状态)；已读且未变化则复用。

用户明确指定 K／T，或要求保存／切换默认路径时，按 [保存配置](references/setup/first-use.md#保存配置) 检查是否需要保存；同会话相同路径的定位结果可复用，但用户明确要求保存或切换默认位置时，仍按该小节处理。

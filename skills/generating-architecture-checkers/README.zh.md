# 生成架构检查器

[English](./README.md) | 中文版

你可以在提示词或规则文件里把架构约定写得很清楚，但 AI Agent 在写代码时仍然可能违反它们——把 domain 和 infra 耦合、让依赖跨包蔓延、把文件放错位置。光靠文档约束不住 Agent，它需要一个能实际运行的检查：违反了就报错，报错了就能修。

这个技能从现有代码中推断架构规则，生成一条 Agent 每次改完代码就能跑的检查命令。一旦违反边界，Agent 立刻知道哪条规则出了问题、哪个文件需要修，当场就能改好。架构守护不再靠写文档和人工 review，而是变成一个可执行的自动反馈闭环。

详细实现说明请参阅 [SKILL.md](./SKILL.md)。

## 适用场景

- 需要为现有仓库生成架构检查
- 希望从现有代码推断规则，而非手工编写
- 需要强制执行文件布局、模块边界或依赖方向
- 关注误报率，倾向于基于 AST 的工具而非 grep

本技能**不适用于**手动架构评审、重构或自动修复违规、通用 lint / 格式化、运行时装配验证或部署拓扑。

## 工作流程

1. **检测** — 读取清单文件、工作区标记、已有 lint 配置和门禁集成
2. **推断** — 采样导入关系和目录结构，确定拓扑类型（包图、运行时图或混合）
3. **健康度检查** — 扫描常见反模式（循环依赖、层反转、枢纽耦合、边界侵蚀等）。发现问题时向用户报告并建议修正方向，按修正后的目标架构生成规则，已有违规记录为基线
4. **提问** — 仅在存在实质性歧义或反模式有多种修正方案时
5. **生成** — 按合适的执行级别产出清单、适配器、原生配置和入口
6. **验证** — 在移交前确认通过/失败/误报行为

## 产出物

生成的产物遵循三层模型：

1. **清单** (`architecture-rules.yaml`) — 将推断出的边界记录在一个可审查的文件中
2. **适配器** — 将清单转译为语言原生的工具配置、测试或检查代码
3. **入口** (`check-architecture`) — 一条命令即可运行检查，集成到仓库现有的门禁体系中

## 执行级别

| 级别 | 适用场景 | 产出内容 |
|------|---------|---------|
| Level 1 | 首次引入，无已有工具 | 清单 + 仓库本地适配器 + 门禁钩子 |
| Level 2 | 已有原生工具或添加成本极低 | 清单 + 原生工具配置/测试 |
| Level 3 | 特定规则需要符号级/内容分析 | Level 1 或 2 + 定向 AST 补充 |

## 支持的语言

| 语言 | 首选工具 | 回退方案 |
|------|---------|---------|
| JS/TS | dependency-cruiser, ESLint | ts-morph / TypeScript Compiler API |
| Python | import-linter | LibCST |
| Go | go/packages | go/ast |
| Java | ArchUnit | — |
| C# | NetArchTest | Roslyn |
| Dart | custom_lint + analyzer AST | — |
| Rust | cargo metadata | syn |

支持混合语言仓库 — 每种语言使用各自的原生工具，统一在一个入口下。

## 延伸阅读

- [SKILL.md](./SKILL.md) — 完整实现指令和参考文件索引
- [references/common-strategy.md](references/common-strategy.md) — 检测顺序、推断规则、决策矩阵
- [references/architecture-rules-format.md](references/architecture-rules-format.md) — 清单格式与编写指引
- [references/architecture-adapter-contract.md](references/architecture-adapter-contract.md) — 适配器翻译契约

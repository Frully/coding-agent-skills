# Operating Git Flow

中文 | [English](./README.md)

使用 AI agent 执行日常 Git Flow 工作流的指南。命令级操作说明见 [SKILL.md](./SKILL.md)。

## 什么是 Git Flow，为什么要用它

Git Flow 是一种分支模型，围绕两个常驻分支和三种临时工作分支来组织开发：

- **生产分支**（`main` 或 `master`）：始终反映最新的已发布代码
- **集成分支**（`develop`）：汇集已完成的功能，准备下一次发布
- **功能分支**（`feature/*`）：隔离地开发单个功能
- **发布分支**（`release/*`）：在正式发布前稳定一组功能
- **热修复分支**（`hotfix/*`）：直接基于生产代码进行紧急修复

这个模型为每个变更提供了清晰的生命周期——启动、开发、集成、发布——并明确规定了合并发生的时机和位置。它非常适合需要版本化发布、且生产分支必须随时保持稳定的项目。

## 前提条件

- 仓库必须已经初始化过 Git Flow（`git flow version` 可执行，且 `gitflow.branch.*` 配置存在）。如果还没有，请先使用 `initializing-git-flow` 技能。
- 在启动、发布或完成任何分支之前，工作区应保持干净。
- `finish` 操作默认应当是非交互式的。不要直接裸跑 `git flow ... finish`，应优先使用 `scripts/gitflow_finish_non_interactive.sh`，避免合并提交卡在编辑器里。

## 三种工作流概览

| 工作流 | 从哪个分支创建 | 合并到哪里 | 什么时候用 |
|--------|--------------|-----------|-----------|
| **功能** | `develop` | `develop` | 新功能或改进 |
| **发布** | `develop` | `main` + `develop` | 稳定并发布一个版本 |
| **热修复** | `main` | `main` + `develop` | 生产环境紧急修复 |

## 具体步骤：功能工作流

### 1. 在主工作区开始

确认你在集成分支（`develop`）上，且已拉取到最新。

### 2. 让 agent 创建功能分支

- `帮我创建一个叫 add-login 的功能分支。`

agent 会基于最新的 `develop` 创建 `feature/add-login`。

### 3. 在功能分支上开发

正常开发、提交代码。如果 `develop` 有更新，同步一下：

- `把 add-login 功能分支同步到 develop。`

### 4. 完成功能

功能完成后，有两种方式：

- **直接完成**：`完成 add-login 功能。`——agent 将它合并到 `develop`，删除功能分支并推送。
- **通过 PR**：`发布 add-login 并创建一个合并到 develop 的 PR。`——agent 推送分支并创建 PR。PR 合并后，agent 清理分支。

直接完成时，底层应优先使用 `scripts/gitflow_finish_non_interactive.sh --kind feature --name add-login`，而不是直接执行 `git flow feature finish add-login`。

## 具体步骤：发布工作流

### 1. 创建发布分支

在 `develop` 上，告诉 agent 你要创建发布：

- `创建一个新的发布分支。`——agent 会检查已有标签和版本历史，自动推断下一个版本号，并创建发布分支。
- 也可以手动指定版本：`创建 1.8.0 版本的发布分支。`

agent 会基于最新的 `develop` 创建 `release/<版本号>`。

### 2. 在发布分支上稳定

修复最后的问题、更新 changelog、调整版本号。只做发布相关的修改——新功能留到下一个版本。

### 3. 完成发布

- **直接完成**：`完成当前发布。`——agent 合并到 `main`、打标签（遵循配置的标签前缀）、回合到 `develop`、删除发布分支并推送。
- **通过 PR**：`发布当前版本并创建一个合并到 main 的 PR。`——PR 合并后，agent 创建标签，再创建一个回合到 `develop` 的 PR，然后清理分支。

直接完成发布时，安全默认命令应是 `scripts/gitflow_finish_non_interactive.sh --kind release --version <版本号> -- --message "Release <版本号>" --push`。

## 具体步骤：热修复工作流

### 1. 创建热修复分支

在 `main` 上，告诉 agent 你需要一个热修复：

- `创建一个热修复分支。`——agent 会根据已有标签自动确定版本号（通常是 patch 递增），并创建热修复分支。
- 也可以手动指定：`创建 1.8.1 版本的热修复分支。`

agent 会基于最新的 `main` 创建 `hotfix/<版本号>`。

### 2. 实施修复

做最小范围的修复。热修复应当精简——不要夹带功能开发。

### 3. 完成热修复

- **直接完成**：`完成当前热修复。`——agent 合并到 `main`、打标签、回合到 `develop`、删除热修复分支并推送。
- **通过 PR**：`发布当前热修复并创建一个合并到 main 的 PR。`——流程与发布 PR 相同。

直接完成热修复时，安全默认命令应是 `scripts/gitflow_finish_non_interactive.sh --kind hotfix --version <版本号> -- --message "Hotfix <版本号>" --push`。

## 版本和标签规则

agent 会从仓库历史中推断版本风格：

- **语义化版本**（`1.8.0`）：根据变更范围决定升级——`PATCH` 用于修复，`MINOR` 用于新功能，`MAJOR` 用于不兼容变更。
- **日期时间版本**（`20260326-1336`）：使用你的本地时区，并与已有标签保持格式一致。

标签始终遵循配置的 `gitflow.prefix.versiontag`（例如 `v`）。如果已有标签与配置前缀冲突，agent 会停下来询问，不会擅自创建。

## 最佳实践

- 不要直接在生产分支或集成分支上提交——始终使用功能、发布或热修复分支。
- 功能分支尽量短命。存在越久，合并越痛苦。
- 同一时间只开一个发布分支。上一个发布还没结束时不要开新的。
- 热修复应当精简。如果修复范围很大，考虑走正常发布流程。
- 合并后及时清理工作分支，保持分支列表干净。

## 延伸阅读

命令参数、纯 Git 回退方案和详细操作说明请参考 [SKILL.md](./SKILL.md)。

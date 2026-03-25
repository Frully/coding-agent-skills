# Dev Skills

This repository is a skill authoring kit for coding agents. It stores templates and authoring rules for reusable skills, but it is not itself a runtime install directory for Codex or Claude Code.

## What lives here

- `template/`: the canonical starter files for a new skill
- `spec/`: repository rules and skill authoring guidance
- `skills/`: reserved for real skills added later

## What does not live here

- Sample skills used only as examples
- Runtime-specific installation roots such as `.agents/skills` or `.claude/skills`
- Validation scripts or test harnesses for V1

## Repository layout

```text
.
├── README.md
├── skills/
├── spec/
│   ├── repository-layout.md
│   └── skill-authoring.md
└── template/
    ├── SKILL.md
    └── agents/
        └── openai.yaml
```

## Quick start

Agents working inside this repository should also read [`AGENTS.md`](./AGENTS.md).

1. Read [`spec/skill-authoring.md`](./spec/skill-authoring.md).
2. Copy `template/` into a new skill directory.
3. Fill in `SKILL.md` first.
4. Add `agents/openai.yaml` only if the skill needs Codex-specific metadata.
5. Install or sync the finished skill into the runtime-specific location described in [`spec/repository-layout.md`](./spec/repository-layout.md).

## Design principles

- Use `SKILL.md` as the single source of truth.
- Keep each skill focused on one workflow.
- Prefer concise instructions over heavy scaffolding.
- Use progressive disclosure: keep `SKILL.md` short, then split large details into optional files.
- Treat agent-specific files as extensions, not the main format.

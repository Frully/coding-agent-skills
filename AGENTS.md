# AGENTS

This file tells an agent how to create new skills in this repository.

## Goal

When asked to add a new skill, create a real skill under `skills/<slug>/` using the repository template and authoring rules.

This repository is a source repository for skill definitions. It is not a runtime install directory.

## Create-skill workflow

1. Read [`spec/skill-authoring.md`](./spec/skill-authoring.md).
2. Choose a focused workflow for the skill. Do not combine unrelated jobs into one skill.
3. Create a new directory at `skills/<slug>/`.
4. Start from [`template/SKILL.md`](./template/SKILL.md).
5. Fill in the YAML frontmatter first:
   - `name`
   - `description`
6. Write the body sections in this order unless there is a strong reason not to:
   - `Overview`
   - `When to use`
   - `When not to use`
   - `Instructions`
   - `Examples`
   - `Additional files`
7. Add optional directories only when the skill actually needs them:
   - `references/`
   - `scripts/`
   - `assets/`
8. Add [`template/agents/openai.yaml`](./template/agents/openai.yaml) to `skills/<slug>/agents/openai.yaml` for every skill. It is required for Codex compatibility, but it must remain secondary to `SKILL.md` and must not redefine the core workflow.

## Required output

Every new skill must include:

- `skills/<slug>/SKILL.md`
- `skills/<slug>/agents/openai.yaml`

`SKILL.md` is the primary source of truth. Do not create `skill.yaml` or any parallel primary manifest.

## Naming rules

- Use kebab-case for the directory name.
- Use kebab-case for the `name` field.
- Use short, action-oriented, workflow-style names that read naturally as a callable skill or command.
- Prefer gerund or task-command style names, such as `writing-documentation`, `fixing-build-failures`, or `migrate-component`.
- Do not use broad domain-only or topic-only names such as `git`, `documentation`, or `frontend`.
- Keep the name aligned to one focused workflow, not a bundle of unrelated tasks.
- Keep the skill narrow and specific.

## Writing rules

- Make `description` specific about both capability and trigger conditions.
- Use direct, imperative instructions.
- State required inputs, expected outputs, sequence, and boundaries.
- Prefer workflows that work with portable shell commands and plain text instructions.
- Avoid making a skill depend on environment-specific runtimes or tools such as Python, Node.js, or agent-local package managers unless the dependency is essential to the workflow.
- If a non-portable dependency is truly required, mention it in `SKILL.md`, keep it optional when possible, and put detailed rationale or fallback guidance in referenced additional files when needed.
- Include non-goals when they help prevent accidental overreach.
- Prefer short input/output examples over long explanations.
- Keep `SKILL.md` concise and execution-oriented.

## Progressive disclosure

Keep the shortest useful version of the skill in `SKILL.md`.

Only add side files when needed:

- `references/` for long supporting material
- `scripts/` for deterministic execution
- `assets/` for templates or static resources
- `agents/openai.yaml` for required Codex metadata

Do not create empty optional directories beyond the required `agents/` directory for Codex compatibility.

## Compatibility rules

- Shared skill behavior must live in `SKILL.md`.
- Every skill must be compatible with both CODEX and Claude Code through the shared `SKILL.md`.
- Core workflow instructions must rely on portable tools and text instructions, not agent-specific UI, orchestration, or metadata files.
- Shared workflow instructions should not assume language runtimes such as Python or Node.js are available unless that requirement is central to the skill and clearly documented.
- Every skill must include `agents/openai.yaml` for Codex compatibility.
- Codex-specific metadata belongs in `agents/openai.yaml`.
- Agent-specific extensions must remain optional and must not replace or redefine the shared instructions.

## Non-goals

When creating a new skill, do not:

- add sample or fake skills for illustration
- add `tests/` or validation tooling unless explicitly requested
- turn the root of this repository into a runtime skill directory
- split the core skill definition across multiple required files

## Placement note

This repository stores authored skills under `skills/`.

Runtime environments typically load skills from other locations:

- Codex: `.agents/skills`
- Claude Code: `.claude/skills`
- Claude plugins: plugin-local `skills/`

Use [`spec/repository-layout.md`](./spec/repository-layout.md) if the task involves packaging or syncing a skill into a runtime location.

# Skill Authoring

This document defines the long-lived authoring contract for skills in this repository.

If you are an agent creating a new skill right now, start with [`../AGENTS.md`](../AGENTS.md). That file describes the creation workflow. This document explains the durable rules behind it.

## Core contract

Each skill must include these files:

- `SKILL.md`
- `agents/openai.yaml`

That file must begin with YAML frontmatter containing:

- `name`
- `description`

`SKILL.md` is still the primary manifest and source of truth. Do not introduce `skill.yaml`, `README.md`, or another parallel file as a required primary manifest.

## Skill shape

A skill should cover one focused workflow. Prefer multiple narrow skills over one large skill that mixes unrelated tasks.

The shared, cross-agent behavior belongs in `SKILL.md`. `agents/openai.yaml` is required in this repository for Codex compatibility, but it must remain secondary.

## Naming contract

- Use kebab-case for `skills/<slug>/`.
- Use kebab-case for the `name` field.
- Prefer short, action-oriented names.
- Favor workflow-style naming, often with a gerund, such as `writing-documentation`.

## Description contract

`description` is used for discovery and triggering. It should state both:

- what the skill does
- when the skill should be used

Good:

```yaml
name: writing-documentation
description: Draft or revise technical documentation when the task is to explain code, APIs, workflows, or engineering decisions.
```

Bad:

```yaml
name: docs
description: Helps with documentation.
```

## Recommended body structure

Unless there is a strong reason otherwise, organize `SKILL.md` in this order:

1. `Overview`
2. `When to use`
3. `When not to use`
4. `Instructions`
5. `Examples`
6. `Additional files`

This structure aligns with the repository template and keeps discovery, boundaries, execution, and examples easy to scan.

## Writing rules

- Keep the skill execution-oriented.
- Use direct, imperative instructions.
- State inputs, outputs, order, and constraints explicitly.
- Prefer portable shell commands and plain text instructions over environment-specific tooling.
- Do not make Python, Node.js, or similar language runtimes a default dependency unless they are essential to the workflow being encoded.
- If a non-portable dependency is unavoidable, mention it in `SKILL.md`, keep it optional when practical, and place detailed rationale or fallback guidance in referenced additional files when needed.
- Add non-goals when they reduce accidental overreach.
- Prefer examples that demonstrate successful execution instead of explanatory prose.

Prefer:

- "Inspect the existing API before proposing schema changes."
- "Return a concise migration plan with risks and tests."

Avoid:

- "Help with APIs."
- "Do the right thing."

## Progressive disclosure

Keep the shortest useful version of the skill in `SKILL.md`.

Only add side files when they materially improve the skill:

- `references/` for long supporting material
- `scripts/` for deterministic execution
- `assets/` for templates or static resources

Do not create optional directories by default. Add them only when the skill needs them. The `agents/` directory is the exception because every skill must include `agents/openai.yaml`.

## Agent compatibility

- Claude and Codex should share the same `SKILL.md`.
- Every skill must include `agents/openai.yaml` for Codex compatibility.
- Codex-specific metadata belongs in `agents/openai.yaml`.
- Agent-specific extensions must not replace the shared instructions.
- Shared instructions should assume only broadly available tools unless the skill's core purpose requires a specific runtime or platform dependency.

If a skill behaves differently across agents, keep the shared workflow in `SKILL.md` and isolate only the agent-specific metadata or policy.

## When to add scripts

Add a script only when the task needs deterministic execution, repeatable local tooling, or a command sequence that is easy to get wrong.

Prefer portable scripts or commands that do not assume Python, Node.js, or a language-specific toolchain is installed. If the workflow truly requires such a runtime, make the dependency explicit and explain why plain text instructions are not sufficient.

Do not add scripts just to restate instructions in code.

## Repository constraints

Within this repository:

- `skills/` is reserved for real skills
- `template/` contains the canonical starter files
- `spec/` contains repository rules

V1 does not require:

- sample skills
- tests
- validation tooling

## Review checklist

Before considering a skill complete, confirm:

- `name` is stable and kebab-case
- `description` is specific about capability and trigger
- `SKILL.md` stands on its own
- `agents/openai.yaml` exists and stays secondary to `SKILL.md`
- optional files are referenced from `SKILL.md`
- the skill covers one workflow
- examples show expected use
- environment-specific dependencies are avoided or explicitly justified
- Codex-only metadata is isolated in `agents/openai.yaml`

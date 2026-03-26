# Repository Layout

This repository is a source and distribution workspace for skills. It is not the same thing as the runtime directories that Codex or Claude Code scan.

## Purpose of this repository

Use this repository to:

- author skill templates
- document authoring rules
- keep reusable skill source folders under version control

Do not assume agents will automatically discover skills from this repository root.

## Runtime locations

Typical runtime locations are:

- Codex: `.agents/skills`
- Claude Code: `.claude/skills`
- Claude Code plugins: plugin-local `skills/`

Those paths are runtime install locations. This repository is the source from which those locations can be populated.

## Recommended flow

1. Author or update a skill here.
2. Keep shared instructions in `SKILL.md`.
3. Add `agents/openai.yaml` for every skill so the authored skill stays Codex-compatible.
4. Copy or sync the finished skill into the appropriate runtime directory.

## Layout used in this repository

```text
.
├── README.md
├── skills/
├── spec/
└── template/
```

- `skills/` is reserved for real skills that may be added later.
- `template/` contains the canonical starter files.
- `spec/` explains how to author and place skills.

## Non-goals for V1

V1 does not include:

- sample skills
- runtime installation automation
- validation scripts
- tests

Those can be added later once the authoring contract is stable.

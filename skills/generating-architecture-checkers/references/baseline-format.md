# Baseline Format

Use this file when the chosen `architecture-rules.yaml` manifest sets `baseline.mode` to anything other than `off`.

## Baseline path rules

- `baseline.path` is resolved from the repository root unless `baseline.resolve_from` explicitly says otherwise.
- For this skill, default `baseline.resolve_from` to `repo-root`.
- Keep baseline files machine-generated and stable across runs.

## Default JSON shape

Use this structure unless the repository already has a stronger established baseline format:

```json
{
  "version": 1,
  "generated_from": "tools/architecture/architecture-rules.yaml",
  "identity_fields": [
    "rule_id",
    "kind",
    "member",
    "source",
    "target",
    "edge",
    "symbol"
  ],
  "violations": [
    {
      "rule_id": "example-rule",
      "kind": "dependency",
      "member": "frontend",
      "source": "frontend/src/features/a.ts",
      "target": "frontend/src/platform/b.ts",
      "edge": "import",
      "symbol": ""
    }
  ]
}
```

## Identity rules

Normalize violation identity before comparing:

- store paths relative to the repository root
- keep path separators stable
- use empty strings for identity fields that do not apply
- keep `rule_id` and `kind` exactly as declared by the manifest

Use this identity tuple in order:

1. `rule_id`
2. `kind`
3. `member`
4. `source`
5. `target`
6. `edge`
7. `symbol`

## `block-new` comparison

For `baseline.mode: block-new`:

- compute the normalized identity tuple for every current violation
- compute the normalized identity tuple for every baseline violation
- allow a violation only if its identity already exists in the baseline
- fail the command on any current violation whose identity is missing from the baseline

Do not compare by free-form message text.

## Maintenance rules

- regenerate the baseline only when the user explicitly accepts the new snapshot
- keep the baseline small and reviewable
- record broad structural changes in the final report when they require a baseline refresh
- store `generated_from` as the repo-relative path to the actual manifest location, not just the file name

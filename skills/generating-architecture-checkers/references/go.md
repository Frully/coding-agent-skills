# Go

## Preferred implementation order

1. Build package and module understanding with `go/packages`.
2. Inspect syntax with `go/ast` when package boundaries alone are not enough.
3. Generate a small repo-local checker when needed.

Prefer Go-native analysis over shell parsing.

## Detection checklist

Read:

- `go.mod`
- `go.work` if present
- package layout under services, internal, pkg, cmd, or domain folders
- any existing analyzer or test packages

Look for:

- `internal/` boundaries
- module or workspace split
- service packages versus shared libraries
- repeated dependency direction between domain, service, transport, and persistence packages

## Rule strategy

Use `go/packages` for:

- import graph construction
- package visibility and module resolution
- workspace member boundaries

Use `go/ast` when:

- package name alone is insufficient
- file placement rules depend on declarations or build tags
- generated adapters need to be excluded precisely

## Monorepo notes

For `go.work` or multi-module repos:

- infer module boundaries first
- treat each module as a public contract unless the repository clearly centralizes ownership
- keep module-level rules separate from package-level rules

## False-positive controls

- ignore generated protobuf or mock packages
- separate `_test.go` dependencies from production rules
- respect `internal/` and build-tag conventions before adding custom restrictions

## Output hints

Typical generated artifacts:

- `architecture-rules.yaml`
- a repo-local Go adapter or checker under a tooling directory
- a `go run` or task-runner entrypoint surfaced as `check-architecture`

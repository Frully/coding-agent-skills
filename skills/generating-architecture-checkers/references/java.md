# Java

## Preferred implementation order

1. Use `ArchUnit` tests as the default enforcement mechanism.
2. Add supporting reflection or build configuration only when `ArchUnit` alone cannot locate the right modules.

Prefer architecture tests over custom text scanners.

## Detection checklist

Read:

- `pom.xml` or `build.gradle*`
- multi-module build settings
- package naming and source-set layout
- existing test suites and any architecture tests

Look for:

- layered packages such as `domain`, `application`, `infrastructure`, `web`
- module boundaries in Maven or Gradle
- framework patterns from Spring or similar stacks

## Rule strategy

Use `ArchUnit` for:

- layer rules by package
- forbidden dependencies between modules
- naming and location rules for adapters, controllers, repositories, and services

Add helper code only when:

- package scanning needs explicit module discovery
- the repository has mixed source sets that require custom inclusion logic

## Monorepo notes

For multi-module builds:

- infer module boundaries before package layers
- generate shared base helpers only if several modules enforce the same rule shape
- avoid central tests that obscure which module is violating the rule

## False-positive controls

- scope rules to production classes unless test architecture is explicitly in scope
- exclude generated sources and annotation-processor outputs
- align package matching with the real build graph

## Output hints

Typical generated artifacts:

- `architecture-rules.yaml`
- a manifest-driven helper that emits or loads `ArchUnit` assertions
- `ArchUnit` test classes in the appropriate test source set
- a Gradle or Maven entrypoint documented as `check-architecture`

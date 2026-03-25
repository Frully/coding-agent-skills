---
name: implementing-smoke-tests
description: Implement or extend smoke tests based on a repository's web, API, or mobile stack, existing test tooling, and baseline user flows when the goal is fast regression coverage for core paths.
---

# Implementing Smoke Tests

## Overview

Use this skill to add or tighten a small smoke-test lane that proves the product still works at a baseline level.

- inspect the repository before choosing tools or test scope
- prefer the existing test runner when one already covers the target layer
- support common web, API, iOS, Android, and Flutter smoke-test paths
- keep smoke coverage narrow, stable, and fast enough for routine CI
- require smoke output that is useful for both humans and downstream AI analysis
- optimize for the highest possible signal-to-noise ratio in smoke output
- return implemented tests, a dedicated smoke command, CI wiring, and any intentional coverage gaps

## When to use

Use this skill when:

- the user asks to add smoke tests for a web app, HTTP API, iOS app, Android app, or Flutter app
- the repository has tests, but no fast baseline lane for pull requests or deploy checks
- the current E2E suite is too broad or slow and needs a smaller smoke subset
- a team needs confidence that core entry, read, and write flows still work after changes

## When not to use

Do not use this skill when:

- the task is to design a full end-to-end strategy or deep regression suite
- the main goal is load, stress, performance, or resilience testing
- the task is browser compatibility, device matrix, accessibility certification, or visual regression
- the product is a desktop app, game engine project, embedded system, or another stack outside common web, API, iOS, Android, and Flutter workflows
- the repository cannot support automated smoke tests yet because basic app startup or test environment setup is still broken

## Instructions

### 1. Inventory the repository first

Inspect the existing project before proposing or writing tests.

Collect at least:

- application type: browser app, API service, native mobile app, Flutter app, or mixed surfaces
- primary language and package manager
- existing test runners, helpers, fixtures, and CI workflows
- authentication pattern and whether login can be created programmatically
- test data setup and reset options
- the smallest set of business-critical baseline flows

Check the repository instead of guessing. Prefer portable inspection commands such as:

```bash
rg --files
rg -n "playwright|cypress|pytest|vitest|jest|mocha|ava|xctest|xcuitest|espresso|uiautomator|integration_test|github/workflows|circleci|gitlab-ci"
```

### 2. Choose one implementation route

Prefer reuse over introducing another overlapping test framework.

- If the repository already uses Playwright or Cypress for browser tests, extend that runner with a smoke lane.
- If the repository is a JS or TS web app with no browser automation, default to Playwright.
- If the repository is a Python API and already uses `pytest`, add a `smoke` marker-based lane there.
- If the repository is a Node API and already uses `vitest` or `jest`, add a smoke lane there with file naming or test-name filtering.
- If the repository is an iOS app, prefer the existing `XCTest` and `XCUITest` targets for smoke coverage.
- If the repository is an Android app, prefer existing instrumented UI tests with Espresso and use UI Automator only when the flow crosses app or system boundaries.
- If the repository is a Flutter app, prefer the existing `integration_test` path for smoke coverage.
- If the repository uses an unfamiliar or unsupported stack, stop short of installing a new toolchain and return a concrete implementation plan grounded in the existing setup.

Use [`references/stack-selection.md`](./references/stack-selection.md) for the selection matrix and fallback rules.

### 3. Reduce scope to the baseline path

Keep smoke coverage to three through seven flows. Pick the minimum set that proves the system still works.

Prioritize:

- app startup, homepage reachability, or API health
- app cold launch and first interactive screen for mobile apps
- login or the main anonymous entry path
- one critical read flow
- one critical write or state-changing flow
- one post-change verification step
- one permission or failure-path check only when it is genuinely baseline-critical

Do not turn smoke tests into a thin copy of the full regression suite.

### 4. Implement for speed and stability

Enforce these defaults when writing tests:

- make each test independent and runnable in isolation
- prefer programmatic login, fixtures, or seed APIs over long UI setup
- reset state in setup hooks or fixtures, not in teardown
- mock or stub third-party dependencies when the boundary is outside the system under test
- assert on user-visible behavior for browser and mobile flows
- use stable locators such as roles, accessibility ids, explicit test ids, or deliberate text contracts
- keep retries, waits, and timeouts conservative so smoke failures stay actionable

### 5. Add a dedicated smoke entrypoint

The repository must be able to run only the smoke lane.

- Playwright: use tags or a dedicated project
- Cypress: use a dedicated smoke spec path or a `--spec` based script
- pytest: register a `smoke` marker and run with `-m smoke`
- Vitest or Jest: use file naming or test-name filtering for smoke runs
- XCUITest: use a smoke test plan, dedicated scheme, or focused test target selection
- Android Espresso or UI Automator: use a smoke instrumentation package, class filter, or Gradle task wrapper
- Flutter `integration_test`: use a smoke naming convention, target selection, or dedicated test command

Expose the lane through the repository's normal command surface, such as a package script, make target, or CI command.

Use [`references/runner-recipes.md`](./references/runner-recipes.md) for runner-specific patterns.

### 6. Wire smoke into CI without making it heavy

Add or update CI so smoke runs on the team's baseline integration path.

Default expectations:

- run smoke on pull requests, commits, or the repository's existing pre-merge path
- use one primary browser and one environment unless the repository already requires more
- use one primary simulator, emulator, or device target for mobile unless the repository already requires a matrix
- keep dependencies minimal and avoid booting optional subsystems
- preserve traces, screenshots, or logs only on failure

### 7. Emit AI-friendly smoke output

Do not stop at a plain console transcript. The smoke lane should produce output that helps an AI diagnose failures and suggest the next action.

Require these defaults where the runner makes them practical:

- emit one machine-readable result format such as JUnit XML or JSON in addition to human-readable console output
- identify each test failure with a stable test name, flow name, file path, and failure stage
- include one direct repro command for the failed test or smoke subset
- preserve artifact paths for screenshots, traces, videos, or logs when a failure occurs
- keep the console summary short and list covered, failed, and skipped flows before raw logs
- strip non-actionable noise from default output and avoid dumping verbose framework logs unless they are needed for diagnosis
- normalize obvious failure categories when possible, such as startup, auth, locator, assertion, backend, or test-data failures

Use [`references/ai-friendly-output.md`](./references/ai-friendly-output.md) for the output contract and summary shape.

### 8. Return the implemented result clearly

When the work is complete, return:

- which runner and selection strategy was chosen
- which baseline flows are covered
- the smoke command
- the CI entrypoint that runs it
- how the smoke lane exposes machine-readable results and failure artifacts
- any important flows intentionally left out of smoke coverage

## Examples

Input: "This Next.js app has unit tests but no browser coverage. Add smoke tests for login and dashboard."

Output:

```text
Choose Playwright as the browser runner, add a smoke-tagged login and dashboard path, expose `pnpm test:smoke`, and wire that command into the PR workflow.
```

Input: "We already use Cypress, but our full suite takes 20 minutes. Add a quick smoke lane."

Output:

```text
Reuse Cypress, move three baseline specs into a smoke path, expose a `cypress run --spec ...` smoke command, and keep the full suite unchanged.
```

Input: "This FastAPI service already uses pytest. We only need a deployment smoke check."

Output:

```text
Add `@pytest.mark.smoke` to the health, auth, and one write-path test, register the marker, and run them with `pytest -m smoke`.
```

Input: "This iOS app already has UI tests. Add a deploy-gate smoke lane."

Output:

```text
Reuse the existing XCUITest target, keep startup, login, and one purchase-safe read flow in a smoke-only test plan, and expose it through a dedicated `xcodebuild test` command in CI.
```

## Additional files

- [`references/stack-selection.md`](./references/stack-selection.md): runner selection rules, reuse policy, and fallback guidance
- [`references/ai-friendly-output.md`](./references/ai-friendly-output.md): output contract for machine-readable summaries, failure metadata, repro commands, and artifacts
- [`references/runner-recipes.md`](./references/runner-recipes.md): compact runner-specific implementation recipes for Playwright, Cypress, pytest, Vitest, Jest, XCTest, Espresso, UI Automator, and Flutter integration tests

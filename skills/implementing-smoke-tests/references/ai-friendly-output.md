# AI-Friendly Output

Use this file when implementing or refining the smoke lane's output contract.

## Goal

Make smoke results easy for both humans and AI to consume.
Optimize for the highest possible signal-to-noise ratio. The default smoke output should contain almost no non-actionable text.

A good smoke run should answer:

- what baseline flows were exercised
- which flow failed
- where it failed
- how to rerun it
- which artifacts contain the best evidence

## Required output shape

Produce both:

- a short human-readable summary in console output
- one machine-readable result file, preferably JUnit XML or JSON

Do not treat raw framework output as the primary result. Raw logs are supporting evidence only.

The machine-readable result should include, directly or through stable fields that can be derived:

- overall status
- runner name
- smoke command
- environment or target name
- browser, simulator, emulator, or device target when applicable
- commit, branch, or build identifier when available
- covered flows
- failed flows
- skipped flows

For each failure, include:

- stable test id or test name
- flow name
- failure stage such as `startup`, `auth`, `read-flow`, `write-flow`, or `post-change-check`
- source file path when the runner exposes it
- concise failure message
- normalized failure category when it can be inferred
- direct repro command
- artifact paths

## Preferred failure categories

Normalize to a small set when practical:

- `app-not-starting`
- `auth-failed`
- `locator-missing`
- `assertion-failed`
- `backend-unavailable`
- `test-data-invalid`
- `device-or-emulator-failed`

If precise normalization is not reliable, keep the raw failure and omit the category instead of inventing one.

## Console summary contract

Keep the console summary compact and ordered:

1. overall status
2. runner and environment
3. covered flows
4. failed and skipped flows
5. repro commands
6. artifact paths

Only then print raw logs or stack traces.

## Noise reduction rules

Aim to reduce noise as close to zero as the runner allows.

- do not print passing step-by-step action logs in the default summary
- do not print full stack traces for every failure when a concise failure summary and artifact path are available
- do not mix infrastructure logs, dependency install logs, or app boot chatter into the smoke summary
- collapse repeated failures into one normalized summary entry plus a count when possible
- prefer one clear failure line per failed flow over dozens of low-level assertion echoes
- keep raw logs behind expandable CI sections, separate files, or artifacts when the platform supports it
- if a piece of output does not help identify the failed flow, reproduce it, or inspect evidence, exclude it from the default summary

## Artifact expectations

On failure, preserve at least one high-value artifact where the runner supports it:

- screenshot
- trace
- video
- app log
- network log
- test report path

Artifact paths must be explicit so a follow-up agent can inspect them without guessing.

## Example JSON summary

```json
{
  "status": "failed",
  "runner": "playwright",
  "smoke_command": "pnpm test:smoke",
  "environment": {
    "target": "staging",
    "browser_or_device": "chromium",
    "commit": "abc123"
  },
  "covered_flows": [
    "startup",
    "login",
    "dashboard-read",
    "profile-update"
  ],
  "failed_flows": [
    "login"
  ],
  "skipped_flows": [],
  "failures": [
    {
      "id": "smoke-login",
      "flow": "login",
      "stage": "auth",
      "file": "tests/smoke/login.spec.ts",
      "message": "Post-login redirect missing",
      "category": "auth-failed",
      "repro_command": "pnpm playwright test tests/smoke/login.spec.ts --grep @smoke",
      "artifacts": [
        "artifacts/screenshots/login-failure.png",
        "artifacts/traces/login-failure.zip"
      ]
    }
  ]
}
```

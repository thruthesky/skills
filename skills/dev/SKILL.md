---
name: dev
description: Structured spec-driven development workflow for projects that use a `.dev/` workspace. Use when the user wants to document existing code as reusable reference material, list `.dev` work items, write an implementation plan into `.dev/<name>/plan.md`, implement code strictly from that plan, create a refactor plan, or run an adversarial review that updates `.dev/<name>/plan.md`. Keywords: .dev folder, dev workflow, copy existing code, plan feature, execute plan, refactor analysis, adversarial review.
---

# Dev

This skill ports the existing `dev` workflow to Codex.

Use it when the project follows a `.dev/`-based process:

- `copy`: analyze an existing codebase, module, file, URL, or concept and write reusable reference docs into `.dev/<name>/`
- `list`: inspect the `.dev/` workspace and summarize document status
- `plan`: write a detailed implementation spec into `.dev/<name>/plan.md`
- `execute`: implement code from `.dev/<name>/plan.md`
- `refactor`: analyze current code and write a refactor plan
- `review`: perform an adversarial review and feed critical findings back into `.dev/<name>/plan.md`

## First Rule

Before using any workflow, check whether `.dev/DEV.md` exists.

- If it exists, read it first.
- Treat `.dev/DEV.md` as project-specific instructions that override the default workflow guidance.

## Routing

Read only the command doc that matches the user request:

- For documenting existing code or patterns: `commands/copy.md`
- For listing `.dev` status: `commands/list.md`
- For writing a new implementation spec: `commands/plan.md`
- For implementing from a saved spec: `commands/execute.md`
- For refactor analysis only: `commands/refactor.md`
- For adversarial review and plan reinforcement: `commands/review.md`

## Operating Model

The workflow centers on a `.dev/` directory that stores reusable references, plans, progress tracking, and reviews. Prefer this skill when the user wants work to be traceable and spec-driven instead of ad hoc.

Common artifact layout:

```text
.dev/
├── DEV.md
├── <feature-a>/
│   ├── README.md
│   ├── plan.md
│   ├── progress.md
│   ├── review.md
│   └── refactor-plan.md
└── <feature-b>/
```

## Practical Guidance

- Keep `SKILL.md` high-level and use the command docs for the exact workflow.
- Preserve the existing `dev` semantics as much as possible when translating requests.
- When a user refers to `/dev:copy`, `/dev:plan`, `/dev:execute`, `/dev:list`, `/dev:refactor`, or `/dev:review`, treat that as an explicit request to load the corresponding command doc.
- When a request matches one of those workflows but does not use slash-command syntax, route it the same way.

## Output Expectations

- `copy`, `plan`, `refactor`, and `review` should write structured files under `.dev/<name>/`.
- `execute` should implement code and update `.dev/<name>/progress.md` when the command guidance calls for it.
- `review` should not stop at critique; it should update the plan when the workflow requires that.

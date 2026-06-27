# Harness Adoption Contract

This document is a working base for a future dash-skogai decision, spec, schema, and implementation checklist. It describes what the harness is, what another repository must provide to use it, and what the harness must be able to assume when it plans and executes work there.

It is intentionally written as a portable contract rather than an install guide. The exact CLI names, config paths, and dashboard implementation can evolve; the expectations between a repository and the harness should stay stable.

## What This Is

The harness is a human-controlled AI work system for turning intent into auditable task execution.

At the center is a loop:

```text
intent -> spec -> task graph -> assigned agents -> execution -> proof -> review -> next intent
```

The harness does not replace the repository's engineering process. It gives that process a structured surface:

- A spec becomes a set of tasks with dependencies.
- Tasks are assigned to suitable agents or humans.
- Agents execute in the repository with project-local instructions.
- Progress, questions, and proof are posted back to the task board.
- The human reviews the work and decides what becomes durable.

For this to work across repositories, each repository needs to expose enough local truth for an agent to operate without guessing: how to understand the project, how to run checks, how to communicate, how to prove work, and how to avoid stepping outside the intended boundaries.

## Goals

- Make any harness-enabled repository understandable to an agent starting from disk.
- Keep project-specific truth in the target repository, not hidden in chat history.
- Let the harness create plans and task graphs from durable specs.
- Give agents a standard way to ask questions, post progress, and submit proof.
- Make completed work reviewable through task-board evidence, logs, tests, and git.
- Provide enough structure for schema validation without forcing every repository to use the same stack.

## Non-Goals

- This is not a replacement for project READMEs, contribution guides, or security policies.
- This is not a universal coding standard.
- This is not a promise that every repository must use the same AI providers.
- This is not a mandate that every task must be automated; human tasks remain first-class.

## Core Concepts

### Harness

The orchestration layer that plans work, creates tasks, assigns agents, runs tasks, records execution, and synchronizes with the board.

In this repo, Odin is the orchestration CLI and TaskIt is the board and audit surface.

### Target Repository

The repository where work is being planned or executed. It owns its source code, local instructions, validation commands, security boundaries, and project-specific definitions of done.

### Spec

A durable expression of intent. A spec should explain the desired outcome, constraints, acceptance criteria, and relevant context. The harness can turn it into a task graph, but the spec remains the source of original intent.

### Task

A unit of work with a title, description, assignee, status, dependencies, and proof. Planning, implementation, testing, review, assembly, and documentation can all be tasks.

### Task Graph

The dependency graph produced from a spec. Independent tasks can run in parallel; dependent tasks wait for upstream tasks to reach the required state.

### Proof

The evidence attached to a task that lets a human or downstream agent understand what was done and how to verify it. Proof can include changed files, test commands, screenshots, logs, commit hashes, PR links, and handoff notes.

## Repository Obligations

A repository is harness-ready when it provides the following surfaces.

### 1. Routing Instructions

The repository must have a clear entrypoint for agents. This can be an `AGENTS.md`, `CLAUDE.md`, `SKOGAI.md`, `HARNESS.md`, or another agreed routing document, but the harness must be able to identify the canonical file.

The routing document should answer:

- What is this repository?
- Which files or directories matter first?
- Which commands are safe to run?
- Which commands mutate state?
- What should agents never do?
- Where are deeper module-specific instructions?
- What is the correct test and verification ladder?

Recommended direction for dash-skogai alignment: use caps routing files with frontmatter and structured sections where possible, and avoid duplicating full instructions across several files.

### 2. Project Metadata

The repository should expose enough metadata for the harness to identify and classify it.

Minimum fields for a future schema:

```yaml
project:
  name: string
  kind: string
  default_branch: string
  package_managers: string[]
  primary_languages: string[]
  owner: string | null
```

Useful optional fields:

```yaml
project:
  repo_url: string
  worktree_policy: string
  deployment_targets: string[]
  issue_tracker: string | null
  docs_entrypoints: string[]
```

### 3. Validation Contract

The repository must describe how to verify work.

At minimum, it should distinguish:

- Fast local sanity checks.
- Focused tests for a changed area.
- Full test or CI-equivalent checks.
- Commands that are unsafe, slow, flaky, destructive, networked, or credential-dependent.

Recommended schema shape:

```yaml
validation:
  fast:
    - name: string
      command: string
      cwd: string
      mutates: boolean
  full:
    - name: string
      command: string
      cwd: string
      mutates: boolean
  notes: string[]
```

The harness can only enforce "proof of work" if it knows what proof is meaningful in the target repo.

### 4. Spec Location and Format

The repository should define where specs live and what fields are expected.

Recommended minimum:

- Intent or problem statement.
- Requirements.
- Acceptance criteria.
- Constraints and non-goals.
- Verification expectations.
- Human decisions still needed.

Specs can be Markdown, YAML-frontmatter Markdown, issue bodies, or generated story packets. The important part is that they are durable and can be referenced from tasks.

### 5. Task Board Mapping

The repository should declare how harness tasks map to project work.

Questions to answer:

- Does this repo use TaskIt as the live board?
- Are GitHub issues, Linear issues, or local files also authoritative?
- Which statuses are allowed?
- When is a task considered ready for review?
- When is it considered done?

Recommended generic lifecycle:

```text
backlog -> todo -> in_progress -> executing -> review -> done
                                      \-> failed
```

The exact status names can vary, but the repository should not leave lifecycle semantics implicit.

### 6. Agent and Provider Policy

The repository should define which agents are allowed and what they may do.

Minimum policy:

- Allowed agent providers.
- Required model or capability constraints for planning, coding, review, and simple edits.
- Whether agents may install dependencies.
- Whether agents may access the network.
- Whether agents may write outside the repository.
- Whether agents may create branches, worktrees, commits, or PRs.

This policy should be suggestive by default: the harness can recommend the cheapest capable agent, while the human can override.

### 7. MCP and Communication Contract

The repository should support a communication channel from running agents back to the board.

Expected agent actions:

- Post a status update when starting meaningful work.
- Post milestone updates during long tasks.
- Ask blocking questions instead of guessing on material ambiguity.
- Submit proof before claiming the task is complete.

Expected comment types:

```yaml
comments:
  status_update: progress visible to humans
  question: blocks until a human answers
  proof: verification and handoff evidence
  debug: low-level execution traces, hidden by default where possible
```

The implementation may use TaskIt MCP, another MCP server, or a compatible bridge. The contract is the behavior, not the transport.

### 8. Git and Isolation Policy

The repository should say how agent work is isolated and reviewed.

Minimum policy:

- Default branch.
- Whether agents may commit.
- Branch naming convention.
- Worktree location, if worktrees are used.
- Whether one branch represents a spec, task, or both.
- PR creation and merge expectations.
- Rules for failed attempts and retries.

Recommended future direction:

```text
spec branch: odin/<spec_id>
task branch: odin/<spec_id>/<task_id>
worktree: .odin/worktrees/<task_id>
```

The human remains responsible for merging to the protected branch.

### 9. Secrets and Safety Boundaries

The repository must make safety boundaries explicit.

Minimum guidance:

- Where secrets may be read from.
- Which files must never be printed or copied into task output.
- Whether external network calls are allowed.
- Whether deployment commands are allowed.
- Whether destructive database, cloud, or filesystem commands require human approval.

The harness should treat missing safety guidance as a reason to ask, not a reason to proceed.

### 10. Proof of Work Definition

The repository should define what a completed task must include.

Minimum proof package:

- Summary of what changed.
- Files or artifacts changed.
- Verification commands run and their results.
- Known risks, limitations, or skipped checks.
- Handoff notes for reviewers or downstream tasks.

For UI work, proof should usually include a screenshot or browser verification. For API work, it should include tests or request examples. For docs work, it should include links to changed files and any schema or lint checks.

## Harness Obligations

If a repository provides the contract above, the harness should:

- Discover the canonical routing document before planning or executing.
- Preserve the original spec and link all derived tasks back to it.
- Represent dependencies explicitly as a graph.
- Suggest agents based on capability, cost, and policy.
- Let the human review and override the plan before execution.
- Pass project-local instructions and task context to each agent.
- Configure the communication channel for each running task.
- Record progress, questions, proof, logs, duration, cost, and final status.
- Keep derived status computed from tasks where possible.
- Respect repo safety and git isolation policy.
- Stop and ask when required metadata or safety rules are missing.

## Minimal Harness-Ready Repository

A minimal repository should contain or expose:

```text
README.md
AGENTS.md or HARNESS.md or SKOGAI.md
specs/ or plans/stories/
.odin/config.yaml or equivalent harness config
.mcp.json / .codex/config.toml / provider-specific MCP config as needed
health or validation command documented in routing instructions
```

The exact files may vary. The invariant is that an agent can start from the repository root, find the canonical instructions, understand the work, run the correct checks, communicate with the board, and submit proof.

## Candidate Schema Sections

The future dash-skogai schema can likely be split into these sections:

```yaml
harnessContract:
  version: string
  project: {}
  routing: {}
  specs: {}
  taskLifecycle: {}
  validation: {}
  agents: {}
  communication: {}
  git: {}
  safety: {}
  proof: {}
```

Each section should have a small required core and richer optional fields. The schema should validate that the repository is operable, not force every repository into the same implementation details.

## Candidate Decision

Decision title:

```text
Harness-enabled repositories expose a portable adoption contract
```

Decision summary:

```text
Repositories that want to use the harness must publish a small, machine-checkable contract covering routing, specs, task lifecycle, validation, agent policy, MCP communication, git isolation, safety, and proof of work. dash-skogai owns the canonical decision and schema. Individual repositories own their local values.
```

Decision consequences:

- Repositories become easier for agents to enter without chat history.
- The harness can validate readiness before planning or execution.
- Missing instructions become explicit blockers instead of hidden assumptions.
- dash-skogai can define the portable contract while each repo keeps local autonomy.
- Existing repos can adopt the contract gradually by filling the required core first.

## Open Questions

- Which filename should be canonical for the portable contract: `HARNESS.md`, `SKOGAI.md`, frontmatter in `AGENTS.md`, or a machine file such as `.harness/contract.yaml`?
- Should the schema validate Markdown routing documents directly, a separate YAML/JSON file, or both?
- Which task lifecycle fields are universal, and which belong to TaskIt only?
- How strict should validation be for repos that only want planning but not execution?
- Should git isolation be mandatory for code-writing tasks or only recommended until the worktree flow is fully implemented?
- How should reusable global policies from dash-skogai layer with repo-local overrides?

## Next Artifacts

This README should feed four follow-up artifacts in dash-skogai:

- A typed decision that accepts the portable adoption contract.
- A schema for the contract fields and required sections.
- A spec/story packet for implementing readiness validation.
- A migration guide for existing repositories that want harness support.


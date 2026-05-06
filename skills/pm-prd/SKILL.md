---
name: pm-prd
description: Generate, revise, or approve a PRD for a software feature — from RFC/grooming/kickoff sources or from scratch via guided intake
argument-hint: <feature-slug>
allowed-tools: [Read, Write, Edit, Glob, Bash]
version: 1.2.0
---

# PM — PRD Pipeline

Feature: $ARGUMENTS

---

## Hard Rules (apply every time)

1. **Never fabricate.** Every requirement traces to a source document or a recorded intake answer. Missing values → blank + flag in §10 Open Items.
2. **Confirm before writing.** Present draft summary, wait for approval before writing the file.
3. **Source citations mandatory.** Every FR/NFR/AC carries `[RFC-XXX §N]`, `[Grooming YYYY-MM-DD]`, `[Kickoff YYYY-MM-DD]`, or `[Intake YYYY-MM-DD]` (for scratch PRDs).
4. **Language preservation.** Thai/English/mixed source content is verbatim. Agent commentary in English.
5. **Pipeline gates.** Sources/Intake → PRD → Review → Breakdown. Never skip. Never auto-promote.
6. **PRD versioning.** Every change bumps version + adds Changelog row. Approved PRDs are not silently regenerated.

---

## Gitflow Management

All PRD file writes go through a feature branch → MR/PR → `develop`. QA tests PM artifacts on `develop`. The `develop` → `main` merge is a separate PM gate — the agent never triggers it.

Read `GIT_PROVIDER` from `.env` (default: `gitlab`). See `knowledge/git-provider.md` for auth headers and endpoint formats.

**Confirm with user before every `push` and MR/PR creation.**

### Branch setup — run once per session, before first write
```bash
git status                               # must be clean
git checkout develop && git pull origin develop
git checkout -b prd/<feature-slug>       # if exists: git checkout prd/<feature-slug>
```

### After every file write (new draft or revision)
```bash
git add prd/<feature-slug>.md
git commit -m "prd(<feature-slug>): <draft|revise> v<version> — <brief change>"
git push origin prd/<feature-slug>
```

### On first push — create MR/PR targeting `develop` (confirm first)

**GitLab:**
```
POST /projects/:id/merge_requests
{
  "source_branch": "prd/<feature-slug>",
  "target_branch": "develop",
  "title": "PRD: <Feature Name> — v<version> review",
  "description": "File: `prd/<feature-slug>.md`\nVersion: <version>\nFeature Owner: @<owner>\n\nReview using `.gitlab/merge_request_templates/prd-review.md`.",
  "remove_source_branch": true
}
```

**GitHub:**
```
POST /repos/:owner/:repo/pulls
{
  "head": "prd/<feature-slug>",
  "base": "develop",
  "title": "PRD: <Feature Name> — v<version> review",
  "body": "File: `prd/<feature-slug>.md`\nVersion: <version>\nFeature Owner: @<owner>\n\nReview using `.github/pull_request_template.md`."
}
```

Report MR/PR URL to user.

### On PRD approval (version 1.0, status approved)
```bash
git add prd/<feature-slug>.md
git commit -m "prd(<feature-slug>): approve v1.0"
git push origin prd/<feature-slug>
```
Remind user: "PRD v1.0 pushed to branch. Merge the MR/PR into `develop` so QA can validate. After QA sign-off, `develop` → `main` locks the PRD."
**Do NOT merge the MR/PR yourself** — merge is the team's explicit approval gate.

---

## PRD Pipeline — Four Stages

### Stage 1 — Generate PRD

**Trigger:** "Generate PRD for <feature>", "Draft PRD from <files>", "PRD from scratch", or argument provided.

#### Path A — From source documents (RFC / grooming / kickoff available)

Steps:
1. Scan `rfc/`, `grooming/`, `kickoff/` and propose matching files for the feature slug. Confirm with user.
2. Read all confirmed source files in full.
3. Draft PRD using the template below.
4. Every requirement has an inline source citation.
5. Append Source Coverage appendix mapping every FR/NFR/AC to its source.
6. Append §10 Open Items for anything unresolvable from sources.
7. Set frontmatter: `version: 0.1`, `status: draft`, `last_updated: <today>`, `sources: [<files>]`.
8. Present draft summary → wait for approval → write to `prd/<feature-slug>.md`.

#### Path B — From scratch (no source documents)

Use this path when: no RFC/grooming/kickoff files exist, or user explicitly says "from scratch" / "no documents".

**Step 1 — Intake interview.** Ask the following questions one group at a time. Wait for answers before proceeding to the next group. Do not generate the PRD until all required questions are answered.

**Group 1 — Identity**
- (Required) What is the feature name?
- (Required) Who is the feature owner?
- (Required) What problem does this feature solve? (background & motivation)

**Group 2 — Scope**
- (Required) What are the goals — what does success look like?
- (Required) What is explicitly out of scope / non-goals?
- (Required) Who are the target users or personas?

**Group 3 — Requirements**
- (Required) List the core things the system must do (functional requirements). Bullet points are fine.
- (Optional) Any performance, security, or compliance constraints?
- (Optional) Describe the main user flows or journeys (UX/UI flows).

**Group 4 — Validation**
- (Required) How will you know this feature is done? (acceptance criteria, even rough)
- (Optional) Any dependencies — other teams, services, or features this relies on?
- (Optional) Any open questions or decisions still pending?

**Step 2 — Confirm intake.** After all groups answered, present a structured summary of all answers. Ask user to confirm or correct before writing the PRD.

**Step 3 — Draft PRD.** Use the template below. Cite every FR/NFR/AC as `[Intake <today's date>]`. Set frontmatter `sources: []`.

**Step 4 — Write.** Present draft summary → wait for approval → write to `prd/<feature-slug>.md`.

### Stage 2 — Revise PRD

**Trigger:** "Revise PRD §4", "Update FR-2", "Change the overview".

On every revision:
- Bump draft version: `0.1 → 0.2 → 0.3 …`
- Add Changelog row: date, author, what changed
- Keep `status: draft`

**Approval trigger:** "PRD approved" / "Lock PRD" / "Finalize PRD"
- Set `version: 1.0`, `status: approved`
- Add Changelog row: `v1.0 — Approved by <user>`
- File is now locked (no silent regeneration)

**Drift detection:** If a source RFC/grooming/kickoff was modified after PRD approval, flag on next read:
> "RFC-022 was modified <date>, after PRD v1.0 approved <date> — review for drift?"

Post-approval edits: propose `v1.1` draft. Approved version stays locked until new version is itself approved.

### Stage 3 — Propose Breakdown

**Trigger:** "Break down the PRD", "Generate working items" — handed off to `/pm-breakdown`.

Read the **approved** PRD only. Do NOT re-read RFC/grooming/kickoff at this stage.

### Stage 4 — Apply Breakdown

**Trigger:** "Apply the breakdown", "Create issues" — handled by `/pm-breakdown`.

---

## PRD Template

```markdown
---
title: <Feature Name>
prd_id: PRD-<feature-slug>
version: 0.1
status: draft
feature_owner: <name>
last_updated: <YYYY-MM-DD>
sources:                        # list source files, or [] for scratch PRDs
  - rfc/KUB-RFC-XXX_<slug>.md
  - grooming/YYYY-MM-DD-<feature>.md
  - kickoff/YYYY-MM-DD-kickoff-<feature>.md
---

# <Feature Name> — PRD

## Changelog
| Version | Date       | Author        | Changes                                          |
|---------|------------|---------------|--------------------------------------------------|
| 0.1     | YYYY-MM-DD | Agent (draft) | Initial draft synthesized from sources / intake |

## 1. Overview
Background and motivation. [RFC-XXX §3]

## 2. Goals & Non-Goals
**Goals**
- ...

**Non-Goals**
- ...

## 3. User Stories / Personas
- As a <persona>, I want <action>, so that <outcome>. [Source]

## 4. Functional Requirements
1. **FR-1** — <requirement>. [RFC-XXX §6]
2. **FR-2** — ...

## 5. Non-Functional Requirements
Performance, security, compliance. Each with source citation.

## 6. UX / UI Flows
- **Flow 1: <name>** — steps 1..N, including error/edge cases. [Source]

## 7. Acceptance Criteria
- AC-1 (covers FR-1): Given <X>, when <Y>, then <Z>.

## 8. Dependencies
External services, other features, other teams.

## 9. Out of Scope
Explicit non-goals (often from RFC §10).

## 10. Open Items / Needs Input
Unresolved questions. Must be empty before approval.

## 11. References
- RFC: rfc/KUB-RFC-XXX_<slug>.md          ← omit if scratch
- Grooming: grooming/YYYY-MM-DD-<feature>.md  ← omit if scratch
- Kickoff: kickoff/YYYY-MM-DD-kickoff-<feature>.md  ← omit if scratch
- Intake: YYYY-MM-DD (from scratch session)  ← include if scratch

## Appendix A — Source Coverage
| Requirement | Source location               |
|-------------|-------------------------------|
| FR-1        | RFC-XXX §6                    |
| AC-1        | Grooming YYYY-MM-DD — Q#10    |
```

---

## Source Document Reading Guide

| Document | Extract |
|---|---|
| RFC | Problem statement, decisions, constraints, proposed approach, key flows, out of scope, risks → FRs, NFRs, dependencies |
| Grooming notes | Open questions, decisions, pending items → resolves Open Items, action items become tasks |
| Kickoff notes | Scope, owner assignments, timeline, ACs from PO → §2 Goals, §7 AC, §8 Dependencies |

Conflict: Grooming/kickoff overrides RFC. If unresolvable → §10 Open Items, flag to PO.

---
name: pm-prd
description: Generate, revise, or approve a PRD for a software feature from RFC, grooming, and kickoff source documents
argument-hint: <feature-slug>
allowed-tools: [Read, Write, Edit, Glob]
version: 1.0.0
---

# PM — PRD Pipeline

Feature: $ARGUMENTS

---

## Hard Rules (apply every time)

1. **Never fabricate.** Every requirement traces to a source document. Missing values → blank + flag in §10 Open Items.
2. **Confirm before writing.** Present draft summary, wait for approval before writing the file.
3. **Source citations mandatory.** Every FR/NFR/AC carries `[RFC-XXX §N]`, `[Grooming YYYY-MM-DD]`, or `[Kickoff YYYY-MM-DD]`.
4. **Language preservation.** Thai/English/mixed source content is verbatim. Agent commentary in English.
5. **Pipeline gates.** Sources → PRD → Review → Breakdown. Never skip. Never auto-promote.
6. **PRD versioning.** Every change bumps version + adds Changelog row. Approved PRDs are not silently regenerated.

---

## PRD Pipeline — Four Stages

### Stage 1 — Generate PRD

**Trigger:** "Generate PRD for <feature>", "Draft PRD from <files>", or argument provided.

Steps:
1. Scan `rfc/`, `grooming/`, `kickoff/` and propose matching files for the feature slug. Confirm with user.
2. Read all confirmed source files in full.
3. Draft PRD using the template below.
4. Every requirement has an inline source citation.
5. Append Source Coverage appendix mapping every FR/NFR/AC to its source.
6. Append §10 Open Items for anything unresolvable from sources.
7. Set frontmatter: `version: 0.1`, `status: draft`, `last_updated: <today>`.
8. Present draft summary → wait for approval → write to `prd/<feature-slug>.md`.

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

**Trigger:** "Apply the breakdown", "Create GitLab issues" — handled by `/pm-breakdown`.

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
sources:
  - rfc/KUB-RFC-XXX_<slug>.md
  - grooming/YYYY-MM-DD-<feature>.md
  - kickoff/YYYY-MM-DD-kickoff-<feature>.md
---

# <Feature Name> — PRD

## Changelog
| Version | Date       | Author        | Changes                                |
|---------|------------|---------------|----------------------------------------|
| 0.1     | YYYY-MM-DD | Agent (draft) | Initial draft synthesized from sources |

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
- RFC: rfc/KUB-RFC-XXX_<slug>.md
- Grooming: grooming/YYYY-MM-DD-<feature>.md
- Kickoff: kickoff/YYYY-MM-DD-kickoff-<feature>.md

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

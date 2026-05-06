---
title: PRD Template Reference
description: Summary of the PRD structure and pipeline stages used by pm-prd skill
source: skills/pm-prd/SKILL.md
---

# PRD Template Reference

## Frontmatter

```yaml
---
title: <Feature Name>
prd_id: PRD-<feature-slug>
version: 0.1
status: draft           # draft | approved
feature_owner: <name>
last_updated: <YYYY-MM-DD>
sources:                # list source files; use [] for scratch (intake) PRDs
  - rfc/KUB-RFC-XXX_<slug>.md
  - grooming/YYYY-MM-DD-<feature>.md
  - kickoff/YYYY-MM-DD-kickoff-<feature>.md
---
```

## Sections

| # | Section | Content |
|---|---------|---------|
| — | Changelog | Version, date, author, changes table. Updated on every revision. |
| 1 | Overview | Background and motivation. Cite RFC. |
| 2 | Goals & Non-Goals | Bulleted goals and explicit non-goals. |
| 3 | User Stories / Personas | "As a \<persona\>, I want \<action\>, so that \<outcome\>." with source citation. |
| 4 | Functional Requirements | FR-1, FR-2, … each with inline source citation. |
| 5 | Non-Functional Requirements | Performance, security, compliance — each cited. |
| 6 | UX / UI Flows | Named flows with step-by-step descriptions including edge cases. |
| 7 | Acceptance Criteria | AC-N (covers FR-N): Given / When / Then format. |
| 8 | Dependencies | External services, other features, other teams. |
| 9 | Out of Scope | Explicit exclusions (often from RFC). |
| 10 | Open Items / Needs Input | Unresolved questions — must be empty before approval. |
| 11 | References | Links to RFC, grooming, kickoff source files. |
| A | Appendix: Source Coverage | Table mapping FR/AC to source location. |

## Versioning Rules

- Start at `0.1` (draft). Increment `0.1 → 0.2 → 0.3` on each revision.
- Set `1.0` + `status: approved` only on explicit approval trigger.
- Every change adds a Changelog row.
- Post-approval edits create a `1.1` draft; `1.0` stays locked until new version is approved.

## Source Priority

| Source | Extracts |
|--------|----------|
| RFC | Problem, decisions, constraints, approach, flows, out-of-scope, risks |
| Grooming notes | Open questions, decisions, action items |
| Kickoff notes | Scope, owners, timeline, ACs from PO |
| Intake interview | All sections — used when no RFC/grooming/kickoff exists (scratch PRD) |

**Conflict rule:** Grooming/kickoff overrides RFC. If unresolvable → §10 Open Items.

## Citation Format

Every FR, NFR, and AC must carry an inline source citation:
- `[RFC-XXX §N]` — from RFC document
- `[Grooming YYYY-MM-DD]` — from grooming notes
- `[Kickoff YYYY-MM-DD]` — from kickoff notes
- `[Intake YYYY-MM-DD]` — from scratch intake interview (no source documents)

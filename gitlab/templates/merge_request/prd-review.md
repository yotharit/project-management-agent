<!--
  PRD Review Merge Request Template
  Deploy to: .gitlab/merge_request_templates/prd-review.md in your GitLab repo

  Source branch : prd/<feature-slug>
  Target branch : main
  Assignee      : Feature Owner
-->

## PRD: <!-- Feature Name -->

**File:** `prd/<feature-slug>.md`
**Version:** <!-- current draft version, e.g. 0.3 -->
**Feature Owner:** @<!-- username -->
**Reviewers:** @<!-- reviewer1 --> @<!-- reviewer2 -->

---

## Review Checklist

The author completes every box before merging.
GitLab Free has no enforced approval rules — this checklist is the gate.

### Source coverage
- [ ] Every FR/NFR/AC has an inline citation (`[RFC-XXX §N]`, `[Grooming YYYY-MM-DD]`, `[Kickoff YYYY-MM-DD]`)
- [ ] Appendix A (Source Coverage table) maps every FR/NFR/AC to its source location
- [ ] §10 Open Items is empty, or all items explicitly deferred with a named owner and due date

### Content
- [ ] §1 Overview accurately states the problem (cites RFC §3 problem statement)
- [ ] §2 Goals & Non-Goals are explicit and agreed with PO
- [ ] §3 User Stories cover all relevant personas
- [ ] §4 Functional Requirements are numbered, sourced, and testable
- [ ] §5 Non-Functional Requirements include performance, security, compliance where applicable
- [ ] §6 UX/UI Flows cover happy path AND error/edge cases
- [ ] §7 Acceptance Criteria are in Given/When/Then format, one per FR
- [ ] §8 Dependencies list external services, other features, and other teams
- [ ] §9 Out of Scope matches RFC §10 (or is explicitly expanded/narrowed with rationale)

### Process
- [ ] No content was invented — every statement traces to a source document
- [ ] Source-language content (Thai/English/mixed) is preserved verbatim
- [ ] Changelog table has an entry for this draft version

---

## Reviewer Notes

<!-- Reviewers leave inline comments on the diff. Summarise any blocking issues here: -->

---

## On Merge — Agent Actions

After this MR is merged to `main`, the agent will:
1. Set `version: 1.0`, `status: approved` in PRD frontmatter
2. Add Changelog row: `v1.0 — Approved — merged by <merger> on <YYYY-MM-DD>`
3. Treat the PRD as locked (§6a) — no silent regeneration

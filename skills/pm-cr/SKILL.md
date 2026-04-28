---
name: pm-cr
description: Log, assess, approve, and apply a Change Request (CR) against an existing feature or approved PRD
argument-hint: <feature-slug> [cr-title]
allowed-tools: [Read, Write, Edit, Glob]
version: 1.0.0
---

# PM — Change Request (CR) Workflow

Feature / CR: $ARGUMENTS

---

## Hard Rules (apply every time)

1. **Never fabricate.** CR description, requester, and affected sections must come from the user or the current PRD. Never invent impact.
2. **Confirm before writing.** Show CR YAML and proposed changes — wait for approval at each stage.
3. **Source citations mandatory.** If the CR modifies PRD requirements, each modified/new FR carries a citation: `[CR-<id> YYYY-MM-DD]`.
4. **Language preservation.** Thai/English/mixed content verbatim.
5. **Pipeline gates.** Log → Impact Assessment → Approval → Apply. Never skip. Never auto-apply a rejected CR.
6. **PRD versioning.** A CR that changes the PRD triggers a minor version bump (`v1.0 → v1.1`). The approved PRD version remains locked until the new version is itself approved.
7. **WI status is a rollup.** New CR Working Items start as `Status: Todo`. Status derives from child Tasks — never set directly.

---

## CR Lifecycle — Four Stages

```
Log CR → Impact Assessment → CR Approval → Apply
```

---

## Stage 1 — Log a CR

**Trigger:** "Log a CR", "Open a change request for <feature>", "Stakeholder wants to change <X>"

Collect from user:
1. Title — what is being requested
2. Affected feature / PRD (`prd/<feature-slug>.md`)
3. Description — what change and why (stakeholder's words verbatim)
4. Requested by — name / team
5. Priority — High / Medium / Low / Un-priority
6. Requested date (defaults to today)

Generate CR YAML and save to `cr/<feature-slug>-<NNN>.yaml` (NNN = sequential per feature, e.g. `001`):

```yaml
cr:
  id: CR-<feature-slug>-001
  title: ""
  requested_by: ""
  requested_date: YYYY-MM-DD
  priority: ""
  status: draft              # draft | under-review | approved | rejected | implemented
  affected_prd: prd/<feature-slug>.md
  affected_prd_version: ""   # fill from PRD frontmatter
  description: |
    <verbatim description from requester>
  impact:
    prd_change_needed: false  # true = PRD revision required
    affected_sections: []     # e.g. ["§4 FR-3", "§6 Flow 2"]
    new_frs: []               # new FRs to add if PRD changes
    modified_frs: []          # existing FR numbers to modify
    new_working_items: []     # new GitLab issues regardless of PRD change
    timeline_impact: ""
    notes: ""
  decision:
    status: ""                # approved | rejected | deferred
    by: ""
    date: ""
    reason: ""
  gitlab_issues: []           # filled after Apply stage
```

Present draft to user. Proceed to Stage 2.

---

## Stage 2 — Impact Assessment

**Trigger:** After CR is logged, or "Assess CR <id>", "What's the impact of this CR?"

Steps:
1. Read the affected PRD (`prd/<feature-slug>.md`).
2. Identify which sections / FRs / ACs are affected by the requested change.
3. Determine:
   - Does the PRD text need to change? → set `prd_change_needed: true`
   - Which sections are affected? → fill `affected_sections`
   - Are new FRs needed? → fill `new_frs`
   - Which existing FRs need modifying? → fill `modified_frs`
   - Are new Working Items needed (even without a PRD change)? → fill `new_working_items`
   - What is the timeline / scope impact? → fill `timeline_impact`
4. Update the YAML impact block.
5. Present completed impact assessment to user.

Set `status: under-review`.

---

## Stage 3 — CR Approval

**Trigger:** "Approve CR <id>", "Reject CR <id>", "Defer CR <id>"

**Approved:**
- Set `decision.status: approved`, `decision.by: <user>`, `decision.date: <today>`
- Set `status: approved`
- Proceed to Stage 4

**Rejected:**
- Set `decision.status: rejected`, fill `decision.reason`
- Set `status: rejected`
- If any GitLab issues exist for this CR: update their labels to `Status: Declined`
- No further action

**Deferred:**
- Set `decision.status: deferred`, fill `decision.reason` (e.g. target release)
- Set `status: draft` — revisit in future sprint

---

## Stage 4 — Apply CR

**Trigger:** "Apply CR <id>", after approval.

Two paths based on `impact.prd_change_needed`:

### Path A — PRD change required

1. Invoke PRD revision workflow (same as `/pm-prd` Stage 2):
   - Read current approved PRD
   - Apply modifications for each item in `modified_frs` and `new_frs`
   - Cite each change: `[CR-<id> YYYY-MM-DD]`
   - Bump PRD to next minor version (`v1.0 → v1.1`)
   - Add Changelog row: `v1.1 — CR-<id>: <title>`
   - Present diff for user approval before writing
   - On approval: write updated PRD, set `status: draft` until re-approved
2. After PRD is re-approved: run `/pm-breakdown` for any new Working Items in `new_working_items`.

### Path B — No PRD change, new items only

Create GitLab issues directly:

```
POST /projects/:id/issues
{
  "title":       "<working_item.name>",
  "description": "CR: <cr.id> — <cr.title>\nRequested by: <cr.requested_by>\n\n<working_item description>\n\nSource: cr/<feature>-<NNN>.yaml",
  "labels":      "Kind: Working Item,Group: <group>,Priority: <priority>,Type: CR,Platform: <platform>,Status: Todo",
  "milestone_id": <id>
}
```

For both paths:
- Store returned `iid`s in `cr.gitlab_issues`
- Set `status: implemented`
- Update YAML file

---

## CR YAML — field reference

| Field | Values | Notes |
|---|---|---|
| `status` | `draft` / `under-review` / `approved` / `rejected` / `implemented` | Overall CR lifecycle |
| `prd_change_needed` | `true` / `false` | Drives Path A vs Path B in Stage 4 |
| `affected_sections` | e.g. `["§4 FR-3"]` | PRD sections impacted |
| `new_frs` | List of FR descriptions | Added to PRD if Path A |
| `modified_frs` | List of FR numbers + new text | Modified in PRD if Path A |
| `new_working_items` | List with name, group, platform | Always created as GitLab issues |
| `decision.status` | `approved` / `rejected` / `deferred` | Final decision |
| `gitlab_issues` | List of `#<iid>` | Filled after Apply |

---

## Identity & Config Resolution (run once per session)

1. Read `.env` at project root — parse as `KEY=value` text lines (not shell env). Extract `GITLAB_USERNAME`, `GITLAB_BASE_URL`, `GITLAB_PROJECT_ID`, `GITLAB_TOKEN`.
2. Read `team.yaml` → find the member where `gitlab_username` matches. Use `display_name` and `role` for this session. `display_name` becomes the default `requested_by` and `decision.by`.
3. If `.env` is missing or `GITLAB_USERNAME` is blank → ask once. Suggest copying `.env.example` to `.env`.
4. **Self-registration:** If user is not found in `team.yaml` → ask for `display_name` and `role`. Append to `team.yaml`, show diff, confirm before writing.
5. Role updates happen only on explicit command. Never infer from behavior.
6. Never repeat identity resolution in the same session.

## GitLab API — Config

Values are read from `.env` (see Identity & Config Resolution above).

---

## CR vs other types

| Situation | Type to use |
|---|---|
| New feature, no existing PRD | `Feature` → `/pm-prd` + `/pm-breakdown` |
| Something is broken | `BUG` → `/pm-bug` |
| Stakeholder requests change to approved/live feature | `CR` → `/pm-cr` |
| Internal team improvement request | `Issue` or `CR` — PM decides |
| Scheduled deployment task | `Deployment` |

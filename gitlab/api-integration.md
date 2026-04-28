# Phase 3 — GitLab API Integration (Replaces XLSX)

Self-hosted GitLab Free. All board operations use the GitLab Issues API.
XLSX import/export is retired after migration (§13 handles the one-time migration).
The `xlsx` skill is no longer used for ongoing task management once migration is complete.

---

## Configuration (set once per session or in agent config)

```
GITLAB_BASE_URL  : https://<your-gitlab-host>/api/v4
GITLAB_PROJECT_ID: <numeric project ID>         # Settings → General → Project ID
GITLAB_TOKEN     : <personal access token>      # Profile → Access Tokens, scope: api
```

---

## Bootstrap — label ID cache

Labels must be created before first use (see `repo-structure.md`).
On first run, fetch and cache the `name → id` map:

```
GET /projects/:id/labels?per_page=100
```

Use label **names** in this document for readability. In actual API calls, pass label names as strings — GitLab accepts label names directly in the `labels` field (comma-separated string).

---

## Pagination rule

All list endpoints default to 20 results. Always append `&per_page=100`.
If the response header contains `X-Next-Page`, fetch subsequent pages before processing.

---

## Workflow mapping

### §6 Stage 4 — Apply Breakdown (replaces: generate XLSX rows)

For each Working Item in the approved YAML, call:

```
POST /projects/:id/issues
{
  "title":       "<working_item.name>",
  "description": "<working_item.description>\n\nSource: prd/<feature>.md v1.0 | Plan: breakdown/<feature>_v1.0.yaml",
  "labels":      "Kind: Working Item,Group: <group>,Priority: <priority>,Type: <type>,Platform: <platform>,Status: Todo",
  "milestone_id": <id>   // null if release field is blank
}
```

Store the returned `iid` as the Working Item identifier (replaces KUB-XXXX).

Display created issues as a markdown table inline for user verification — same UX as the XLSX row display that is retired.

**Milestone lookup / creation:**
```
GET /projects/:id/milestones?search=<release_string>&per_page=20
POST /projects/:id/milestones
{ "title": "<release>", "due_date": "YYYY-MM-DD" }
```

---

### §9 Mode A — Solo standup update (replaces: read XLSX → write XLSX)

**Step 1 — Read tasks assigned to the user:**
```
GET /projects/:id/issues?assignee_username=<username>&labels=Kind%3A%20Task&state=opened&per_page=100
```
Filter out issues that carry `Status: Done` or `Status: Declined` in their label list.

**Step 2 — Present** as standup YAML (same format as §9 Mode A — no change to the user-facing interface).

**Step 3 — Write status update (replaces XLSX write):**

For each task where `new_status` is set, replace the current `Status:*` label with the new one:

```
PUT /projects/:id/issues/:iid
{
  "labels": "<all current labels, with old Status:* removed and new Status:* added>"
}
```

Label replacement rule: split current labels on `,`, drop any that start with `Status: `, append `Status: <new_status>`, re-join.

**Step 4 — Append standup log to issue description:**
```
POST /projects/:id/issues/:iid/notes
{
  "body": "**Standup <YYYY-MM-DD>** — Yesterday: <...> | Today: <...> | Blockers: <...> | Status: <old> → <new>"
}
```

**Step 5 — Recompute parent WI status (§5 rollup):**

Parse `Part of #<wi_iid>` from each updated task's description to identify the parent WI.
Then fetch all child tasks:
```
GET /projects/:id/issues?labels=Kind%3A%20Task&state=opened&per_page=100
```
Filter those whose description contains `Part of #<wi_iid>`. Apply §5 rules to derive WI status. Update WI labels exactly as in Step 3.

The transition `Ready to Review → Done` at the WI level **requires explicit user approval**. The agent never auto-promotes a WI to Done.

---

### §9 Mode B — Team standup report (replaces: read XLSX → generate markdown)

Fetch all open Task issues:
```
GET /projects/:id/issues?labels=Kind%3A%20Task&state=opened&per_page=100
```

For each issue, read the latest note that starts with `**Standup` to extract yesterday/today/blockers.
Group by assignee. Output `daily-standup/<date>.md` using the §9 Mode B template (no change).

---

### §9 Mode C — Quick status query (replaces: filter XLSX)

| Query intent | API call |
|---|---|
| Feature status | `GET /projects/:id/issues?search=<keyword>&per_page=20` |
| Person's tasks | `GET /projects/:id/issues?assignee_username=<user>&state=opened&per_page=50` |
| Specific item by ID | `GET /projects/:id/issues/<iid>` |

Always recompute WI status from children before displaying — never trust the WI label alone.

---

### §10 — Task assignment (replaces: update XLSX Owner + Status)

**User ID lookup:**
```
GET /users?username=<username>
```

**Assign and set status:**
```
PUT /projects/:id/issues/:iid
{
  "assignee_ids": [<user_id>],
  "labels": "<existing labels with Status: Todo replaced by Status: Working on it>"
}
```

Append timeline start to issue description via note:
```
POST /projects/:id/issues/:iid/notes
{
  "body": "Timeline start: <YYYY-MM-DD> — assigned to @<username>"
}
```

Recompute parent WI status per §5.

---

### §11 — Defect workflow (replaces: XLSX Defects group)

**QA opens defect:**
```
POST /projects/:id/issues
{
  "title":       "<title>",
  "description": "<defect template content with steps, expected, actual>",
  "labels":      "Kind: Working Item,Group: Defects,Type: BUG,Priority: <priority>,Platform: <platform>,Dev Status: Todo,QA Status: Pending Retest",
  "assignee_ids": [<dev_user_id>],
  "milestone_id": <release_milestone_id>
}
```

Do NOT apply any `Status:*` label to Defect issues.

**Dev picks up:**
```
PUT /projects/:id/issues/:iid
{ "labels": "<replace 'Dev Status: Todo' with 'Dev Status: Working on it'>" }
```

**Dev sends to QA:**
```
PUT /projects/:id/issues/:iid
{ "labels": "<replace 'Dev Status: Working on it' → 'Dev Status: Ready for QA', 'QA Status: Pending Retest' → 'QA Status: In Retest'>" }
```

**QA pass:**
```
PUT /projects/:id/issues/:iid
{
  "labels":      "<replace 'Dev Status: Ready for QA' → 'Dev Status: Done', 'QA Status: In Retest' → 'QA Status: Pass'>",
  "state_event": "close"
}
```

**QA fail:**
```
PUT /projects/:id/issues/:iid
{ "labels": "<replace 'Dev Status: Ready for QA' → 'Dev Status: Todo', 'QA Status: In Retest' → 'QA Status: Fail'>" }
```
Append failure notes:
```
POST /projects/:id/issues/:iid/notes
{ "body": "**Retest Fail — <YYYY-MM-DD>** — <failure detail> (@<qa_username>)" }
```

---

### §13 — XLSX Migration (one-time, then retire)

The XLSX migration workflow runs once to import existing monday.com board data into GitLab Issues:

1. Parse XLSX per §8 (existing logic, unchanged).
2. For each Working Item row: call `POST /projects/:id/issues` as in §6 Stage 4 above. Map `Item ID` (KUB-XXXX) into the issue description as `Legacy ID: KUB-XXXX` for traceability.
3. For each Task (subitem) row: call `POST /projects/:id/issues` with `Kind: Task` label and `Part of #<parent_iid>` in description.
4. Apply the current `Status` from XLSX to the matching `Status:*` label.
5. After all issues are created, run the §5 rollup recompute across all WIs to validate.
6. Report: count created, count flagged (missing Type, missing Priority, etc.).

After migration is confirmed, the `xlsx` skill is fully retired from this workflow.

---

## Status rollup — agent responsibility (Free tier)

GitLab Free has no computed or formula fields. The agent is solely responsible for enforcing §5:

| When | What the agent does |
|---|---|
| Standup update (Mode A) | After each Task label update, re-fetch all children of the parent WI and recompute WI status |
| Status query (Mode C) | Always recompute before displaying — never trust the WI label alone |
| Breakdown apply (Stage 4) | All new WIs start as `Status: Todo` |
| `Ready to Review → Done` | Requires explicit user approval — agent never auto-promotes |

---

## ID mapping reference

| monday.com / XLSX concept | GitLab equivalent |
|---|---|
| Board group (Client, Service…) | `Group:*` label |
| Working Item | Issue with `Kind: Working Item` label |
| Task (subitem) | Issue with `Kind: Task` label + `Part of #<wi_iid>` |
| KUB-XXXX (Item ID) | GitLab issue `iid` (e.g. `#42`) |
| Owner field (comma-separated) | GitLab assignees (multiple via `assignee_ids`) |
| Status column | `Status:*` label (one active at a time) |
| Dev Status column (defects) | `Dev Status:*` label |
| QA Status column (defects) | `QA Status:*` label |
| Release column | Milestone title |
| Feature column | Mentioned in issue description + `feature_area` from YAML |
| Actual Timeline | Issue `created_at` + close date (read-only) |
| Est. Timeline Start/End | Recorded in issue description / notes |

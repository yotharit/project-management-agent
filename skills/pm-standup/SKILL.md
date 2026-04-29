---
name: pm-standup
description: Run the daily standup — log individual progress, generate the team report, or query task status
argument-hint: [username]
allowed-tools: [Read, Write, Edit, Glob, Bash]
version: 1.1.0
---

# PM — Daily Standup

User: $ARGUMENTS (blank = resolve from `.env`)

---

## Identity & Config Resolution (run once per session)

1. Read `.env` at project root — parse as `KEY=value` text lines (not shell env). Extract `GITLAB_USERNAME`, `GITLAB_BASE_URL`, `GITLAB_PROJECT_ID`, `GITLAB_TOKEN`.
2. Read `team.yaml` → find the member where `gitlab_username` matches. Use `display_name` and `role` for this session.
3. If argument is provided, use it as `GITLAB_USERNAME` directly (overrides `.env`).
4. If `.env` is missing or `GITLAB_USERNAME` is blank → ask once. Suggest copying `.env.example` to `.env`.
5. **Self-registration:** If user is not found in `team.yaml` → ask for `display_name` and `role`. Append the new entry to `team.yaml`, show the diff, confirm before writing.
6. Role updates happen only on explicit command ("update my role to PO"). Never infer from behavior.
7. Never repeat identity resolution in the same session.

---

## Gitflow Management

Standup file writes go through a branch → MR → `develop`. Mode C (query only) writes nothing — no git operations needed.

**Confirm with user before every `push` and MR creation.**

### Branch setup — once per standup session, before writing
```bash
git status
git checkout develop && git pull origin develop
git checkout -b standup/<YYYY-MM-DD>
```

### After writing standup file (Mode A or B)
```bash
git add daily-standup/<YYYY-MM-DD>.md
git commit -m "standup: <YYYY-MM-DD> — <username>"
git push origin standup/<YYYY-MM-DD>
```

### If `team.yaml` was modified (self-registration) — commit on same branch
```bash
git add team.yaml daily-standup/<YYYY-MM-DD>.md
git commit -m "standup: <YYYY-MM-DD> — <username> + register <display_name>"
git push origin standup/<YYYY-MM-DD>
```

### Create MR (confirm first)
```
POST /projects/:id/merge_requests
{
  "source_branch": "standup/<YYYY-MM-DD>",
  "target_branch": "develop",
  "title": "Standup: <YYYY-MM-DD>",
  "description": "Daily standup log for <YYYY-MM-DD>.",
  "remove_source_branch": true
}
```
Report MR URL. **Do NOT merge the MR yourself.**

---

## Hard Rules (apply every time)

1. **Never fabricate.** Status, owners, blockers must come from GitLab issues or user input. Never invent progress.
2. **Confirm before writing.** Show proposed status changes and standup entry — wait for approval before writing files or calling API.
3. **Language preservation.** Thai/English/mixed content verbatim.
4. **WI status is a rollup.** After every Task update, recompute the parent Working Item status. Never edit WI status directly.
5. `Ready to Review → Done` at the WI level requires explicit user approval. Never auto-promote.

---

## GitLab API — Read/Write (replaces XLSX)

Config values are read from `.env` (see Identity & Config Resolution above).

**Read tasks for a user:**
```
GET /projects/:id/issues?assignee_username=<user>&labels=Kind: Task&state=opened&per_page=100
```
Filter out issues carrying `Status: Done` or `Status: Declined` labels.

**Update task status (replace label):**
```
PUT /projects/:id/issues/:iid
{ "labels": "<existing labels with old Status:* removed, new Status:* added>" }
```
Label replacement rule: split on `,`, drop entries starting with `Status: `, append `Status: <new>`, re-join.

**Append standup log as note:**
```
POST /projects/:id/issues/:iid/notes
{ "body": "**Standup <YYYY-MM-DD>** — Yesterday: <...> | Today: <...> | Blockers: <...> | Status: <old> → <new>" }
```

**Recompute parent WI status:**
Parse `Part of #<wi_iid>` from each updated task's description. Fetch all child tasks of that WI. Apply rollup rules below. Update WI labels via PUT.

**WI status rollup rules:**

| Child Task state | Working Item Status |
|---|---|
| Any Task = `Stuck` | `Stuck` |
| Any Task = `Declined` (others not all Done) | `Stuck` |
| Any Task = `Working on it` / `In Review` / `Ready to Review` | `Working on it` |
| All Tasks = `Done` (WI not yet manually reviewed) | `Ready to Review` |
| Some Tasks = `Ready to Start`, none started | `Ready to Start` |
| All Tasks = `Todo`, or no Tasks exist | `Todo` |
| All Tasks = `Done` AND WI manually reviewed | `Done` |

---

## Mode A — Solo update (individual logs their own tasks)

**Trigger:** "Update my standup", "Log my standup", "I want to log progress"

Steps:
1. Use `GITLAB_USERNAME` and `display_name` from Identity & Config Resolution. Use `display_name` as `user` in the YAML.
2. Read open tasks assigned to user via API (filter out Done/Declined).
3. Present as YAML for inline editing:

```yaml
standup:
  user: <name>
  date: <YYYY-MM-DD>
  tasks:
    - id: "#42"
      name: "Validate phone number format"
      working_item: "#15"
      current_status: Working on it
      yesterday: ""
      today: ""
      blockers: ""
      new_status: ""      # blank = keep current
  off_board_work: ""
```

4. After user fills in: confirm changes, then for each task in order:

   **a. Verify current issue status before writing** (fetch once per task):
   ```
   GET /projects/:id/issues/:iid
   ```
   Confirm fetched `Status:*` label matches `current_status` in the YAML. If mismatched → warn user: "Issue #<iid> is currently `<actual>`, not `<yaml current_status>`. Proceed with update?"

   **b. Update task label via API** — replace `Status:*` with `new_status` (skip if `new_status` is blank).

   **c. Post standup note.**

   **d. First pick-up detection** — if `current_status` ∈ {`Todo`, `Ready to Start`} AND `new_status` = `Working on it`, also post a branch + prompt comment (confirm with user first):
   ```
   POST /projects/:id/issues/:iid/notes
   {
     "body": "**Picked up by @<username> — <YYYY-MM-DD>**\n\n**Branch:** `feature/<iid>-<title-slug>`\n\n**Suggested Claude Code prompt:**\n```\nImplement \"<task name>\" (Task #<iid>, Working Item #<wi_iid>).\n\nContext:\n- PRD: <prd source reference from issue description>\n- Platform: <platform label>\n- Priority: <priority label>\n\nDescription:\n<task description from issue body>\n\nStart by reading the PRD section above, then implement.\n```"
   }
   ```
   Branch slug: lowercase, spaces → `-`, strip special chars, max 50 chars.

   **e. Recompute parent WI status** after all tasks are updated.

5. Append user's section to `daily-standup/<date>.md`.
6. Show all changes for confirmation **before** writing.

---

## Mode B — Team standup report (PM/SM generates summary)

**Trigger:** "Generate today's standup", "Daily report", "Standup report"

Read all open Task issues:
```
GET /projects/:id/issues?labels=Kind: Task&state=opened&per_page=100
```
For each issue, read the latest note starting with `**Standup` to extract yesterday/today/blockers.
Group by assignee. Output `daily-standup/<date>.md`:

```markdown
# Daily Standup — <YYYY-MM-DD>

## 1. Roadblocks & Problems
- <Person>: <task> — blocked by <reason>. Needs: <who/what>

## 2. Per-member status
### <Name>
- **Yesterday:** ...
- **Today:** ...
- **Blockers:** ...
- **Tasks touched:** [#42], [#43]

## 3. Working Item progress
| Working Item | Status | Tasks done / total | Owners |
|---|---|---|---|
| #15 Implement Wallet UI | Working on it | 3 / 7 | A, B |

## 4. Help requested / dependencies
- <Person> needs <Person> for <task>
```

Roadblocks come first — that is the standup's primary focus.

---

## Mode C — Quick status query

**Trigger:** "What's the status of <feature>?", "Show <person>'s tasks", "Where are we on #42?"

| Query | API call |
|---|---|
| Feature/keyword | `GET /projects/:id/issues?search=<keyword>&per_page=20` |
| Person's tasks | `GET /projects/:id/issues?assignee_username=<user>&state=opened&per_page=50` |
| Specific issue | `GET /projects/:id/issues/<iid>` |

Always recompute WI status from children before displaying. Return compact markdown table. No file output.

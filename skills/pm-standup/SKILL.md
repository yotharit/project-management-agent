---
name: pm-standup
description: Run the daily standup — log individual progress, generate the team report, or query task status
argument-hint: [username]
allowed-tools: [Read, Write, Edit, Glob]
version: 1.0.0
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

4. After user fills in: confirm changes → update each task label via API → post standup note → recompute parent WI status.
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

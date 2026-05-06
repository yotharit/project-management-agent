---
name: pm-bug
description: Open, update, or close a defect — QA opens bugs, dev picks up and fixes, QA retests
argument-hint: [defect-title or issue-id]
allowed-tools: [Read, Write, Edit, Bash]
version: 1.1.0
---

# PM — Defect Workflow

$ARGUMENTS

---

## Gitflow Management

Defect workflow runs entirely via GitLab Issues API — no markdown files are written in the normal flow, so no git operations are needed for defect CRUD.

**Exception: `team.yaml` self-registration**

When a new member is registered, create a branch and MR. Confirm with user first.

```bash
git status
git checkout develop && git pull origin develop
git checkout -b chore/team-register-<username>
git add team.yaml
git commit -m "chore(team): register <display_name>"
git push origin chore/team-register-<username>
```

Then create MR/PR:

**GitLab:**
```
POST /projects/:id/merge_requests
{
  "source_branch": "chore/team-register-<username>",
  "target_branch": "develop",
  "title": "chore(team): register <display_name>",
  "description": "New team member self-registration via /pm-bug.",
  "remove_source_branch": true
}
```

**GitHub:**
```
POST /repos/:owner/:repo/pulls
{
  "head": "chore/team-register-<username>",
  "base": "develop",
  "title": "chore(team): register <display_name>",
  "body": "New team member self-registration via /pm-bug."
}
```

Report MR/PR URL. **Do NOT merge the MR/PR yourself.**

---

## Hard Rules (apply every time)

1. **Never fabricate.** Steps to reproduce, severity, and assignees must come from the user. Never invent bug details.
2. **Confirm before writing.** Show the proposed defect row or status change — wait for approval before calling API.
3. **Language preservation.** Thai/English/mixed content verbatim.
4. **Dual status.** Defects use `Dev Status:*` + `QA Status:*` labels. Never apply `Status:*` to defect issues.
5. **Both Owner and Reviewer required** when a defect is opened.

---

## Identity & Config Resolution (run once per session)

1. Read `.env` at project root — parse as `KEY=value` text lines. Extract `GIT_PROVIDER` (default: `gitlab`).
   - `gitlab`: load `GITLAB_USERNAME`, `GITLAB_BASE_URL`, `GITLAB_PROJECT_ID`, `GITLAB_TOKEN`
   - `github`: load `GITHUB_USERNAME`, `GITHUB_OWNER`, `GITHUB_REPO`, `GITHUB_TOKEN`
   See `knowledge/git-provider.md` for auth headers and endpoint formats.
2. Read `team.yaml` → find the member where `username` matches the active USERNAME. Use `display_name` and `role`. This becomes the default QA reporter when opening defects.
3. If `.env` is missing or USERNAME is blank → ask once. Suggest copying `.env.example` to `.env`.
4. **Self-registration:** If user is not found in `team.yaml` → ask for `display_name` and `role`. Append to `team.yaml`, show diff, confirm before writing.
5. Role updates happen only on explicit command. Never infer from behavior.
6. Never repeat identity resolution in the same session.

## Issues API — Config

Values are from `.env`. See `knowledge/git-provider.md` for endpoints and auth.

**Assignee ID lookup (GitLab only — not needed for GitHub):**
```
GET /users?username=<gitlab_username>  →  use returned .id for assignee_ids
```
GitHub uses `"assignees": ["username"]` directly — no lookup needed.

---

## Defect Status Reference

| Dev Status | QA Status | Meaning |
|---|---|---|
| `Todo` | `Pending Retest` | QA opened, dev hasn't picked up |
| `Working on it` | `Pending Retest` | Dev fixing |
| `Ready for QA` | `In Retest` | Dev done, QA verifying |
| `Done` | `Pass` | Verified fixed |
| `Todo` | `Fail` | Returned to dev, needs re-fix |

---

## QA Opens a Defect

**Trigger:** "Log a bug", "Open defect for <X>", "Report a bug"

Collect from user:
1. Title
2. Feature area
3. Steps to reproduce (goes in description)
4. Severity / Priority
5. Platform
6. Release version where found
7. Dev assignee (Owner)
8. QA reporter (Reviewer) — defaults to current user

Confirm the row, then create:

**GitLab:**
```
POST /projects/:id/issues
{
  "title":       "<title>",
  "description": "<defect template content>",
  "labels":      "Kind: Working Item,Group: Defects,Type: BUG,Priority: <priority>,Platform: <platform>,Dev Status: Todo,QA Status: Pending Retest",
  "assignee_ids": [<dev_user_id>],
  "milestone_id": <release_milestone_id>
}
```

**GitHub:**
```
POST /repos/:owner/:repo/issues
{
  "title":     "<title>",
  "body":      "<defect template content>",
  "labels":    ["Kind: Working Item", "Group: Defects", "Type: BUG", "Priority: <priority>", "Platform: <platform>", "Dev Status: Todo", "QA Status: Pending Retest"],
  "assignees": ["<dev_github_username>"],
  "milestone": <release_milestone_number>
}
```

Display created issue details for confirmation before import.

---

## Dev Picks Up a Defect

**Trigger:** "I'm picking up defect #<iid>", "Start working on bug #<iid>"

[GitLab] `PUT /projects/:id/issues/:iid { "labels": "<replace 'Dev Status: Todo' → 'Dev Status: Working on it'>" }`
[GitHub] `PATCH /repos/:owner/:repo/issues/:number { "labels": [...updated label array...] }`

---

## Dev Sends to QA

**Trigger:** "Defect #<iid> ready for QA", "Bug #<iid> fixed, send to QA"

[GitLab] `PUT /projects/:id/issues/:iid { "labels": "<replace 'Dev Status: Working on it' → 'Dev Status: Ready for QA', 'QA Status: Pending Retest' → 'QA Status: In Retest'>" }`
[GitHub] `PATCH /repos/:owner/:repo/issues/:number { "labels": [...updated label array...] }`

---

## QA Retest — Pass

**Trigger:** "Defect #<iid> passed QA", "Bug #<iid> verified fixed"

[GitLab]
```
PUT /projects/:id/issues/:iid
{ "labels": "<replace 'Dev Status: Ready for QA' → 'Dev Status: Done', 'QA Status: In Retest' → 'QA Status: Pass'>", "state_event": "close" }
```

[GitHub]
```
PATCH /repos/:owner/:repo/issues/:number
{ "labels": [...updated label array...], "state": "closed" }
```

---

## QA Retest — Fail

**Trigger:** "Defect #<iid> failed retest", "Bug #<iid> still broken"

[GitLab] `PUT /projects/:id/issues/:iid { "labels": "<replace 'Dev Status: Ready for QA' → 'Dev Status: Todo', 'QA Status: In Retest' → 'QA Status: Fail'>" }`
[GitHub] `PATCH /repos/:owner/:repo/issues/:number { "labels": [...updated label array...] }`

Append failure notes:

[GitLab] `POST /projects/:id/issues/:iid/notes { "body": "**Retest Fail — <YYYY-MM-DD>** — <failure detail> (@<qa_username>)" }`
[GitHub] `POST /repos/:owner/:repo/issues/:number/comments { "body": "**Retest Fail — <YYYY-MM-DD>** — <failure detail> (@<qa_username>)" }`

---

## Label Replacement Rule

When updating labels, always:
1. Fetch current labels from the issue.
2. Remove the label being replaced (exact string match).
3. Add the new label.
4. Re-join as comma-separated string and PUT.

Never leave two `Dev Status:*` or two `QA Status:*` labels active simultaneously.

# Git Provider API Reference

Read `GIT_PROVIDER` from `.env` (default: `gitlab`) to select the active provider.  
All skills reference this file — avoid duplicating API patterns in individual skills.

---

## Config Variables

| Key | GitLab | GitHub |
|---|---|---|
| Provider tag | `gitlab` | `github` |
| Username | `GITLAB_USERNAME` | `GITHUB_USERNAME` |
| Auth token | `GITLAB_TOKEN` | `GITHUB_TOKEN` |
| Project path | `GITLAB_BASE_URL` + `GITLAB_PROJECT_ID` | `GITHUB_OWNER` + `GITHUB_REPO` |

## Auth Header

| Provider | Header |
|---|---|
| GitLab | `PRIVATE-TOKEN: <GITLAB_TOKEN>` |
| GitHub | `Authorization: Bearer <GITHUB_TOKEN>` |

## Base URL

| Provider | Base | Project ref |
|---|---|---|
| GitLab | `<GITLAB_BASE_URL>` | `/projects/<GITLAB_PROJECT_ID>` |
| GitHub | `https://api.github.com` | `/repos/<GITHUB_OWNER>/<GITHUB_REPO>` |

---

## Issues

### Create

**GitLab:** `POST /projects/:id/issues`
```json
{
  "title":       "...",
  "description": "...",
  "labels":      "Label1,Label2",
  "assignee_ids": [123],
  "milestone_id": 1
}
```

**GitHub:** `POST /repos/:owner/:repo/issues`
```json
{
  "title":     "...",
  "body":      "...",
  "labels":    ["Label1", "Label2"],
  "assignees": ["login"],
  "milestone": 1
}
```

Key differences: `description` → `body` · labels as comma-string vs array · `assignee_ids` (numeric) vs `assignees` (login string) · `milestone_id` vs `milestone`

### Update

**GitLab:** `PUT /projects/:id/issues/:iid` — same fields as create.

**GitHub:** `PATCH /repos/:owner/:repo/issues/:number` — same fields as create.

### List

**GitLab:** `GET /projects/:id/issues?assignee_username=<u>&labels=Kind: Task&state=opened&per_page=100`

**GitHub:** `GET /repos/:owner/:repo/issues?assignee=<u>&labels=Kind%3A+Task&state=open&per_page=100`

### Post Comment / Note

**GitLab:** `POST /projects/:id/issues/:iid/notes { "body": "..." }`

**GitHub:** `POST /repos/:owner/:repo/issues/:number/comments { "body": "..." }`

---

## Labels

### List

**GitLab:** `GET /projects/:id/labels?per_page=100`

**GitHub:** `GET /repos/:owner/:repo/labels?per_page=100`

### Create

**GitLab:** `POST /projects/:id/labels`
```json
{ "name": "Status: Todo", "color": "#dfe1e6", "description": "..." }
```

**GitHub:** `POST /repos/:owner/:repo/labels`
```json
{ "name": "Status: Todo", "color": "dfe1e6" }
```

GitHub color has **no `#` prefix**. GitHub has no description field (omit it).

---

## Milestones

### List / Search

**GitLab:** `GET /projects/:id/milestones?search=<title>&per_page=20`

**GitHub:** `GET /repos/:owner/:repo/milestones` — no server-side search; filter client-side by `.title`.

### Create

**GitLab:** `POST /projects/:id/milestones { "title": "...", "due_date": "YYYY-MM-DD" }`

**GitHub:** `POST /repos/:owner/:repo/milestones { "title": "...", "due_on": "YYYY-MM-DDT00:00:00Z" }`

---

## Merge Requests / Pull Requests

| | GitLab | GitHub |
|---|---|---|
| Concept | Merge Request (MR) | Pull Request (PR) |
| Endpoint | `/projects/:id/merge_requests` | `/repos/:owner/:repo/pulls` |
| Source branch | `source_branch` | `head` |
| Target branch | `target_branch` | `base` |
| Body field | `description` | `body` |
| Auto-delete source | `"remove_source_branch": true` | Not available (set in repo settings) |

**GitLab:**
```
POST /projects/:id/merge_requests
{
  "source_branch": "prd/<slug>",
  "target_branch": "develop",
  "title": "PRD: <name>",
  "description": "...",
  "remove_source_branch": true
}
```

**GitHub:**
```
POST /repos/:owner/:repo/pulls
{
  "head": "prd/<slug>",
  "base": "develop",
  "title": "PRD: <name>",
  "body": "..."
}
```

---

## Assignee Lookup

**GitLab** — numeric user ID required for `assignee_ids`:
```
GET /users?username=<gitlab_username>  →  use returned .id
```

**GitHub** — use login string directly. No lookup needed:
```
"assignees": ["github_username"]
```

---

## Branches

### Check / Get

**GitLab:** `GET /projects/:id/repository/branches/<branch>`

**GitHub:** `GET /repos/:owner/:repo/branches/<branch>`

### Create

**GitLab:**
```
POST /projects/:id/repository/branches { "branch": "develop", "ref": "main" }
```

**GitHub** (two steps — get SHA first, then create ref):
```
GET  /repos/:owner/:repo/git/ref/heads/main  →  sha
POST /repos/:owner/:repo/git/refs
{ "ref": "refs/heads/develop", "sha": "<sha>" }
```

### Verify project/repo access

**GitLab:** `GET /projects/:id`

**GitHub:** `GET /repos/:owner/:repo`

---

## Template Directories

| Artifact | GitLab | GitHub |
|---|---|---|
| Issue templates | `.gitlab/issue_templates/<name>.md` | `.github/ISSUE_TEMPLATE/<name>.md` |
| MR/PR template | `.gitlab/merge_request_templates/<name>.md` | `.github/pull_request_template.md` (single file) |

GitHub issue templates require YAML frontmatter:
```yaml
---
name: Working Item
about: Track a working item for a feature
---
<template body here>
```

GitHub PR template is a single file at `.github/pull_request_template.md` — no frontmatter needed.

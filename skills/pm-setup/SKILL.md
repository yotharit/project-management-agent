---
name: pm-setup
description: >
  Set up a PM docs repository after installing the plugin. Activates when the user runs
  /pm-setup, or says "setup pm repo", "initialize pm project", "set up gitlab project
  management", or "init pm agent". Works for both new and ongoing projects.
argument-hint: [new|ongoing]
allowed-tools: [Read, Write, Edit, Glob, Bash]
version: 1.0.0
---

# PM — Repository Setup

Mode: $ARGUMENTS (blank = auto-detect)

---

## Hard Rules

1. **Confirm before writing.** Show each planned action and wait for approval before writing files or calling APIs.
2. **Never overwrite existing files.** Skip any file that already exists — never clobber.
3. **Credentials first.** Collect and validate GitLab credentials before any API call.
4. **Separate automated from manual.** Clearly list which steps require the GitLab web UI.

---

## Phase 0 — Detect Mode

If `$ARGUMENTS` is blank, auto-detect:

```bash
ls prd/ grooming/ team.yaml 2>/dev/null
```

- `team.yaml` exists AND (`prd/` or `grooming/` has files) → **Ongoing** project
- None of those exist → **New** project
- Ambiguous → ask: "Is this a new project or an existing one being retrofitted?"

Greet the user:
> "Starting PM setup for a **[new / ongoing]** project. I'll run through 9 phases and list manual GitLab UI steps at the end."

---

## Phase 1 — GitLab Credentials

### 1a. Read or create .env

Check if `.env` exists at project root. Parse as `KEY=value` text lines. Extract:
- `GITLAB_USERNAME`
- `GITLAB_BASE_URL`
- `GITLAB_PROJECT_ID`
- `GITLAB_TOKEN`

If `.env` is missing → create it with these blank fields:

```
GITLAB_USERNAME=
GITLAB_BASE_URL=https://gitlab.bitkub.com/api/v4
GITLAB_PROJECT_ID=
GITLAB_TOKEN=
```

For each blank value → ask the user once:
- `GITLAB_USERNAME` — "Your GitLab username (e.g. yo.tharit)"
- `GITLAB_BASE_URL` — "Your GitLab API base URL (e.g. https://gitlab.bitkub.com/api/v4)"
- `GITLAB_PROJECT_ID` — "Your GitLab project ID — found at Settings → General → Project ID"
- `GITLAB_TOKEN` — "Your Personal Access Token — Profile → Access Tokens, scope: api"

Write collected values to `.env`. Never ask again this session.

### 1b. Test connection

```
GET <GITLAB_BASE_URL>/projects/<GITLAB_PROJECT_ID>
-H "PRIVATE-TOKEN: <GITLAB_TOKEN>"
```

- HTTP 200 → report: "✓ GitLab connection OK — project: `<name>`"
- Error → report the exact HTTP status and message, stop, ask user to fix credentials before continuing.

### 1c. Protect .env

```bash
grep -q "^\.env$" .gitignore 2>/dev/null || echo ".env" >> .gitignore
```

Report: "✓ .env added to .gitignore"

---

## Phase 2 — Folder Structure

Create all required folders (idempotent — safe if they already exist):

```bash
mkdir -p rfc grooming kickoff prd breakdown cr daily-standup \
         .gitlab/issue_templates .gitlab/merge_request_templates
```

Report: "✓ Folders ready"

---

## Phase 3 — Issue and MR Templates

Check what already exists:

```bash
ls .gitlab/issue_templates/ .gitlab/merge_request_templates/ 2>/dev/null
```

For each missing template file, write it directly using the content below.
**Skip any file that already exists.**

After writing, report:
- "✓ Created: [list of new files]"
- "⏭ Already existed: [list of skipped files]"

### .gitlab/issue_templates/working-item.md

```
<!--
  Working Item Issue Template
  After creating the issue, apply labels:
    Kind: Working Item
    Group: <Client | Service | Smart Contract | Chain | QA - API Test | QA - Automate Test>
    Priority: <High | Medium | Low | Un-priority>
    Type: <Feature | BUG | Support | CR | Issue | Deployment>
    Platform: <Kub Wallet | iOS | Android | Web | Mobile App | Smart Contract | Chain | Backend>
    Status: Todo
  DO NOT set Status directly — derived from child Task issues.
-->

## Summary

## Feature Area

## Source

<!-- e.g. PRD §4 FR-3 | breakdown/<feature>_v1.0.yaml -->

## Description

## Acceptance Criteria

- [ ] AC-1: Given ..., when ..., then ...

## Child Tasks

<!-- Child Task issues link back here with "Part of #<this_iid>" -->

## Status Log

<!-- YYYY-MM-DD — Status: <old> → <new> — <note> -->
```

### .gitlab/issue_templates/task.md

```
<!--
  Task Issue Template
  Labels: Kind: Task | Status: Todo | Priority/Group/Platform: inherit from parent WI
  Link to parent: add "Part of #<working_item_iid>" below.
-->

## Parent Working Item

Part of #<!-- working_item_iid -->

## Summary

<!-- Start with a verb: Implement / Fix / Write -->

## Owner

@<!-- username -->

## Reviewer

@<!-- qa_username -->

## Timeline

- Start: YYYY-MM-DD
- End: YYYY-MM-DD

## Description

## Status Log

<!-- YYYY-MM-DD — Status: <old> → <new> — Yesterday: <...> | Today: <...> | Blockers: <...> -->
```

### .gitlab/issue_templates/defect.md

```
<!--
  Defect Issue Template
  Labels: Kind: Working Item | Group: Defects | Type: BUG | Priority | Platform
          Dev Status: Todo | QA Status: Pending Retest
  DO NOT apply Status:* labels to Defect issues.
  Owner = Dev assignee. Reviewer = QA reporter. Both required when opened.
-->

## Summary

## Feature Area

## Release Found

## Owner (Dev)

@<!-- dev_username -->

## Reviewer (QA)

@<!-- qa_username -->

## Steps to Reproduce

1. 
2. 
3. 

## Expected Behavior

## Actual Behavior

## Environment

- Platform: 
- OS / Device: 
- App version: 

## Attachments

## Retest Log

<!-- YYYY-MM-DD — Pass/Fail — <notes> (@qa_username) -->
```

### .gitlab/merge_request_templates/prd-review.md

```
<!--
  PRD Review MR Template
  Source branch : prd/<feature-slug>
  Target branch : develop
  Assignee      : Feature Owner
-->

## PRD: <!-- Feature Name -->

**File:** `prd/<feature-slug>.md`
**Version:** <!-- e.g. 0.3 -->
**Feature Owner:** @<!-- username -->
**Reviewers:** @<!-- reviewer1 --> @<!-- reviewer2 -->

---

## Review Checklist

### Source coverage
- [ ] Every FR/NFR/AC has an inline citation (`[RFC-XXX §N]`, `[Grooming YYYY-MM-DD]`, `[Kickoff YYYY-MM-DD]`)
- [ ] Appendix A maps every FR/NFR/AC to its source location
- [ ] §10 Open Items is empty or all items deferred with named owner and due date

### Content
- [ ] §1 Overview cites RFC §3 problem statement
- [ ] §2 Goals & Non-Goals agreed with PO
- [ ] §3 User Stories cover all personas
- [ ] §4 Functional Requirements are numbered, sourced, testable
- [ ] §5 Non-Functional Requirements cover performance, security, compliance
- [ ] §6 UX/UI Flows cover happy path AND error/edge cases
- [ ] §7 Acceptance Criteria in Given/When/Then format, one per FR
- [ ] §8 Dependencies list external services and other teams
- [ ] §9 Out of Scope matches RFC §10

### Process
- [ ] No invented content — every statement traces to a source document
- [ ] Source-language content (Thai/English/mixed) preserved verbatim
- [ ] Changelog has an entry for this version

---

## Reviewer Notes

---

## On Merge

After merging to `develop`, the agent will:
1. Set `version: 1.0`, `status: approved` in PRD frontmatter
2. Add Changelog row: `v1.0 — Approved — YYYY-MM-DD`
3. Treat the PRD as locked — no silent regeneration
```

---

## Phase 4 — GitLab Labels

Fetch existing labels:
```
GET /projects/:id/labels?per_page=100
-H "PRIVATE-TOKEN: <GITLAB_TOKEN>"
```

Build the set of existing label names. For each label in the required list below that is NOT already present, create it:

```bash
curl -s -X POST "$GITLAB_BASE_URL/projects/$GITLAB_PROJECT_ID/labels" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"$NAME\", \"color\": \"$COLOR\", \"description\": \"$DESC\"}"
```

### Required labels (38 total)

**Kind (2)**
| Name | Color |
|---|---|
| Kind: Working Item | #0052CC |
| Kind: Task | #0052CC |

**Status (9)**
| Name | Color |
|---|---|
| Status: Todo | #dfe1e6 |
| Status: Ready to Start | #b3d4ff |
| Status: Working on it | #0747a6 |
| Status: Ready to Review | #ff991f |
| Status: In Review | #ff991f |
| Status: Done | #00875a |
| Status: Stuck | #de350b |
| Status: Declined | #6554c0 |
| Status: Deployment | #403294 |

**Priority (4)**
| Name | Color |
|---|---|
| Priority: High | #de350b |
| Priority: Medium | #ff991f |
| Priority: Low | #00875a |
| Priority: Un-priority | #dfe1e6 |

**Type (6)**
| Name | Color |
|---|---|
| Type: Feature | #0052CC |
| Type: BUG | #de350b |
| Type: Support | #00875a |
| Type: CR | #ff991f |
| Type: Issue | #6554c0 |
| Type: Deployment | #403294 |

**Platform (8)**
| Name | Color |
|---|---|
| Platform: Kub Wallet | #00b8d9 |
| Platform: iOS | #00b8d9 |
| Platform: Android | #00b8d9 |
| Platform: Web | #00b8d9 |
| Platform: Mobile App | #00b8d9 |
| Platform: Smart Contract | #00b8d9 |
| Platform: Chain | #00b8d9 |
| Platform: Backend | #00b8d9 |

**Group (7)**
| Name | Color | Description |
|---|---|---|
| Group: Client | #4c9aff | Frontend / Mobile UI |
| Group: Service | #4c9aff | Backend / API |
| Group: Smart Contract | #4c9aff | On-chain logic |
| Group: Chain | #4c9aff | Blockchain infra |
| Group: QA - API Test | #4c9aff | |
| Group: QA - Automate Test | #4c9aff | |
| Group: Defects | #de350b | |

**Dev Status (4 — defects only)**
| Name | Color | Description |
|---|---|---|
| Dev Status: Todo | #dfe1e6 | Defect: dev hasn't picked up |
| Dev Status: Working on it | #0747a6 | Defect: dev fixing |
| Dev Status: Ready for QA | #ff991f | Defect: dev done, QA verifying |
| Dev Status: Done | #00875a | Defect: verified fixed |

**QA Status (4 — defects only)**
| Name | Color | Description |
|---|---|---|
| QA Status: Pending Retest | #dfe1e6 | Defect: awaiting QA retest |
| QA Status: In Retest | #ff991f | Defect: QA retesting |
| QA Status: Pass | #00875a | Defect: fix verified |
| QA Status: Fail | #de350b | Defect: fix failed, returned to dev |

After all labels are processed, print a summary:
```
Labels: 38 required
  ✓ Created:        X
  ⏭ Already existed: Y
  ✗ Failed:         Z  (list names + error messages)
```

---

## Phase 5 — team.yaml

### New project
Ask for project name. Ask for current user's `display_name`, `role`, and `email`. Create `team.yaml`:

```yaml
team:
  project: <project name>
  members:
    - display_name: <display_name>
      gitlab_username: <GITLAB_USERNAME from .env>
      role: <role>        # PM | PO | Dev | QA | SM | DevOps
      email: <email>
```

Show content and confirm before writing.

### Ongoing project
If `team.yaml` exists → check if `GITLAB_USERNAME` has an entry.
- Found → "✓ You are already in team.yaml"
- Not found → ask for `display_name`, `role`, `email`. Append entry. Show diff, confirm before writing.

---

## Phase 6 — develop Branch

Check if `develop` branch exists:
```
GET /projects/:id/repository/branches/develop
-H "PRIVATE-TOKEN: <GITLAB_TOKEN>"
```

If 404 → confirm with user, then create from `main`:
```
POST /projects/:id/repository/branches
{ "branch": "develop", "ref": "main" }
```

Report: "✓ develop branch created" or "✓ develop branch already exists"

---

## Phase 7 — Commit and Push

Stage all new setup files:

```bash
git add .gitignore team.yaml .gitlab/
git status
```

Show the full `git status` output. Confirm with user before committing.

```bash
git commit -m "chore: init PM agent setup"
git push
```

If the repo is empty (no commits) → tell user to create an initial commit manually first, then re-run Phase 7.

---

## Phase 8 — Manual GitLab UI Steps

These steps require the GitLab web UI and cannot be automated on Free tier.
Print as a checklist:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Manual steps — complete in GitLab web UI:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ ] Issue Board
    Plan → Issue Boards → New board → name it after your project
    Add columns in this order:
      Todo            (label: Status: Todo)
      Ready to Start  (label: Status: Ready to Start)
      Working on it   (label: Status: Working on it)
      Ready to Review (label: Status: Ready to Review)
      In Review       (label: Status: In Review)
      Done            (label: Status: Done)
    Create a second board "Defects" filtered on: Group: Defects

[ ] Milestones
    Plan → Milestones → New milestone for each known release
    e.g. v1.0.0, v1.1.0

[ ] Branch Protection
    Settings → Repository → Protected branches
      main    — No direct push. All changes via MR.
      develop — No direct push. All changes via MR.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 9 — Verification

Run a final sanity check. For each item, mark ✓ pass or ✗ fail:

1. Re-read `.env` — all four keys present and non-empty
2. `GET /projects/:id` — HTTP 200
3. `GET /projects/:id/labels?per_page=100` — response count ≥ 38
4. Read `team.yaml` — `GITLAB_USERNAME` has an entry
5. `GET /projects/:id/repository/branches/develop` — HTTP 200

Print final status report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PM Setup Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ GitLab connected  (project: <name>, id: <id>)
✓ Folders           rfc/ grooming/ kickoff/ prd/ breakdown/ cr/ daily-standup/
✓ Templates         3 issue + 1 MR template
✓ Labels            38 ready (<X> created, <Y> already existed)
✓ team.yaml         <N> member(s)
✓ develop branch    ready

Manual steps remaining:
  → Issue Board, Milestones, Branch Protection (see checklist above)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ready to start your first feature:

  Dev team  → write RFC      rfc/KUB-RFC-001_<slug>.md
                              (see knowledge/rfc-template.md)
  PM        → grooming       grooming/YYYY-MM-DD-<feature>.md
                              (see knowledge/mom-template.md)
  PO        → kickoff        kickoff/YYYY-MM-DD-kickoff-<feature>.md
  Then run  → /pm-prd <feature-slug>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Ongoing Project — XLSX Migration (optional)

After verification, if the user has existing Working Items in a monday.com XLSX export, offer:

> "Do you have an existing monday.com XLSX export to migrate to GitLab Issues? (yes/no)"

If yes → hand off:
```
Migrate this XLSX to GitLab issues
```

The agent parses the XLSX, validates, shows a preview table, and creates GitLab Issues on confirmation. After migration, recomputes all WI statuses.

If no → skip.

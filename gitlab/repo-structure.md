# Phase 1 — GitLab Repo Structure & PRD Review Gate

## Recommended repo layout

Create a dedicated repo (e.g. `pm-project`) on your self-hosted GitLab.
Copy the template files from `gitlab/templates/` into `.gitlab/` as shown below.

```
pm-project/                             ← GitLab repo root
├── rfc/
│   └── RFC-XXX_<slug>.md
├── grooming/
│   └── YYYY-MM-DD-<feature>.md
├── kickoff/
│   └── YYYY-MM-DD-kickoff-<feature>.md
├── prd/
│   └── <feature-slug>.md
├── breakdown/
│   └── <feature-slug>_v1.0.yaml
├── cr/
│   └── <feature-slug>-<NNN>.yaml
├── daily-standup/
│   └── YYYY-MM-DD.md
└── .gitlab/
    ├── issue_templates/
    │   ├── working-item.md             ← copy from gitlab/templates/issue/working-item.md
    │   ├── task.md                     ← copy from gitlab/templates/issue/task.md
    │   └── defect.md                   ← copy from gitlab/templates/issue/defect.md
    └── merge_request_templates/
        └── prd-review.md               ← copy from gitlab/templates/merge_request/prd-review.md
```

## Branch naming conventions

| Purpose | Branch name |
|---|---|
| PRD draft | `prd/<feature-slug>` |
| Breakdown draft | `breakdown/<feature-slug>` |
| Change request | `cr/<feature-slug>-<NNN>` |
| Daily standup | `standup/<YYYY-MM-DD>` |
| Team registration | `chore/team-register-<username>` |
| RFC / grooming / kickoff (read-only) | Committed directly to `main` by authors |

## PRD Review Gate — Merge Request workflow

The pipeline gate **"PRD → Review"** (§6 Stage 2) maps to a GitLab MR:

| Pipeline gate | GitLab action |
|---|---|
| Agent generates PRD draft | Commit `prd/<feature-slug>.md` to branch `prd/<feature-slug>`, open MR → `develop` using the `prd-review` MR template |
| User/team review | Reviewer leaves inline comments on the MR diff |
| PRD approved | Author checks all boxes in the MR checklist, reviewer approves, MR is merged into `develop` |
| QA validates | QA tests PM artifacts on `develop` (Dev Release) |
| Agent locks PRD | After merge: set `version: 1.0`, `status: approved` in frontmatter, add Changelog row |
| PM gate | PM/PO opens separate MR: `develop` → `main` to lock the PRD |

### Free tier note on MR approvals
GitLab Free does not enforce MR approval rules (Premium feature).
Use the checklist in `prd-review.md` as the manual gate — the author must tick every box before merging. The merge commit timestamp in `develop` is the audit trail for approval.

## Protected branch setup

| Branch | Protection |
|---|---|
| `main` | No direct push. All changes via MR from `develop` (PM gate). |
| `develop` | No direct push. All artifact branches merge here first. |
| `prd/*` | Author + PM can push; merge to `develop` requires MR. |
| `breakdown/*` | Author + PM can push; merge to `develop` requires MR. |
| `cr/*` | Author + PM can push; merge to `develop` requires MR. |
| `standup/*` | Author can push; merge to `develop` requires MR. |

Configure at: **Settings → Repository → Protected branches**

## Issue Board setup

Create a board at **Plan → Issue Boards → New board** named after the project (e.g. `Your Project`).

Add columns in this order — each column filters by one `Status:*` label:

| Column | Label filter |
|---|---|
| Todo | `Status: Todo` |
| Ready to Start | `Status: Ready to Start` |
| Working on it | `Status: Working on it` |
| Ready to Review | `Status: Ready to Review` |
| In Review | `Status: In Review` |
| Done | `Status: Done` |

Add a separate board for Defects filtering on `Group: Defects`.

## One-time setup checklist

- [ ] Create repo `pm-project` (or embed `.gitlab/` in your existing project repo)
- [ ] Copy issue and MR templates into `.gitlab/`
- [ ] Create all labels from `gitlab/labels.yaml` (see label creation script below)
- [ ] Protect `main` branch
- [ ] Create Issue Board with status columns
- [ ] Create Milestones for known releases (e.g. `v3.0.0-beta.24`)

## Quick label creation via GitLab API

Run this once to bulk-create labels. Replace `<host>`, `<project_id>`, and `<token>`.

```bash
GITLAB="https://<host>/api/v4"
PROJECT=<project_id>
TOKEN=<your_personal_access_token>

create_label() {
  curl -s -X POST "$GITLAB/projects/$PROJECT/labels" \
    -H "PRIVATE-TOKEN: $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$1\", \"color\": \"$2\", \"description\": \"$3\"}"
}

# Kind
create_label "Kind: Working Item" "#0052CC" "Parent issue representing a deliverable"
create_label "Kind: Task"         "#0052CC" "Atomic unit of work, child of a Working Item"

# Status
create_label "Status: Todo"            "#dfe1e6" ""
create_label "Status: Ready to Start"  "#b3d4ff" ""
create_label "Status: Working on it"   "#0747a6" ""
create_label "Status: Ready to Review" "#ff991f" ""
create_label "Status: In Review"       "#ff991f" ""
create_label "Status: Done"            "#00875a" ""
create_label "Status: Stuck"           "#de350b" ""
create_label "Status: Declined"        "#6554c0" ""
create_label "Status: Deployment"      "#403294" ""

# Priority
create_label "Priority: High"        "#de350b" ""
create_label "Priority: Medium"      "#ff991f" ""
create_label "Priority: Low"         "#00875a" ""
create_label "Priority: Un-priority" "#dfe1e6" ""

# Type
create_label "Type: Feature"    "#0052CC" ""
create_label "Type: BUG"        "#de350b" ""
create_label "Type: Support"    "#00875a" ""
create_label "Type: CR"         "#ff991f" "Change Request"
create_label "Type: Issue"      "#6554c0" ""
create_label "Type: Deployment" "#403294" ""

# Platform
create_label "Platform: App"            "#00b8d9" ""
create_label "Platform: iOS"            "#00b8d9" ""
create_label "Platform: Android"        "#00b8d9" ""
create_label "Platform: Web"            "#00b8d9" ""
create_label "Platform: Mobile App"     "#00b8d9" ""
create_label "Platform: Smart Contract" "#00b8d9" ""
create_label "Platform: Chain"          "#00b8d9" ""
create_label "Platform: Backend"        "#00b8d9" ""

# Group
create_label "Group: Client"           "#4c9aff" "Frontend / Mobile UI"
create_label "Group: Service"          "#4c9aff" "Backend / API"
create_label "Group: Smart Contract"   "#4c9aff" "On-chain logic"
create_label "Group: Chain"            "#4c9aff" "Blockchain infra"
create_label "Group: QA - API Test"    "#4c9aff" ""
create_label "Group: QA - Automate Test" "#4c9aff" ""
create_label "Group: Defects"          "#de350b" ""

# Dev Status (Defects only)
create_label "Dev Status: Todo"         "#dfe1e6" "Defect: dev hasn't picked up"
create_label "Dev Status: Working on it" "#0747a6" "Defect: dev fixing"
create_label "Dev Status: Ready for QA" "#ff991f" "Defect: dev done, QA verifying"
create_label "Dev Status: Done"         "#00875a" "Defect: verified fixed"

# QA Status (Defects only)
create_label "QA Status: Pending Retest" "#dfe1e6" "Defect: awaiting QA retest"
create_label "QA Status: In Retest"      "#ff991f" "Defect: QA retesting"
create_label "QA Status: Pass"           "#00875a" "Defect: fix verified"
create_label "QA Status: Fail"           "#de350b" "Defect: fix failed, returned to dev"
```

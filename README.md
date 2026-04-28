# KUB Wallet PM Agent — Claude Code Plugin

IT Project Management Agent for software projects (Web, Mobile, Blockchain, Smart Contract).
Covers PRD generation, sprint breakdown, daily standup, defect tracking, and change requests — all via GitLab Issues.

---

## Table of Contents

- [ONBOARDING.md](./ONBOARDING.md) — Step-by-step guide for new and ongoing projects

1. [Prerequisites](#1-prerequisites)
2. [Install the Plugin](#2-install-the-plugin)
3. [One-time GitLab Setup](#3-one-time-gitlab-setup)
4. [Configure Identity & GitLab Credentials](#4-configure-identity--gitlab-credentials)
5. [How to Use](#5-how-to-use)
   - [Auto-trigger (pm-agent)](#auto-trigger--pm-agent)
   - [/pm-prd — PRD Pipeline](#pm-prd--prd-pipeline)
   - [/pm-breakdown — Feature Breakdown](#pm-breakdown--feature-breakdown)
   - [/pm-standup — Daily Standup](#pm-standup--daily-standup)
   - [/pm-bug — Defect Workflow](#pm-bug--defect-workflow)
   - [/pm-cr — Change Request](#pm-cr--change-request)
6. [Folder Structure](#6-folder-structure)
7. [Workflow Overview](#7-workflow-overview)

---

## 1. Prerequisites

| Requirement | Notes |
|---|---|
| Claude Code CLI | `npm install -g @anthropic-ai/claude-code` |
| Self-hosted GitLab | Free tier or above |
| GitLab Personal Access Token | Scope: `api` — Profile → Access Tokens |
| A GitLab project for PM docs | e.g. `kub-wallet-pm` |

---

## 2. Install the Plugin

Run once per machine. Installs for the current project scope:

```bash
claude plugin install https://<your-gitlab-host>/bitkub/kub-wallet-pm
```

To install globally (available in all projects on this machine):

```bash
claude plugin install --scope user https://<your-gitlab-host>/bitkub/kub-wallet-pm
```

Verify installation — in Claude Code, type `/help` and confirm these slash commands appear:
- `/pm-prd`
- `/pm-standup`
- `/pm-bug`
- `/pm-breakdown`

> **Note:** The `pm-agent` skill is model-invoked (auto-triggered) — it does not appear as a slash command.

---

## 3. One-time GitLab Setup

Do this once when setting up the project board. Skip if already done.

### 3a. Create the PM docs repo

Create a new GitLab repo (e.g. `kub-wallet-pm`) with this folder structure:

```
kub-wallet-pm/
├── rfc/
├── grooming/
├── kickoff/
├── prd/
├── breakdown/
├── daily-standup/
└── .gitlab/
    ├── issue_templates/
    └── merge_request_templates/
```

### 3b. Deploy issue and MR templates

Copy from this plugin repo into your GitLab repo:

```bash
cp gitlab/templates/issue/*.md      .gitlab/issue_templates/
cp gitlab/templates/merge_request/*.md  .gitlab/merge_request_templates/
git add .gitlab/ && git commit -m "Add PM issue and MR templates"
git push
```

### 3c. Create all labels (bulk script)

Replace `<host>`, `<project_id>`, and `<token>`, then run the script from `gitlab/repo-structure.md`:

```bash
GITLAB="https://<host>/api/v4"
PROJECT=<project_id>
TOKEN=<your_token>

# Copy and run the full create_label block from gitlab/repo-structure.md
```

This creates all 38 labels: `Kind:*`, `Status:*`, `Priority:*`, `Type:*`, `Platform:*`, `Group:*`, `Dev Status:*`, `QA Status:*`.

### 3d. Set up the Issue Board

In GitLab: **Plan → Issue Boards → New board** (name it after the project, e.g. `KUB Wallet V3`).

Add columns in this order:

| Column | Label filter |
|---|---|
| Todo | `Status: Todo` |
| Ready to Start | `Status: Ready to Start` |
| Working on it | `Status: Working on it` |
| Ready to Review | `Status: Ready to Review` |
| In Review | `Status: In Review` |
| Done | `Status: Done` |

Create a separate board named `Defects` filtered on `Group: Defects`.

### 3e. Create Milestones for known releases

**Plan → Milestones → New milestone** for each release, e.g. `v3.0.0-beta.24`.

### 3f. Protect the main branch

**Settings → Repository → Protected branches** — protect `main`, no direct push.

---

## 4. Configure Identity & GitLab Credentials

The agent reads credentials and team identity from two files in your project root — no need to tell Claude each session.

### 4a. Team roster — `team.yaml` (commit this)

Copy the template and fill in every team member:

```bash
cp <plugin-path>/team.yaml.example team.yaml
```

```yaml
team:
  project: Your Project Name
  members:
    - display_name: Yo Tharit
      gitlab_username: yo.tharit
      role: PM          # PM | PO | Dev | QA | SM | DevOps
      email: yo.tharit@bitkub.com
```

Commit `team.yaml` so all team members share the same roster.

### 4b. Personal credentials — `.env` (never commit)

Each person copies the template and fills in their own values:

```bash
cp <plugin-path>/.env.example .env
```

```env
GITLAB_USERNAME=your.gitlab.username
GITLAB_BASE_URL=https://gitlab.bitkub.com/api/v4
GITLAB_PROJECT_ID=123          # Settings → General → Project ID
GITLAB_TOKEN=glpat-xxxx        # Profile → Access Tokens (scope: api)
```

`.env` is gitignored. Each team member keeps their own copy with their own token.

> **New team member or ongoing project?** See [ONBOARDING.md](./ONBOARDING.md) for full step-by-step integration guides.

---

## 5. How to Use

### Auto-trigger — pm-agent

You do not need a slash command for general PM conversations. The `pm-agent` skill activates automatically when your message contains PM intent.

**Just talk naturally:**

```
"What's the status of the transaction limit feature?"
"Who is working on KUB-42?"
"Assign me to issue #15"
"Is the PRD for registration approved?"
```

The agent reads from GitLab, applies the status rollup rules, and responds with accurate board state.

---

### /pm-prd — PRD Pipeline

Covers: generate a PRD draft → review → approve → lock.

**Generate a new PRD:**
```
/pm-prd transaction-limit
```
The agent scans `rfc/`, `grooming/`, `kickoff/` for matching files, proposes which to use, then drafts `prd/transaction-limit.md` with inline source citations.

**Revise a section:**
```
/pm-prd transaction-limit
> Revise §4 — add a requirement for AA wallet daily limit
```
The agent bumps the version (`0.1 → 0.2`) and adds a Changelog row.

**Approve and lock:**
```
/pm-prd transaction-limit
> PRD approved
```
Sets `version: 1.0`, `status: approved`. PRD is now locked — no silent regeneration.

**Expected output:** `prd/transaction-limit.md` with frontmatter, Changelog table, FRs with citations, ACs, and Source Coverage appendix.

---

### /pm-breakdown — Feature Breakdown

Covers: propose Working Items from approved PRD → review YAML → create GitLab Issues.

> PRD must be approved before breakdown can start.

**Propose breakdown:**
```
/pm-breakdown transaction-limit
```
The agent reads `prd/transaction-limit.md` (approved), proposes a YAML grouped by `[Client]`, `[Service]`, `[Smart Contract]`, `[Chain]`, and QA groups. Saves draft to `breakdown/transaction-limit_v0.1.yaml`.

**Review and edit YAML inline, then approve:**
```
> Breakdown approved
```

**Create GitLab Issues:**
```
> Apply the breakdown
```
The agent:
1. Archives `breakdown/transaction-limit_v1.0.yaml`
2. Creates one GitLab Issue per Working Item with the correct labels and milestone
3. Displays all created issues as a markdown table for verification

**Dev/QA create Tasks** (child issues) under each Working Item after import — the agent does not create Tasks at this stage.

---

### /pm-standup — Daily Standup

Three modes: solo update, team report, quick query.

#### Mode A — Log your own progress

```
/pm-standup yo.tharit
```

The agent fetches your open Tasks from GitLab and presents a YAML for you to fill in:

```yaml
standup:
  user: Yo Tharit
  date: 2026-04-29
  tasks:
    - id: "#42"
      name: "Implement Progress Bar"
      current_status: Working on it
      yesterday: "Set up component skeleton"
      today: "Wire up API data"
      blockers: ""
      new_status: ""
  off_board_work: ""
```

Fill it in, confirm, and the agent:
- Updates the `Status:*` label on each task in GitLab
- Posts a standup note on each issue
- Recomputes the parent Working Item status
- Appends your section to `daily-standup/2026-04-29.md`

#### Mode B — Generate team report (PM / Scrum Master)

```
/pm-standup
> Generate today's standup
```

Reads all open Task issues, groups by assignee, outputs `daily-standup/2026-04-29.md` with:
1. Roadblocks & Problems (first)
2. Per-member status
3. Working Item progress table
4. Help requested / dependencies

#### Mode C — Quick status query

No command needed — just ask:
```
"What is Somchai working on?"
"Show me the status of issue #15"
"Where are we on the transaction limit feature?"
```

Returns a compact markdown table. No file written.

---

### /pm-bug — Defect Workflow

Covers the full defect lifecycle: open → dev picks up → ready for QA → retest → pass/fail.

**QA opens a defect:**
```
/pm-bug
```
The agent asks for:
- Title
- Feature area
- Steps to reproduce
- Priority
- Platform
- Release version where found
- Dev assignee
- QA reporter (defaults to you)

Confirms the row, then creates a GitLab Issue in `Group: Defects` with `Dev Status: Todo` and `QA Status: Pending Retest`.

**Dev picks up:**
```
/pm-bug
> I'm picking up defect #55
```

**Dev marks ready for QA:**
```
/pm-bug
> Bug #55 is ready for QA
```

**QA retests — pass:**
```
/pm-bug
> Defect #55 passed retest
```
Issue is closed. Labels: `Dev Status: Done`, `QA Status: Pass`.

**QA retests — fail:**
```
/pm-bug
> Defect #55 failed — the limit still resets incorrectly on AA wallets
```
Returns to dev. Failure notes appended to issue. Labels: `Dev Status: Todo`, `QA Status: Fail`.

---

### /pm-cr — Change Request

Covers: log a CR → impact assessment → approve/reject → apply (revise PRD or create issues).

Use this when a **stakeholder requests a change to an existing approved feature or PRD** — not for new features (`/pm-prd`) or broken things (`/pm-bug`).

**Log a new CR:**
```
/pm-cr transaction-limit
```
The agent asks for: title, description of the change (verbatim from stakeholder), requester, priority. Saves `cr/transaction-limit-001.yaml` with `status: draft`.

**Assess impact:**
```
/pm-cr transaction-limit
> Assess the impact of CR-transaction-limit-001
```
The agent reads the affected PRD, identifies which sections/FRs are impacted, determines whether the PRD text needs updating, and lists any new Working Items needed. Updates the YAML impact block.

**Approve or reject:**
```
> Approve CR-transaction-limit-001
> Reject CR-transaction-limit-001 — out of scope for this release
```

**Apply an approved CR — two paths:**

*Path A: PRD change required* — agent revises the PRD (bumps to `v1.1`), cites each change as `[CR-transaction-limit-001 2026-04-29]`, presents diff for approval, then triggers `/pm-breakdown` for any new Working Items.

*Path B: New items only, no PRD change* — agent creates GitLab Issues directly with `Type: CR` label, linking back to the CR YAML.

**Quick reference — CR vs other types:**

| Situation | Command |
|---|---|
| New feature from scratch | `/pm-prd` |
| Something is broken | `/pm-bug` |
| Stakeholder wants to change an existing feature | `/pm-cr` |
| Internal improvement or technical debt | `/pm-cr` or just open an Issue |

---

## 6. Folder Structure

```
bitkub-pm-skills/              ← this plugin repo
├── .claude-plugin/
│   └── plugin.json            ← plugin metadata
├── skills/
│   ├── pm-agent/SKILL.md      ← model-invoked, auto-triggers
│   ├── pm-prd/SKILL.md        ← /pm-prd
│   ├── pm-standup/SKILL.md    ← /pm-standup
│   ├── pm-bug/SKILL.md        ← /pm-bug
│   ├── pm-breakdown/SKILL.md  ← /pm-breakdown
│   └── pm-cr/SKILL.md         ← /pm-cr
├── gitlab/
│   ├── repo-structure.md      ← GitLab setup guide + label creation script
│   ├── labels.yaml            ← all 38 label definitions
│   ├── api-integration.md     ← full GitLab API call reference
│   └── templates/
│       ├── issue/
│       │   ├── working-item.md
│       │   ├── task.md
│       │   └── defect.md
│       └── merge_request/
│           └── prd-review.md
└── generation-prompt.md       ← full agent specification (source of truth)
```

Your **PM docs repo** (`kub-wallet-pm`) on GitLab holds the actual project artifacts:
```
kub-wallet-pm/
├── rfc/           ← authored by dev team
├── grooming/      ← authored by PM + Dev + PO
├── kickoff/       ← authored by PO
├── prd/           ← generated by agent
├── breakdown/     ← generated by agent
├── cr/            ← generated by agent (CR-<feature>-<NNN>.yaml)
└── daily-standup/ ← generated by agent
```

---

## 7. Workflow Overview

```
                    ┌─────────────┐
  Dev team ────────▶│  RFC (.md)  │
  PM/PO ───────────▶│  Grooming   │  (manual, read-only)
  PO ──────────────▶│  Kickoff    │
                    └──────┬──────┘
                           │ /pm-prd <feature>
                    ┌──────▼──────┐
                    │  PRD draft  │  prd/<feature>.md v0.x
                    │   (review   │  ← MR on GitLab
                    │  via MR)    │
                    └──────┬──────┘
                           │ "PRD approved"
                    ┌──────▼──────┐
                    │ PRD v1.0    │  locked, status: approved
                    └──────┬──────┘
                           │ /pm-breakdown <feature>
                    ┌──────▼──────┐
                    │  Breakdown  │  breakdown/<feature>_v0.1.yaml
                    │   YAML      │  ← review inline
                    └──────┬──────┘
                           │ "Apply breakdown"
                    ┌──────▼──────┐
                    │  GitLab     │  Working Item issues created
                    │  Issues     │  with labels + milestone
                    └──────┬──────┘
                           │ Dev/QA create child Task issues
                    ┌──────▼──────┐
                    │  Daily      │  /pm-standup — Mode A/B/C
                    │  Standup    │  status labels updated via API
                    └─────────────┘
```

**CR path (change to existing feature):**
```
Stakeholder request
       │ /pm-cr <feature>
┌──────▼──────┐
│  CR YAML    │  cr/<feature>-001.yaml — Log + Impact Assessment
└──────┬──────┘
       │ "Approve CR"
       ├─── prd_change_needed: true ──▶ /pm-prd (revise v1.1) ──▶ /pm-breakdown
       └─── prd_change_needed: false ─▶ GitLab Issues (Type: CR)
```

**Hard rules that always apply (regardless of skill):**
- Never fabricate — every value traces to a source document
- Confirm before writing — always show proposed changes first
- WI status is a rollup — derived from child Tasks, never set directly
- `Ready to Review → Done` requires explicit user approval
- PRD pipeline gates are never skipped

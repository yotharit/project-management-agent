# PM Agent — Claude Code Plugin

IT Project Management Agent for software projects (Web, Mobile, Blockchain, Smart Contract).
Covers PRD generation, sprint breakdown, daily standup, defect tracking, and change requests — all via GitLab or GitHub Issues.

---

## Table of Contents

- [ONBOARDING.md](./ONBOARDING.md) — Step-by-step guide for new and ongoing projects

1. [Prerequisites](#1-prerequisites)
2. [Install the Plugin](#2-install-the-plugin)
3. [One-time Git Provider Setup](#3-one-time-git-provider-setup)
4. [Configure Identity & Credentials](#4-configure-identity--credentials)
5. [How to Use](#5-how-to-use)
   - [/pm-setup — Repository Setup](#pm-setup--repository-setup)
   - [Auto-trigger (pm-agent)](#auto-trigger--pm-agent)
   - [/pm-prd — PRD Pipeline](#pm-prd--prd-pipeline)
   - [/pm-breakdown — Feature Breakdown](#pm-breakdown--feature-breakdown)
   - [/pm-standup — Daily Standup](#pm-standup--daily-standup)
   - [/pm-bug — Defect Workflow](#pm-bug--defect-workflow)
   - [/pm-cr — Change Request](#pm-cr--change-request)
6. [Folder Structure](#6-folder-structure)
7. [Workflow Overview](#7-workflow-overview)
8. [Gitflow Model](#8-gitflow-model)

---

## 1. Prerequisites

| Requirement | Notes |
|---|---|
| Claude Code CLI | `npm install -g @anthropic-ai/claude-code` |
| GitLab **or** GitHub | GitLab: self-hosted, Free tier or above. GitHub: any plan |
| Personal Access Token | GitLab: scope `api` — Profile → Access Tokens. GitHub: scope `repo` — Settings → Developer settings |
| A project for PM docs | e.g. `pm-project` — GitLab or GitHub |

---

## 2. Install the Plugin

Install once per machine. Skills become available system-wide in every Claude Code session.

```
/plugin marketplace add https://github.com/yotharit/project-management-agent
/plugin install project-management-agent
/reload-plugins
```

Verify by typing `/help` — you should see `/pm-setup`, `/pm-prd`, `/pm-standup`, `/pm-bug`, `/pm-breakdown`, `/pm-cr`.

To update later:
```
/plugin update project-management-agent
/reload-plugins
```

> **Note:** The `pm-agent` skill is model-invoked (auto-triggered) — it does not appear as a slash command. Per-project config (`.env`, `team.yaml`) is still required in each PM docs repo — run `/pm-setup` in your PM docs repo to configure it.

### First time in a new PM docs repo?

After installing the plugin, open Claude Code **in your PM docs repo** and run:

```
/pm-setup
```

This sets up folders, labels, templates, `team.yaml`, and the `develop` branch in one guided flow. See §3 for what it automates and what still requires the provider web UI.

---

## 3. One-time Git Provider Setup

Do this once when setting up the project board. Skip if already done.

### 3a. Create the PM docs repo

Create a new repo (e.g. `pm-project`) with this folder structure:

**GitLab:**
```
pm-project/
├── rfc/
├── grooming/
├── kickoff/
├── prd/
├── breakdown/
├── cr/
├── daily-standup/
└── .gitlab/
    ├── issue_templates/
    └── merge_request_templates/
```

**GitHub:**
```
pm-project/
├── rfc/
├── grooming/
├── kickoff/
├── prd/
├── breakdown/
├── cr/
├── daily-standup/
└── .github/
    └── ISSUE_TEMPLATE/
```

### 3b. Deploy issue templates

Copy from this plugin repo into your PM docs repo (replace `$PLUGIN` and `$PM_REPO`):

**GitLab:**
```bash
cp "$PLUGIN/gitlab/templates/issue/"*.md          "$PM_REPO/.gitlab/issue_templates/"
cp "$PLUGIN/gitlab/templates/merge_request/"*.md  "$PM_REPO/.gitlab/merge_request_templates/"
```

**GitHub:**
```bash
cp "$PLUGIN/gitlab/templates/issue/"*.md  "$PM_REPO/.github/ISSUE_TEMPLATE/"
```

### 3c. Create all labels (bulk script)

See `knowledge/git-provider.md` for the label creation API for both providers.

**GitLab** — replace `<host>`, `<project_id>`, and `<token>`:
```bash
GITLAB="https://<host>/api/v4"
PROJECT=<project_id>
TOKEN=<your_token>

# Copy and run the full create_label block from gitlab/repo-structure.md
```

**GitHub** — replace `<owner>`, `<repo>`, and `<token>`:
```bash
GH_OWNER=<owner>; GH_REPO=<repo>; TOKEN=<your_token>

# POST /repos/$GH_OWNER/$GH_REPO/labels — {"name":"...", "color":"xxxxxx"} (no # in color)
# See knowledge/git-provider.md for the full label list
```

This creates all 38 labels: `Kind:*`, `Status:*`, `Priority:*`, `Type:*`, `Platform:*`, `Group:*`, `Dev Status:*`, `QA Status:*`.

### 3d. Set up the Issue Board

In GitLab: **Plan → Issue Boards → New board** (name it after the project, e.g. `Your Project`).

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

### 3f. Protect branches

**Settings → Repository → Protected branches**

| Branch | Rule |
|---|---|
| `main` | No direct push. All changes via MR from `develop`. |
| `develop` | No direct push. All artifact branches merge here first. |

---

## 4. Configure Identity & Credentials

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
      username: yo.tharit
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
GIT_PROVIDER=gitlab            # gitlab | github

# GitLab (used when GIT_PROVIDER=gitlab)
GITLAB_USERNAME=your.gitlab.username
GITLAB_BASE_URL=https://gitlab.bitkub.com/api/v4
GITLAB_PROJECT_ID=123          # Settings → General → Project ID
GITLAB_TOKEN=glpat-xxxx        # Profile → Access Tokens (scope: api)

# GitHub (used when GIT_PROVIDER=github)
# GITHUB_USERNAME=your.github.username
# GITHUB_OWNER=org-or-username
# GITHUB_REPO=repo-name
# GITHUB_TOKEN=ghp_xxxx        # Settings → Developer settings (scope: repo)
```

`.env` is gitignored. Each team member keeps their own copy with their own token.

> **New team member or ongoing project?** See [ONBOARDING.md](./ONBOARDING.md) for full step-by-step integration guides.

---

## 5. How to Use

### /pm-setup — Repository Setup

Run once per PM docs repository after installing the plugin.

```
/pm-setup
```

Automates: folders, labels (38), issue/MR templates, `team.yaml`, `develop` branch, commit & push. Prints a checklist of the remaining manual provider UI steps (Issue Board, Milestones, Branch Protection).

---

### Auto-trigger — pm-agent

You do not need a slash command for general PM conversations. The `pm-agent` skill activates automatically when your message contains PM intent.

**Just talk naturally:**

```
"What's the status of the transaction limit feature?"
"Who is working on ITEM-42?"
"Assign me to issue #15"
"Is the PRD for registration approved?"
```

The agent reads from the issue tracker, applies the status rollup rules, and responds with accurate board state.

**Pick up a task (agent handles Gitflow suggestion automatically):**
```
"I'm picking up issue #42"
"Assign me to #42"
```
The agent:
1. Fetches live issue status — warns if already picked up or closed
2. Updates labels: `Status: Working on it` + assignee
3. Posts a comment on the issue with:
   - **Branch name** ready to use: `feature/42-implement-wallet-progress-bar`
   - **Claude Code prompt** — pre-filled with task name, PRD reference, platform, description

---

### /pm-prd — PRD Pipeline

Covers: generate a PRD draft → review → approve → lock.

**Generate from source documents (RFC / grooming / kickoff available):**
```
/pm-prd transaction-limit
```
The agent scans `rfc/`, `grooming/`, `kickoff/` for matching files, proposes which to use, then drafts `prd/transaction-limit.md` with inline source citations.

**Generate from scratch (no source documents):**
```
/pm-prd transaction-limit
> from scratch
```
The agent runs a guided intake interview — asking questions in four groups (Identity, Scope, Requirements, Validation) — then drafts the PRD with `[Intake YYYY-MM-DD]` citations.

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

**Gitflow:** `prd/<feature>` → commit → push → MR → **`develop`** (QA validates) → MR → **`main`** (PM gate)

---

### /pm-breakdown — Feature Breakdown

Covers: propose Working Items from approved PRD → review YAML → create Issues.

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

**Create Issues:**
```
> Apply the breakdown
```
The agent:
1. Archives `breakdown/transaction-limit_v1.0.yaml`
2. Creates one issue per Working Item with the correct labels and milestone
3. Displays all created issues as a markdown table for verification

**Dev/QA create Tasks** (child issues) under each Working Item after import — the agent does not create Tasks at this stage.

**Gitflow:** `breakdown/<feature>` → commit → push → MR → **`develop`** (QA validates issue set) → MR → **`main`** (PM gate)

---

### /pm-standup — Daily Standup

Three modes: solo update, team report, quick query.

#### Mode A — Log your own progress

```
/pm-standup yo.tharit
```

The agent fetches your open Tasks from the issue tracker and presents a YAML for you to fill in:

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
- **Fetches live issue status** from the issue tracker before each update — warns if status has drifted from what you entered
- Updates the `Status:*` label on each task in GitLab
- Posts a standup note on each issue
- **First pick-up detection:** if task moves from `Todo`/`Ready to Start` → `Working on it`, also posts branch name + Claude Code prompt on the issue
- Recomputes the parent Working Item status
- Appends your section to `daily-standup/2026-04-29.md`

**Gitflow:** `standup/<YYYY-MM-DD>` → commit → push → MR → **`develop`** → MR → **`main`** (PM gate)

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

Confirms the row, then creates an issue in `Group: Defects` with `Dev Status: Todo` and `QA Status: Pending Retest`.

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

**Gitflow:** Defect CRUD is API-only — no file commits needed. Exception: `team.yaml` self-registration → `chore/team-register-<username>` → MR → **`develop`**

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

*Path B: New items only, no PRD change* — agent creates issues directly with `Type: CR` label, linking back to the CR YAML.

**Gitflow:** `cr/<feature>-<NNN>` → commit each stage → push → MR → **`develop`** (QA validates) → MR → **`main`** (PM gate). Path A also commits PRD changes on the same branch.

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
│   ├── pm-setup/SKILL.md      ← /pm-setup  (run once per PM docs repo)
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
├── knowledge/
│   ├── rfc-template.md        ← RFC authoring guide (for dev team)
│   └── mom-template.md        ← Meeting/grooming notes template (for PM)
└── initial-generation-prompt/
    └── generation-prompt.md   ← DEPRECATED: original monday.com spec (historical only)
```

Your **PM docs repo** (`pm-project`) on GitLab holds the actual project artifacts:
```
pm-project/
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
  Dev team ────────▶┌─────────────┐
  PM/PO ───────────▶│  RFC (.md)  │
  PO ──────────────▶│  Grooming   │  (manual, read-only)
                    │  Kickoff    │
                    └──────┬──────┘    ╔══════════════════════╗
                           │           ║  No documents?       ║
                           │           ║  /pm-prd (scratch)   ║
                           │           ║  → intake interview  ║
                           │           ╚══════════╤═══════════╝
                           └──────────────────────┘
                           │ /pm-prd <feature>
                           │ branch: prd/<feature>
                    ┌──────▼──────┐
                    │  PRD draft  │  prd/<feature>.md v0.x
                    │   v0.x      │  commit → push → MR → develop
                    └──────┬──────┘
                           │ QA validates on develop
                           │ "PRD approved" → merge MR
                    ┌──────▼──────┐
                    │ PRD v1.0    │  locked — develop → main (PM gate)
                    └──────┬──────┘
                           │ /pm-breakdown <feature>
                           │ branch: breakdown/<feature>
                    ┌──────▼──────┐
                    │  Breakdown  │  breakdown/<feature>_v0.1.yaml
                    │   YAML      │  commit → push → MR → develop
                    └──────┬──────┘
                           │ "Apply breakdown" — Issues created
                           │ QA validates issue set on develop
                    ┌──────▼──────┐
                    │  Issues     │  Working Items with labels + milestone
                    │  (Board)    │  develop → main (PM gate)
                    └──────┬──────┘
                           │ Dev picks up task (via pm-agent / pm-standup)
                           │ Agent posts: branch feature/<iid>-<slug>
                           │             + Claude Code prompt on issue
                    ┌──────▼──────┐
                    │  Daily      │  /pm-standup — Mode A/B/C
                    │  Standup    │  branch: standup/<date> → MR → develop
                    └─────────────┘
```

**CR path (change to existing feature):**
```
Stakeholder request
       │ /pm-cr <feature>
       │ branch: cr/<feature>-001
┌──────▼──────┐
│  CR YAML    │  cr/<feature>-001.yaml
│  Log +      │  commit each stage → push
│  Assessment │
└──────┬──────┘
       │ "Approve CR"
       ├─── prd_change_needed: true ──▶ revise PRD v1.1 (same branch) ──▶ /pm-breakdown
       └─── prd_change_needed: false ─▶ Issues (Type: CR)
       │
       └── MR → develop (QA validates) → main (PM gate)
```

**Hard rules that always apply (regardless of skill):**
- Never fabricate — every value traces to a source document or recorded intake answer
- Confirm before writing, pushing, or creating MRs
- WI status is a rollup — derived from child Tasks, never set directly
- `Ready to Review → Done` requires explicit user approval
- PRD pipeline gates are never skipped
- Agent never merges MRs or creates `develop` → `main` MR

---

## 8. Gitflow Model

All PM artifact writes follow a **branch-per-artifact → MR/PR → `develop` → MR/PR → `main`** model.

### Branch responsibilities

| Who | Branch | Target | Gate |
|---|---|---|---|
| Agent | `prd/<feature>` | `develop` | Team reviews MR/PR |
| Agent | `breakdown/<feature>` | `develop` | Team reviews MR/PR |
| Agent | `cr/<feature>-<NNN>` | `develop` | Team reviews MR/PR |
| Agent | `standup/<YYYY-MM-DD>` | `develop` | Team reviews MR/PR |
| Agent | `chore/team-register-<username>` | `develop` | Team reviews MR/PR |
| PM/PO | `develop` | `main` | QA sign-off complete |
| Dev | `feature/<iid>-<slug>` | (code repo) | Per code repo policy |

### Step-by-step for every artifact

```
1. git checkout develop && git pull origin develop
2. git checkout -b <branch-name>
3. [write / edit file]
4. git add <file> && git commit -m "<conventional message>"
5. git push origin <branch-name>
6. Create MR/PR targeting **develop**
   [GitLab] POST /projects/:id/merge_requests
   [GitHub] POST /repos/:owner/:repo/pulls
   → report MR/PR URL to user
7. Team reviews and merges MR into develop
8. QA tests PM artifacts on develop  ← Dev Release
9. PM/PO opens develop → main MR when QA signs off
```

### Commit message conventions

| Skill | Format | Example |
|---|---|---|
| pm-prd | `prd(<slug>): <draft\|revise\|approve> v<N>` | `prd(tx-limit): draft v0.1 — initial` |
| pm-breakdown | `breakdown(<slug>): <draft\|revise\|approve> v<N>` | `breakdown(tx-limit): approve v1.0` |
| pm-cr | `cr(<slug>-<NNN>): <log\|impact\|approve\|apply>` | `cr(tx-limit-001): apply — revise PRD v1.1` |
| pm-standup | `standup: <YYYY-MM-DD> — <username>` | `standup: 2026-04-29 — yo.tharit` |
| team.yaml | `chore(team): register <display_name>` | `chore(team): register Yo Tharit` |

### Task pick-up (code repo branch — suggested by agent, not created)

When a developer picks up a task, the agent posts on the issue:

```
Branch:  feature/42-implement-wallet-progress-bar

Claude Code prompt:
  Implement "Implement daily limit Progress Bar" (Task #42, Working Item #15).
  Context:
  - PRD: prd/transaction-limit.md §6.1
  - Platform: Mobile App | Priority: High
  Description: <task description>
  Start by reading the PRD section above, then implement.
```

The developer creates `feature/<iid>-<slug>` in the **code repository** per the code repo's own branching policy. The agent does not create this branch.

### Hard constraints

- Agent confirms with user before every `push` and MR/PR creation
- Agent never pushes directly to `develop` or `main`
- Agent never merges any MR/PR
- Agent never creates the `develop` → `main` MR/PR — that is the PM/PO gate action after QA sign-off

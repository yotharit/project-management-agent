# PM Skills — Integration Guide

> How to integrate the PM Agent skill set into your project.
> Choose your path: **New Project** or **Ongoing Project**.

## Quick start — use the scripts

Two scripts handle the setup automatically. Manual steps are only needed for things the GitLab Free API doesn't expose (board columns, branch protection).

| Script | Who runs it | When |
|---|---|---|
| `scripts/setup.sh` | PM / project lead | Once per project |
| `scripts/setup-member.sh` | Each team member | Once per person per machine |

```bash
# PM/lead — from the PM docs repo root:
/path/to/bitkub-pm-skills/scripts/setup.sh

# Each team member — from the PM docs repo root:
/path/to/bitkub-pm-skills/scripts/setup-member.sh
```

The scripts detect new vs ongoing automatically, are idempotent (safe to re-run), and verify your GitLab connection before doing anything.

**After running the scripts, only 3 manual steps remain in GitLab UI:**
1. Create Issue Board columns (Plan → Issue Boards)
2. Create Milestones for known releases
3. Protect the `main` branch (Settings → Repository)

---

## Table of Contents

- [Path A — New Project](#path-a--new-project)
  - [Step 1: Install the plugin](#step-1-install-the-plugin)
  - [Step 2: Run setup.sh](#step-2-run-setupsh)
  - [Step 3: Complete GitLab UI steps](#step-3-complete-gitlab-ui-steps)
  - [Step 4: Each team member runs setup-member.sh](#step-4-each-team-member-runs-setup-membersh)
  - [Step 5: Verify and start your first feature](#step-5-verify-and-start-your-first-feature)
- [Path B — Ongoing Project](#path-b--ongoing-project)
  - [Step 1: Install the plugin](#step-1-install-the-plugin-1)
  - [Step 2: Run setup.sh (ongoing mode auto-detected)](#step-2-run-setupsh-ongoing-mode-auto-detected)
  - [Step 3: Each team member runs setup-member.sh](#step-3-each-team-member-runs-setup-membersh)
  - [Step 4: Migrate existing board data (optional)](#step-4-migrate-existing-board-data-optional)
  - [Step 5: Validate and start daily standup](#step-5-validate-and-start-daily-standup)
- [Adding a new team member (both paths)](#adding-a-new-team-member-both-paths)
- [Updating a role](#updating-a-role)
- [Troubleshooting](#troubleshooting)

---

## Path A — New Project

Use this path when you are starting a brand-new project with no existing board or task history.

---

### Step 1: Install the plugin

Run once per machine, inside your project directory:

```bash
claude plugin install https://<your-gitlab-host>/bitkub/bitkub-pm-skills
```

To install globally (all projects on this machine):

```bash
claude plugin install --scope user https://<your-gitlab-host>/bitkub/bitkub-pm-skills
```

Verify: open Claude Code and type `/help`. You should see `/pm-prd`, `/pm-standup`, `/pm-bug`, `/pm-breakdown`, `/pm-cr` listed.

---

### Step 2: Run setup.sh

Create and `cd` into your PM docs repo (e.g. `kub-wallet-pm`), then run:

```bash
/path/to/bitkub-pm-skills/scripts/setup.sh
```

The script will interactively prompt for:
- GitLab host URL, project ID, and your personal access token
- Your display name, GitLab username, role, and email

It will automatically:
- Create all required folders (`rfc/`, `grooming/`, `kickoff/`, `prd/`, `breakdown/`, `cr/`, `daily-standup/`)
- Copy issue and MR templates into `.gitlab/`
- Create all 38 GitLab labels (skips any that already exist)
- Create `team.yaml` with you as the first member
- Create your personal `.env`
- Add `.env` to `.gitignore`

When the script finishes, commit and push:

```bash
git add team.yaml .gitignore .gitlab/
git commit -m "Init PM agent setup"
git push
```

---

### Step 3: Complete GitLab UI steps

These three steps require the GitLab web UI (not available via API on Free tier):

**Issue Board — Plan → Issue Boards → New board** (name it after your project):

| Column | Label filter |
|---|---|
| Todo | `Status: Todo` |
| Ready to Start | `Status: Ready to Start` |
| Working on it | `Status: Working on it` |
| Ready to Review | `Status: Ready to Review` |
| In Review | `Status: In Review` |
| Done | `Status: Done` |

Create a second board named `Defects` filtered on `Group: Defects`.

**Milestones — Plan → Milestones → New milestone** for each known release, e.g. `v1.0.0`.

**Branch protection — Settings → Repository → Protected branches** → protect `main`, no direct push.

---

### Step 4: Each team member runs setup-member.sh

Share this command with every team member. Each person runs it **once on their own machine** from the PM docs repo root:

```bash
/path/to/bitkub-pm-skills/scripts/setup-member.sh
```

The script:
1. Prompts for their GitLab credentials
2. Verifies their token and confirms the username matches
3. Checks if they're in `team.yaml` — if not, adds them and prompts to commit
4. Writes their personal `.env`

---

### Step 5: Verify and start your first feature

Open Claude Code in the PM docs repo and run:

```
/pm-standup
```

Expected: the agent greets you by display name and shows your open tasks (empty on a new board is fine).

Then start your first feature:

```
1. Dev team writes RFC → rfc/YOUR-RFC-001_<slug>.md
2. PM runs grooming → grooming/YYYY-MM-DD-<feature>.md
3. PO runs kickoff → kickoff/YYYY-MM-DD-kickoff-<feature>.md
4. /pm-prd <feature>          → generates PRD draft
5. Review via MR, then "PRD approved"
6. /pm-breakdown <feature>    → proposes Working Items as YAML
7. "Apply breakdown"          → creates GitLab Issues
8. Dev/QA create Task issues under each Working Item
9. /pm-standup (daily)        → logs progress, updates labels
```

---

## Path B — Ongoing Project

Use this path when your project already has a GitLab board, existing issues, and team members who are already working.

---

### Step 1: Install the plugin

Same as Path A Step 1.

```bash
claude plugin install https://<your-gitlab-host>/bitkub/bitkub-pm-skills
```

---

### Step 2: Run setup.sh (ongoing mode auto-detected)

From your PM docs repo root (or create one if you have a separate docs repo):

```bash
/path/to/bitkub-pm-skills/scripts/setup.sh
```

The script detects that `team.yaml` or `prd/` already exists and runs in **ongoing mode** — it will not overwrite any existing files. It will:

- Create any missing folders (`rfc/`, `grooming/`, etc.) — skips existing ones
- Copy any missing `.gitlab/` templates — skips existing ones
- Create any missing GitLab labels — skips labels that already exist
- Add you as the first member in `team.yaml` (if it doesn't exist yet), or append you to an existing one
- Create your `.env` if it doesn't exist

After the script finishes, add existing team members to `team.yaml` manually if they're not there yet. You can find current assignees from your GitLab project:

```bash
curl -s "https://<host>/api/v4/projects/<id>/issues?state=opened&per_page=100" \
  -H "PRIVATE-TOKEN: <your_token>" \
  | jq -r '.[].assignees[].username' | sort -u
```

Commit and push:

```bash
git add team.yaml .gitignore .gitlab/
git commit -m "Add PM agent setup to project"
git push
```

---

### Step 3: Each team member runs setup-member.sh

Same as Path A Step 4 — each person runs:

```bash
/path/to/bitkub-pm-skills/scripts/setup-member.sh
```

The script handles self-registration into `team.yaml` automatically if they're not listed yet.

---

### Step 4: Migrate existing board data (optional)

If you have existing Working Items and Tasks in a monday.com XLSX export, the agent can migrate them to GitLab Issues in one pass.

> Skip this step if your board is already fully in GitLab Issues.

Provide the XLSX file to Claude and run:

```
Migrate this XLSX to GitLab issues
```

The agent will:
1. Parse the XLSX — Working Items and Tasks per the board schema
2. Validate — flag missing Type, Priority, duplicate IDs, unknown statuses
3. Recompute — apply status rollup rules to all Working Items
4. Show a summary and wait for your approval
5. Create GitLab Issues for each Working Item and Task (with `Legacy ID: KUB-XXXX` in description)
6. Report counts and any flagged items

After confirming, review 5–10 issues in GitLab to verify labels, milestones, and `Part of #<iid>` parent–child links look correct.

---

### Step 5: Validate and start daily standup

Ask the agent to validate the board state:

```
What's the current status of the board?
```

The agent will recompute WI statuses from child Tasks, flag mismatches, and list WIs with missing data. Fix any flagged issues, then start daily standups immediately:

**Each team member (Mode A):**
```
/pm-standup
```

**PM or Scrum Master — team report (Mode B):**
```
/pm-standup
> Generate today's standup
```

---

## Adding a new team member (both paths)

The new member runs one script from the PM docs repo root:

```bash
# Pull latest team.yaml first
git pull

# Then run the member setup script
/path/to/bitkub-pm-skills/scripts/setup-member.sh
```

The script:
1. Prompts for their GitLab credentials
2. Verifies the token and confirms the username matches
3. If not in `team.yaml` — prompts for display name and role, appends the entry, and reminds them to commit
4. Writes their personal `.env`

They then commit and push `team.yaml`:

```bash
git add team.yaml && git commit -m "Add <Name> to team roster" && git push
```

> Always `git pull` before running the script when multiple people are onboarding at the same time, to avoid merge conflicts on `team.yaml`.

---

## Updating a role

Roles only update on explicit command — the agent never infers a role change from your behavior.

Tell the agent directly:

```
Update my role to PO
```

or

```
Update Noom's role to SM
```

The agent updates `team.yaml`, shows the diff, and confirms before writing. Commit the change:

```bash
git add team.yaml && git commit -m "Update <Name> role to <new role>"
git push
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Agent asks for GitLab URL / project ID every session | `.env` not found or `GITLAB_BASE_URL` is blank | Check `.env` exists in the project root. Make sure it has no typos. |
| Agent greets you by wrong name | `gitlab_username` in `.env` doesn't match the entry in `team.yaml` | Check that `GITLAB_USERNAME` in `.env` exactly matches `gitlab_username` in `team.yaml` (case-sensitive). |
| "You're not in team.yaml" every session | `team.yaml` is not committed or is out of date | `git pull` to get the latest `team.yaml`. If self-registration wrote a local change, commit and push it. |
| `/pm-standup` returns no tasks | Your GitLab token lacks `api` scope, or tasks are already `Done`/`Declined` | Re-generate your token with `api` scope. Verify your open tasks in GitLab directly. |
| WI status looks wrong on the board | GitLab Free doesn't compute status automatically | Ask the agent: "Recompute WI statuses" — it will re-read all child Tasks and correct the labels. |
| Breakdown fails: "PRD not approved" | The PRD `status` field is still `draft` | Run `/pm-prd <feature>` and say "PRD approved" to lock it before running breakdown. |
| CR Path A: PRD didn't version-bump | The approved PRD was edited directly instead of via the agent | Always use `/pm-cr` or `/pm-prd` for post-approval changes. Direct edits skip versioning. |

# PM Skills — Integration Guide

> How to integrate the PM Agent skill set into your project.
> Choose your path: **New Project** or **Ongoing Project**.

## Table of Contents

- [Path A — New Project](#path-a--new-project)
  - [Step 1: Create the PM docs repo and folder structure](#step-1-create-the-pm-docs-repo-and-folder-structure)
  - [Step 2: Copy issue and MR templates](#step-2-copy-issue-and-mr-templates)
  - [Step 3: Copy PM skills](#step-3-copy-pm-skills)
  - [Step 4: Create all GitLab labels](#step-4-create-all-gitlab-labels)
  - [Step 5: Create team.yaml](#step-5-create-teamyaml)
  - [Step 6: Add .env to .gitignore](#step-6-add-env-to-gitignore)
  - [Step 7: Commit and push](#step-7-commit-and-push)
  - [Step 8: Complete GitLab UI steps](#step-8-complete-gitlab-ui-steps)
  - [Step 9: Each team member sets up credentials](#step-9-each-team-member-sets-up-credentials)
  - [Step 10: Verify and start your first feature](#step-10-verify-and-start-your-first-feature)
- [Path B — Ongoing Project](#path-b--ongoing-project)
  - [Step 1: Create missing folders](#step-1-create-missing-folders)
  - [Step 2: Copy missing templates](#step-2-copy-missing-templates)
  - [Step 3: Copy PM skills](#step-3-copy-pm-skills-1)
  - [Step 4: Create missing labels](#step-4-create-missing-labels)
  - [Step 5: Update team.yaml](#step-5-update-teamyaml)
  - [Step 6: Commit and push](#step-6-commit-and-push)
  - [Step 7: Each team member sets up credentials](#step-7-each-team-member-sets-up-credentials)
  - [Step 8: Migrate existing board data (optional)](#step-8-migrate-existing-board-data-optional)
  - [Step 9: Validate and start daily standup](#step-9-validate-and-start-daily-standup)
- [Adding a new team member (both paths)](#adding-a-new-team-member-both-paths)
- [Updating a role](#updating-a-role)
- [Troubleshooting](#troubleshooting)

---

## Path A — New Project

Use this path when you are starting a brand-new project with no existing board or task history.

---

### Step 1: Create the PM docs repo and folder structure

Create a new GitLab repo (e.g. `kub-wallet-pm`) and clone it locally. From the repo root, create all required folders:

```bash
mkdir -p rfc grooming kickoff prd breakdown cr daily-standup \
         .gitlab/issue_templates .gitlab/merge_request_templates
```

---

### Step 2: Copy issue and MR templates

From this plugin repo root, copy the templates into your PM docs repo. Replace `$PM_REPO` with the path to your cloned PM docs repo:

```bash
PLUGIN=/path/to/bitkub-pm-skills   # where you cloned this plugin repo
PM_REPO=/path/to/kub-wallet-pm     # your PM docs repo

cp "$PLUGIN/gitlab/templates/issue/"*.md       "$PM_REPO/.gitlab/issue_templates/"
cp "$PLUGIN/gitlab/templates/merge_request/"*.md  "$PM_REPO/.gitlab/merge_request_templates/"
```

---

### Step 3: Copy PM skills

Copy all skills into `.claude/skills/` in your PM docs repo. Anyone who clones the repo gets the skills automatically — no extra install step.

> **Do not** add `.claude/` to the PM docs repo's `.gitignore`. Skills must be committed.

```bash
mkdir -p "$PM_REPO/.claude/skills"
cp -r "$PLUGIN/skills/." "$PM_REPO/.claude/skills/"
```

---

### Step 4: Create all GitLab labels

Run the label creation script from `gitlab/repo-structure.md`. Replace `<host>`, `<project_id>`, and `<token>`:

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
```

See `gitlab/repo-structure.md` for the complete script with all 38 label definitions.

---

### Step 5: Create team.yaml

Copy the template into your PM docs repo root and fill in each team member:

```bash
cp "$PLUGIN/team.yaml.example" "$PM_REPO/team.yaml"
```

Edit `team.yaml`:

```yaml
team:
  project: Your Project Name
  members:
    - display_name: Yo Tharit
      gitlab_username: yo.tharit
      role: PM          # PM | PO | Dev | QA | SM | DevOps
      email: yo.tharit@bitkub.com
```

Add an entry for every team member. Commit this file — it is shared and not secret.

---

### Step 6: Add .env to .gitignore

In your PM docs repo root, add `.env` to `.gitignore` if it isn't already there:

```bash
echo ".env" >> "$PM_REPO/.gitignore"
```

---

### Step 7: Commit and push

```bash
cd "$PM_REPO"
git add team.yaml .gitignore .gitlab/ .claude/
git commit -m "Init PM agent setup"
git push
```

---

### Step 8: Complete GitLab UI steps

These steps require the GitLab web UI (not available via API on Free tier):

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

### Step 9: Each team member sets up credentials

Each person does this **once on their own machine** from the PM docs repo root:

1. Pull the latest repo:
   ```bash
   git pull
   ```

2. Copy the credentials template and fill in their own values:
   ```bash
   cp "$PLUGIN/.env.example" .env
   ```
   ```env
   GITLAB_USERNAME=their.gitlab.username
   GITLAB_BASE_URL=https://gitlab.bitkub.com/api/v4
   GITLAB_PROJECT_ID=123          # Settings → General → Project ID
   GITLAB_TOKEN=glpat-xxxx        # Profile → Access Tokens (scope: api)
   ```

3. If they are not yet in `team.yaml`, add an entry and commit:
   ```yaml
   - display_name: Their Name
     gitlab_username: their.username
     role: Dev
     email: their.email@bitkub.com
   ```
   ```bash
   git add team.yaml && git commit -m "Add <Name> to team roster" && git push
   ```

`.env` is gitignored — each person keeps their own copy with their own token. Never commit `.env`.

---

### Step 10: Verify and start your first feature

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

### Step 1: Create missing folders

From your PM docs repo root, create any folders that don't already exist:

```bash
mkdir -p rfc grooming kickoff prd breakdown cr daily-standup \
         .gitlab/issue_templates .gitlab/merge_request_templates
```

This is safe to run even if the folders already exist.

---

### Step 2: Copy missing templates

Copy templates you don't already have from this plugin repo. Replace `$PLUGIN` and `$PM_REPO`:

```bash
PLUGIN=/path/to/bitkub-pm-skills
PM_REPO=/path/to/kub-wallet-pm

# Copy only files that don't exist yet (-n = no-clobber)
cp -n "$PLUGIN/gitlab/templates/issue/"*.md       "$PM_REPO/.gitlab/issue_templates/"
cp -n "$PLUGIN/gitlab/templates/merge_request/"*.md  "$PM_REPO/.gitlab/merge_request_templates/"
```

---

### Step 3: Copy PM skills

Copy skills into `.claude/skills/`, skipping any that already exist:

```bash
mkdir -p "$PM_REPO/.claude/skills"
cp -rn "$PLUGIN/skills/." "$PM_REPO/.claude/skills/"
```

---

### Step 4: Create missing labels

Run the label creation script from `gitlab/repo-structure.md`. Labels that already exist will return an API error — this is safe to ignore. Replace `<host>`, `<project_id>`, and `<token>`.

See `gitlab/repo-structure.md` for the complete script.

---

### Step 5: Update team.yaml

If `team.yaml` doesn't exist yet, copy and fill in the template:

```bash
cp "$PLUGIN/team.yaml.example" "$PM_REPO/team.yaml"
```

If it already exists, add any missing team members manually. You can find current assignees from your GitLab project:

```bash
curl -s "https://<host>/api/v4/projects/<id>/issues?state=opened&per_page=100" \
  -H "PRIVATE-TOKEN: <your_token>" \
  | jq -r '.[].assignees[].username' | sort -u
```

---

### Step 6: Commit and push

```bash
cd "$PM_REPO"
git add team.yaml .gitignore .gitlab/ .claude/
git commit -m "Add PM agent setup to project"
git push
```

---

### Step 7: Each team member sets up credentials

Same as Path A Step 9 — each person does this once on their own machine:

1. Pull latest: `git pull`
2. Copy and edit the credentials template:
   ```bash
   cp "$PLUGIN/.env.example" .env
   ```
   Fill in `GITLAB_USERNAME`, `GITLAB_BASE_URL`, `GITLAB_PROJECT_ID`, and `GITLAB_TOKEN`.
3. If not in `team.yaml`, add an entry and commit.

---

### Step 8: Migrate existing board data (optional)

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

### Step 9: Validate and start daily standup

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

The new member does this once on their own machine from the PM docs repo root:

1. Pull the latest:
   ```bash
   git pull
   ```

2. Copy and edit the credentials template:
   ```bash
   cp /path/to/bitkub-pm-skills/.env.example .env
   ```
   Fill in `GITLAB_USERNAME`, `GITLAB_BASE_URL`, `GITLAB_PROJECT_ID`, and `GITLAB_TOKEN`.

3. If not already in `team.yaml`, add an entry:
   ```yaml
   - display_name: New Member
     gitlab_username: new.member
     role: Dev          # PM | PO | Dev | QA | SM | DevOps
     email: new.member@bitkub.com
   ```

4. Commit and push `team.yaml`:
   ```bash
   git add team.yaml && git commit -m "Add <Name> to team roster" && git push
   ```

> Always `git pull` before editing `team.yaml` when multiple people are onboarding at the same time, to avoid merge conflicts.

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
| "You're not in team.yaml" every session | `team.yaml` is not committed or is out of date | `git pull` to get the latest `team.yaml`. If you added a local entry, commit and push it. |
| `/pm-standup` returns no tasks | Your GitLab token lacks `api` scope, or tasks are already `Done`/`Declined` | Re-generate your token with `api` scope. Verify your open tasks in GitLab directly. |
| WI status looks wrong on the board | GitLab Free doesn't compute status automatically | Ask the agent: "Recompute WI statuses" — it will re-read all child Tasks and correct the labels. |
| Breakdown fails: "PRD not approved" | The PRD `status` field is still `draft` | Run `/pm-prd <feature>` and say "PRD approved" to lock it before running breakdown. |
| CR Path A: PRD didn't version-bump | The approved PRD was edited directly instead of via the agent | Always use `/pm-cr` or `/pm-prd` for post-approval changes. Direct edits skip versioning. |
| `/pm-standup` (or other `/pm-*`) not in `/help` | `.claude/skills/` missing or not committed in the PM docs repo | Copy skills manually: `cp -r /path/to/bitkub-pm-skills/skills/. .claude/skills/` then `git add .claude/ && git commit && git push`. |

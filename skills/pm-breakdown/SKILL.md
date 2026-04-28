---
name: pm-breakdown
description: Break down an approved PRD into Working Items (GitLab Issues) grouped by component — Client, Service, Smart Contract, Chain, QA
argument-hint: <feature-slug>
allowed-tools: [Read, Write, Edit, Glob]
version: 1.0.0
---

# PM — Breakdown Pipeline

Feature: $ARGUMENTS

---

## Hard Rules (apply every time)

1. **Never fabricate.** Every Working Item traces to a PRD section. Missing info → blank + flag.
2. **Confirm before writing.** Present YAML draft → wait for approval → write file → wait for approval → create GitLab issues.
3. **Approved PRD only.** Read `prd/<feature-slug>.md` (status: approved). Do NOT re-read RFC/grooming/kickoff at this stage.
4. **Language preservation.** Thai/English/mixed content verbatim.
5. **Pipeline gates.** PRD must be approved before breakdown starts. YAML must be approved before issues are created.
6. **WI status is a rollup.** New Working Items start as `Status: Todo`. Never set status directly — it derives from children.

---

## Config Resolution (run once per session)

1. Read `.env` at project root — parse as `KEY=value` text lines (not shell env). Extract `GITLAB_BASE_URL`, `GITLAB_PROJECT_ID`, `GITLAB_TOKEN`.
2. If `.env` is missing or any value is blank → ask once. Suggest copying `.env.example` to `.env`.
3. Never ask again within the same session.

## GitLab API — Config

Values are read from `.env` (see Config Resolution above).

---

## Stage 3 — Propose Breakdown

**Trigger:** "Break down the PRD", "Generate working items", or argument provided.

Steps:
1. Read `prd/<feature-slug>.md` — confirm it has `status: approved`. If not, stop and tell user to approve the PRD first.
2. Identify groups by component: `[Client]`, `[Service]`, `[Smart Contract]`, `[Chain]`, `[QA - API Test]`, `[QA - Automate Test]`. Include `[Defects]` group with empty working_items (defects are added live).
3. For each group, propose Working Items with: name, priority, type, platform, release, feature_area, source (PRD section), description.
4. Save draft to `breakdown/<feature-slug>_v0.1.yaml` using the format below.
5. Present to user for review.

### Breakdown YAML format

```yaml
breakdown:
  feature: <feature-slug>
  prd: prd/<feature-slug>.md
  prd_version: 1.0
  generated: <YYYY-MM-DD>
  version: 0.1
  status: draft
  groups:
    - name: "[Client] Crypto Wallet"
      working_items:
        - name: "Implement daily limit Progress Bar"
          priority: High
          type: Feature
          platform: Mobile App
          release: ""
          feature_area: "Transaction Limit"
          source: "PRD §6.1"
          description: |
            Wallet page Progress Bar showing remaining daily limit.

    - name: "[Service] Crypto Limit Service"
      working_items:
        - name: "Daily limit aggregation across AA + EOA shared quota"
          priority: High
          type: Feature
          platform: Backend
          source: "PRD §4 FR-3"

    - name: "[Defects]"
      working_items: []
```

During review, edit the YAML in place. On approval: version → `1.0`, status → `approved`.

---

## Stage 4 — Apply Breakdown (Create GitLab Issues)

**Trigger:** "Apply the breakdown", "Create GitLab issues", after YAML is approved.

Steps:
1. Set YAML: `version: 1.0`, `status: approved`. Archive as `breakdown/<feature-slug>_v1.0.yaml` (immutable).
2. For each Working Item, create a GitLab issue:

```
POST /projects/:id/issues
{
  "title":       "<working_item.name>",
  "description": "<working_item.description>\n\nSource: prd/<feature>.md v1.0 | Plan: breakdown/<feature>_v1.0.yaml",
  "labels":      "Kind: Working Item,Group: <group>,Priority: <priority>,Type: <type>,Platform: <platform>,Status: Todo",
  "milestone_id": <id>   // null if release blank
}
```

3. Store returned `iid` — this is the Working Item ID (replaces KUB-XXXX).
4. Display all created issues as markdown table inline for verification before creating.
5. Tasks (subitems) are NOT created here — Dev/QA create their own under Working Items.

### Milestone lookup / creation
```
GET /projects/:id/milestones?search=<release>&per_page=20
POST /projects/:id/milestones { "title": "<release>", "due_date": "YYYY-MM-DD" }
```

### YAML field → GitLab label mapping

| YAML field | GitLab field |
|---|---|
| `name` | Issue title |
| `priority` | `Priority:*` label |
| `type` | `Type:*` label |
| `platform` | `Platform:*` label |
| `release` | Milestone |
| `feature_area` | Noted in description |
| `source` + `description` | Issue description body |
| Owner / timelines / status | Left blank — set after Dev/QA pick up tasks |

---

## Working Item Status (after creation)

All new Working Items start with `Status: Todo`.
Status is **derived from child Task issues** per the rollup rules — never set directly.
The agent recomputes on every read and write.

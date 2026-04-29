#!/usr/bin/env bash
# setup.sh — PM Agent project setup
# Run this from your TARGET PROJECT ROOT (the PM docs repo).
# Works for both new and ongoing projects.
#
# Usage:
#   /path/to/bitkub-pm-skills/scripts/setup.sh

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$(pwd)"

# ── Colors ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
skip() { echo -e "${YELLOW}  -${NC} $*"; }
fail() { echo -e "${RED}  ✗${NC} $*"; }
info() { echo -e "${CYAN}$*${NC}"; }

echo ""
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  PM Agent — Project Setup"
info "  Target: $TARGET_DIR"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Detect new vs ongoing ─────────────────────────────────────────────────
ONGOING=false
if [[ -f "$TARGET_DIR/team.yaml" || -d "$TARGET_DIR/prd" ]]; then
  ONGOING=true
  echo "Existing project detected (team.yaml or prd/ found)."
  echo "Running in ONGOING mode — existing files will not be overwritten."
else
  echo "No existing project detected. Running in NEW PROJECT mode."
fi
echo ""

# ── Step 1: GitLab credentials ────────────────────────────────────────────
info "Step 1 — GitLab credentials"
echo ""

read -rp "  GitLab host URL (e.g. https://gitlab.bitkub.com): " GITLAB_HOST
GITLAB_HOST="${GITLAB_HOST%/}"
GITLAB_BASE_URL="${GITLAB_HOST}/api/v4"

read -rp "  Project ID (Settings → General → Project ID): " GITLAB_PROJECT_ID
read -rsp "  Personal Access Token (scope: api): " GITLAB_TOKEN
echo ""

# Verify API connection
echo ""
echo -n "  Verifying API connection... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_BASE_URL/projects/$GITLAB_PROJECT_ID")

if [[ "$HTTP_CODE" != "200" ]]; then
  fail "Could not connect (HTTP $HTTP_CODE). Check host, project ID, and token."
  exit 1
fi
ok "Connected"
echo ""

# Fetch project name from GitLab
PROJECT_NAME=$(curl -s \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_BASE_URL/projects/$GITLAB_PROJECT_ID" \
  | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)

# ── Step 2: First team member (new) or add member (ongoing) ───────────────
info "Step 2 — Your identity"
echo ""
read -rp "  Your display name (e.g. Yo Tharit): " MEMBER_NAME
read -rp "  Your GitLab username (e.g. yo.tharit): " MEMBER_USERNAME
echo "  Role options: PM | PO | Dev | QA | SM | DevOps"
read -rp "  Your role: " MEMBER_ROLE
read -rp "  Your email: " MEMBER_EMAIL
echo ""

# ── Step 3: Folder structure ──────────────────────────────────────────────
info "Step 3 — Folder structure"
echo ""
FOLDERS=(rfc grooming kickoff prd breakdown cr daily-standup .gitlab/issue_templates .gitlab/merge_request_templates)
for dir in "${FOLDERS[@]}"; do
  if [[ -d "$TARGET_DIR/$dir" ]]; then
    skip "Exists: $dir/"
  else
    mkdir -p "$TARGET_DIR/$dir"
    ok "Created: $dir/"
  fi
done
echo ""

# ── Step 4: Copy GitLab templates ─────────────────────────────────────────
info "Step 4 — GitLab issue & MR templates"
echo ""
ISSUE_TEMPLATES=("working-item.md" "task.md" "defect.md")
for tmpl in "${ISSUE_TEMPLATES[@]}"; do
  src="$PLUGIN_DIR/gitlab/templates/issue/$tmpl"
  dst="$TARGET_DIR/.gitlab/issue_templates/$tmpl"
  if [[ -f "$dst" ]]; then
    skip "Exists: .gitlab/issue_templates/$tmpl"
  elif [[ -f "$src" ]]; then
    cp "$src" "$dst"
    ok "Copied: .gitlab/issue_templates/$tmpl"
  else
    fail "Source not found: $src"
  fi
done

MR_SRC="$PLUGIN_DIR/gitlab/templates/merge_request/prd-review.md"
MR_DST="$TARGET_DIR/.gitlab/merge_request_templates/prd-review.md"
if [[ -f "$MR_DST" ]]; then
  skip "Exists: .gitlab/merge_request_templates/prd-review.md"
elif [[ -f "$MR_SRC" ]]; then
  cp "$MR_SRC" "$MR_DST"
  ok "Copied: .gitlab/merge_request_templates/prd-review.md"
fi
echo ""

# ── Step 5: GitLab labels ─────────────────────────────────────────────────
info "Step 5 — GitLab labels"
echo ""

create_label() {
  local name="$1" color="$2" description="$3"
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$GITLAB_BASE_URL/projects/$GITLAB_PROJECT_ID/labels" \
    -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$name\", \"color\": \"$color\", \"description\": \"$description\"}")
  case "$http_code" in
    201) ok "Created: $name" ;;
    409) skip "Exists:  $name" ;;
    *)   fail "Failed ($http_code): $name" ;;
  esac
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
create_label "Platform: Kub Wallet"     "#00b8d9" ""
create_label "Platform: iOS"            "#00b8d9" ""
create_label "Platform: Android"        "#00b8d9" ""
create_label "Platform: Web"            "#00b8d9" ""
create_label "Platform: Mobile App"     "#00b8d9" ""
create_label "Platform: Smart Contract" "#00b8d9" ""
create_label "Platform: Chain"          "#00b8d9" ""
create_label "Platform: Backend"        "#00b8d9" ""

# Group
create_label "Group: Client"             "#4c9aff" "Frontend / Mobile UI"
create_label "Group: Service"            "#4c9aff" "Backend / API"
create_label "Group: Smart Contract"     "#4c9aff" "On-chain logic"
create_label "Group: Chain"              "#4c9aff" "Blockchain infra"
create_label "Group: QA - API Test"      "#4c9aff" ""
create_label "Group: QA - Automate Test" "#4c9aff" ""
create_label "Group: Defects"            "#de350b" ""

# Dev Status (Defects only)
create_label "Dev Status: Todo"          "#dfe1e6" "Defect: dev hasn't picked up"
create_label "Dev Status: Working on it" "#0747a6" "Defect: dev fixing"
create_label "Dev Status: Ready for QA"  "#ff991f" "Defect: dev done, QA verifying"
create_label "Dev Status: Done"          "#00875a" "Defect: verified fixed"

# QA Status (Defects only)
create_label "QA Status: Pending Retest" "#dfe1e6" "Defect: awaiting QA retest"
create_label "QA Status: In Retest"      "#ff991f" "Defect: QA retesting"
create_label "QA Status: Pass"           "#00875a" "Defect: fix verified"
create_label "QA Status: Fail"           "#de350b" "Defect: fix failed, returned to dev"
echo ""

# ── Step 6: team.yaml ─────────────────────────────────────────────────────
info "Step 6 — team.yaml"
echo ""
TEAM_YAML="$TARGET_DIR/team.yaml"

if [[ -f "$TEAM_YAML" ]]; then
  # Check if member already exists
  if grep -q "gitlab_username: $MEMBER_USERNAME" "$TEAM_YAML"; then
    skip "team.yaml exists and $MEMBER_USERNAME already listed"
  else
    # Append new member
    cat >> "$TEAM_YAML" << YAML

    - display_name: $MEMBER_NAME
      gitlab_username: $MEMBER_USERNAME
      role: $MEMBER_ROLE
      email: $MEMBER_EMAIL
YAML
    ok "Appended $MEMBER_NAME to existing team.yaml"
  fi
else
  cat > "$TEAM_YAML" << YAML
# team.yaml — shared team roster
# Commit this file. Each member's .env is gitignored and personal.
# Role values: PM | PO | Dev | QA | SM | DevOps

team:
  project: ${PROJECT_NAME:-Your Project}
  members:
    - display_name: $MEMBER_NAME
      gitlab_username: $MEMBER_USERNAME
      role: $MEMBER_ROLE
      email: $MEMBER_EMAIL
YAML
  ok "Created team.yaml"
fi
echo ""

# ── Step 7: .gitignore ────────────────────────────────────────────────────
info "Step 7 — .gitignore"
echo ""
GITIGNORE="$TARGET_DIR/.gitignore"
if [[ -f "$GITIGNORE" ]] && grep -q "^\.env$" "$GITIGNORE"; then
  skip ".env already in .gitignore"
else
  echo ".env" >> "$GITIGNORE"
  ok "Added .env to .gitignore"
fi
echo ""

# ── Step 8: Claude Code skills ────────────────────────────────────────────
info "Step 8 — Claude Code skills"
echo ""
SKILLS_DST="$TARGET_DIR/.claude/skills"
mkdir -p "$SKILLS_DST"
for skill_src in "$PLUGIN_DIR/skills"/*/; do
  skill_name=$(basename "$skill_src")
  if [[ -d "$SKILLS_DST/$skill_name" ]]; then
    skip "Exists: .claude/skills/$skill_name/"
  else
    cp -r "$skill_src" "$SKILLS_DST/$skill_name"
    ok "Copied: .claude/skills/$skill_name/"
  fi
done
echo ""

# ── Step 9: Personal .env ─────────────────────────────────────────────────
info "Step 9 — Your personal .env"
echo ""
ENV_FILE="$TARGET_DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
  skip ".env already exists — not overwritten"
else
  cat > "$ENV_FILE" << ENV
GITLAB_USERNAME=$MEMBER_USERNAME
GITLAB_BASE_URL=$GITLAB_BASE_URL
GITLAB_PROJECT_ID=$GITLAB_PROJECT_ID
GITLAB_TOKEN=$GITLAB_TOKEN
ENV
  ok "Created .env"
fi
echo ""

# ── Done ──────────────────────────────────────────────────────────────────
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  Setup complete"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo ""
echo "  1. Review and commit:"
echo "     git add team.yaml .gitignore .gitlab/ .claude/"
echo "     git commit -m 'Init PM agent setup'"
echo "     git push"
echo ""
echo "  2. In GitLab — complete manually (API not available on Free tier):"
echo "     - Plan → Issue Boards → New board → add Status: * columns"
echo "     - Plan → Milestones → create release milestones"
echo "     - Settings → Repository → Protected branches → protect main"
echo ""
echo "  3. Share setup-member.sh with your team:"
echo "     Each member runs: $PLUGIN_DIR/scripts/setup-member.sh"
echo ""
echo "  4. Open Claude Code in this directory and run /pm-standup to verify."
echo ""

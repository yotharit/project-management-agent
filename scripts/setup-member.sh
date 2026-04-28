#!/usr/bin/env bash
# setup-member.sh — Personal credential setup for each team member.
# Run this from your TARGET PROJECT ROOT (the PM docs repo).
# Each person runs this once on their own machine.
#
# Usage:
#   /path/to/bitkub-pm-skills/scripts/setup-member.sh

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
info "  PM Agent — Member Setup"
info "  Target: $TARGET_DIR"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Verify this is a PM project directory ─────────────────────────────────
if [[ ! -f "$TARGET_DIR/team.yaml" ]]; then
  fail "team.yaml not found in $TARGET_DIR"
  echo ""
  echo "  Make sure you are running this from the PM docs repo root."
  echo "  If the project is brand new, run setup.sh first (PM/lead only)."
  exit 1
fi

# ── Step 1: Collect credentials ───────────────────────────────────────────
info "Step 1 — Your GitLab credentials"
echo ""

# Pre-fill from team.yaml if already there
EXISTING_ENV=""
if [[ -f "$TARGET_DIR/.env" ]]; then
  EXISTING_ENV="$TARGET_DIR/.env"
  echo "  Existing .env found. Values will be used as defaults."
  echo ""
fi

read_with_default() {
  local prompt="$1" default="$2" result
  if [[ -n "$default" ]]; then
    read -rp "  $prompt [$default]: " result
    echo "${result:-$default}"
  else
    read -rp "  $prompt: " result
    echo "$result"
  fi
}

# Extract defaults from existing .env if present
DEFAULT_USERNAME=""; DEFAULT_BASE_URL=""; DEFAULT_PROJECT_ID=""
if [[ -n "$EXISTING_ENV" ]]; then
  DEFAULT_USERNAME=$(grep "^GITLAB_USERNAME=" "$EXISTING_ENV" 2>/dev/null | cut -d= -f2 || true)
  DEFAULT_BASE_URL=$(grep "^GITLAB_BASE_URL=" "$EXISTING_ENV" 2>/dev/null | cut -d= -f2 || true)
  DEFAULT_PROJECT_ID=$(grep "^GITLAB_PROJECT_ID=" "$EXISTING_ENV" 2>/dev/null | cut -d= -f2 || true)
fi

GITLAB_USERNAME=$(read_with_default "Your GitLab username" "$DEFAULT_USERNAME")
GITLAB_BASE_URL=$(read_with_default "GitLab API URL (e.g. https://gitlab.bitkub.com/api/v4)" "$DEFAULT_BASE_URL")
GITLAB_BASE_URL="${GITLAB_BASE_URL%/}"
GITLAB_PROJECT_ID=$(read_with_default "Project ID (Settings → General → Project ID)" "$DEFAULT_PROJECT_ID")

read -rsp "  Personal Access Token (scope: api, input hidden): " GITLAB_TOKEN
echo ""
echo ""

# ── Step 2: Verify credentials ────────────────────────────────────────────
info "Step 2 — Verifying credentials"
echo ""

# Verify token is valid and username matches
echo -n "  Checking API connection... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_BASE_URL/projects/$GITLAB_PROJECT_ID")

if [[ "$HTTP_CODE" != "200" ]]; then
  fail "Could not connect (HTTP $HTTP_CODE). Check base URL, project ID, and token."
  exit 1
fi
ok "Connected to project"

# Verify the GitLab username matches the token owner
echo -n "  Verifying username... "
TOKEN_USERNAME=$(curl -s \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_BASE_URL/user" \
  | grep -o '"username":"[^"]*"' | head -1 | cut -d'"' -f4)

if [[ "$TOKEN_USERNAME" != "$GITLAB_USERNAME" ]]; then
  fail "Token belongs to '$TOKEN_USERNAME', but you entered '$GITLAB_USERNAME'."
  echo ""
  read -rp "  Use '$TOKEN_USERNAME' instead? (y/n): " USE_TOKEN_USERNAME
  if [[ "$USE_TOKEN_USERNAME" =~ ^[Yy]$ ]]; then
    GITLAB_USERNAME="$TOKEN_USERNAME"
    ok "Using $GITLAB_USERNAME"
  else
    echo "  Fix the mismatch and re-run setup-member.sh."
    exit 1
  fi
else
  ok "Username matches token ($GITLAB_USERNAME)"
fi
echo ""

# ── Step 3: Check team.yaml membership ───────────────────────────────────
info "Step 3 — Checking team roster"
echo ""
if grep -q "gitlab_username: $GITLAB_USERNAME" "$TARGET_DIR/team.yaml"; then
  DISPLAY_NAME=$(grep -A1 "gitlab_username: $GITLAB_USERNAME" "$TARGET_DIR/team.yaml" \
    | grep "display_name:" | head -1 | sed 's/.*display_name: //' | xargs)
  ok "Found in team.yaml as: $DISPLAY_NAME"
else
  echo "  You are not in team.yaml yet."
  echo ""
  read -rp "  Your display name (e.g. Yo Tharit): " DISPLAY_NAME
  echo "  Role options: PM | PO | Dev | QA | SM | DevOps"
  read -rp "  Your role: " MEMBER_ROLE
  read -rp "  Your email: " MEMBER_EMAIL
  echo ""

  cat >> "$TARGET_DIR/team.yaml" << YAML

    - display_name: $DISPLAY_NAME
      gitlab_username: $GITLAB_USERNAME
      role: $MEMBER_ROLE
      email: $MEMBER_EMAIL
YAML
  ok "Added $DISPLAY_NAME to team.yaml"
  echo ""
  echo -e "  ${YELLOW}Remember to commit and push team.yaml:${NC}"
  echo "  git add team.yaml && git commit -m 'Add $DISPLAY_NAME to team roster' && git push"
fi
echo ""

# ── Step 4: Write .env ────────────────────────────────────────────────────
info "Step 4 — Personal .env"
echo ""
ENV_FILE="$TARGET_DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
  read -rp "  .env already exists. Overwrite? (y/n): " OVERWRITE
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    skip ".env not overwritten"
    echo ""
    info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    info "  Setup complete — .env unchanged"
    info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Open Claude Code in $TARGET_DIR and run /pm-standup to verify."
    echo ""
    exit 0
  fi
fi

cat > "$ENV_FILE" << ENV
GITLAB_USERNAME=$GITLAB_USERNAME
GITLAB_BASE_URL=$GITLAB_BASE_URL
GITLAB_PROJECT_ID=$GITLAB_PROJECT_ID
GITLAB_TOKEN=$GITLAB_TOKEN
ENV
ok "Created .env"

# Confirm .env is gitignored
if ! grep -q "^\.env$" "$TARGET_DIR/.gitignore" 2>/dev/null; then
  echo ".env" >> "$TARGET_DIR/.gitignore"
  ok "Added .env to .gitignore"
fi
echo ""

# ── Done ──────────────────────────────────────────────────────────────────
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
info "  Setup complete — $DISPLAY_NAME"
info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Open Claude Code in $TARGET_DIR and run:"
echo ""
echo "    /pm-standup"
echo ""
echo "  The agent will greet you as '$DISPLAY_NAME' and show your open tasks."
echo ""

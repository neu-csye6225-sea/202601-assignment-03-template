#!/bin/bash

# Log file setup
LOG_FILE="grading-report.txt"
echo "Assignment Grading Report" > "$LOG_FILE"
echo "Generated on: $(date)" >> "$LOG_FILE"

log() { echo "$1" | tee -a "$LOG_FILE"; }

SCORE=0

log "--- Starting Production Compliance Checks ---"

# 1. Hygiene
# Check if .gitignore exists, contains .env, AND that .env is NOT in the repo
if [ -f .gitignore ] && grep -q ".env" .gitignore; then
    if [ -f .env ]; then
        log "❌ [FAIL] SECURITY RISK: .env file found in repository!"
        log "   - Remove the file using 'git rm --cached .env' and commit."
    else
        log "✅ [PASS] .gitignore configured and secrets excluded (+15)"
        SCORE=$((SCORE + 15))
    fi
else
    log "❌ [FAIL] .gitignore missing or does not ignore .env"
fi

# 2. Branching
if git branch -r | grep -q "feature/"; then
    log "✅ [PASS] Feature branch detected (+10)"
    SCORE=$((SCORE + 10))
else
    log "❌ [FAIL] No feature branch found"
fi

# 3. Traceability
# Matches "close/fix/resolve" variations, optional colon, optional space, then #<number>
if git log --all --oneline | grep -iqE "(close[ds]?|fix(es|ed)?|resolve[ds]?):?\s*#[0-9]+"; then
    log "✅ [PASS] Issue linking detected (+15)"
    SCORE=$((SCORE + 15))
else
    log "❌ [FAIL] No commit linked to an issue (Expected format: 'closes #1', 'fixes #2', 'resolved: #3', etc.)"
fi

# 4. File Operations
# Check: obsolete.txt deleted, CONTRIBUTING.md created, ENV.md has 'PROD' (case-insensitive)
if [ ! -f "obsolete.txt" ] && [ -f "CONTRIBUTING.md" ] && grep -iq "PROD" ENV.md; then
    log "✅ [PASS] File operations (delete/create/modify) verified (+10)"
    SCORE=$((SCORE + 10))
else
    log "❌ [FAIL] File operations incomplete:"
    [ -f "obsolete.txt" ] && log "   - obsolete.txt still exists"
    [ ! -f "CONTRIBUTING.md" ] && log "   - CONTRIBUTING.md missing"
    ! grep -iq "PROD" ENV.md && log "   - ENV.md does not contain 'PROD'"
fi

# 5. Conflict Resolution
if [ "$(git rev-list --merges --count HEAD)" -gt 0 ]; then
    log "✅ [PASS] Merge conflict resolution detected (+25)"
    SCORE=$((SCORE + 25))
else
    log "❌ [FAIL] No merge commits found"
fi

# 6. Release Tag
if git tag | grep -q "v1.0.0"; then
    log "✅ [PASS] Tag v1.0.0 found (+10)"
    SCORE=$((SCORE + 10))
else
    log "❌ [FAIL] Tag v1.0.0 missing"
fi

# 7. Secrets Check
# Checks if DEPLOY_ENV is 'production' AND API_KEY is 'sk_live_123456'
if [ "$DEPLOY_ENV" == "production" ] && [ "$API_KEY" == "sk_live_123456" ]; then
    log "✅ [PASS] Secrets and Variables correctly configured (+15)"
    SCORE=$((SCORE + 15))
else
    log "❌ [FAIL] Secrets/Vars incorrect or missing."
    if [ "$DEPLOY_ENV" != "production" ]; then
        log "   - DEPLOY_ENV is invalid or missing (Expected: 'production')"
    fi
    if [ "$API_KEY" != "sk_live_123456" ]; then
        log "   - API_KEY is invalid or missing (Check value)"
    fi
fi

log "---------------------------------"
log "FINAL SCORE: $SCORE / 100"
log "---------------------------------"

# Always exit 0 to allow artifact upload. Grading happens in next step.
exit 0

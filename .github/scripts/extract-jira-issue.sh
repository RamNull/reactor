#!/bin/bash
# Script to extract Jira issue ID from PR title or description
# Supports common formats like: [PROJ-123], PROJ-123:, PROJ-123 -

set -e

# Get PR title and body from environment variables
PR_TITLE="${PR_TITLE:-}"
PR_BODY="${PR_BODY:-}"

echo "Extracting Jira issue ID from PR..."
echo "PR Title: $PR_TITLE"

# Function to extract issue ID using various patterns
extract_issue_id() {
    local text="$1"
    
    # Pattern 1: [PROJ-123] at the beginning
    if [[ "$text" =~ ^\[([A-Z]+-[0-9]+)\] ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    
    # Pattern 2: PROJ-123: at the beginning
    if [[ "$text" =~ ^([A-Z]+-[0-9]+): ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    
    # Pattern 3: PROJ-123 - at the beginning
    if [[ "$text" =~ ^([A-Z]+-[0-9]+)[[:space:]]- ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    
    # Pattern 4: PROJ-123 anywhere in the text
    if [[ "$text" =~ ([A-Z]+-[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    
    return 1
}

# Try to extract from title first
ISSUE_ID=""
if [ -n "$PR_TITLE" ]; then
    ISSUE_ID=$(extract_issue_id "$PR_TITLE" || echo "")
fi

# If not found in title, try description
if [ -z "$ISSUE_ID" ] && [ -n "$PR_BODY" ]; then
    echo "Issue ID not found in title, checking description..."
    ISSUE_ID=$(extract_issue_id "$PR_BODY" || echo "")
fi

# Output the result
if [ -n "$ISSUE_ID" ]; then
    echo "✅ Found Jira issue ID: $ISSUE_ID"
    echo "issue_id=$ISSUE_ID" >> "$GITHUB_OUTPUT"
    exit 0
else
    echo "ℹ️  No Jira issue ID found in PR title or description"
    echo "   Supported formats:"
    echo "   - [PROJ-123] Fix the bug"
    echo "   - PROJ-123: Fix the bug"
    echo "   - PROJ-123 - Fix the bug"
    echo "   - Fix the bug (mentions PROJ-123)"
    echo "issue_id=" >> "$GITHUB_OUTPUT"
    exit 0
fi

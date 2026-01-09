#!/bin/bash
# Script to update Jira issue status via REST API

set -e

# Check required environment variables
if [ -z "$JIRA_URL" ]; then
    echo "⚠️  JIRA_URL environment variable is not set. Skipping Jira update."
    echo "   Please configure JIRA_URL in GitHub repository secrets."
    exit 0
fi

if [ -z "$JIRA_USER" ]; then
    echo "⚠️  JIRA_USER environment variable is not set. Skipping Jira update."
    echo "   Please configure JIRA_USER in GitHub repository secrets."
    exit 0
fi

if [ -z "$JIRA_API_TOKEN" ]; then
    echo "⚠️  JIRA_API_TOKEN environment variable is not set. Skipping Jira update."
    echo "   Please configure JIRA_API_TOKEN in GitHub repository secrets."
    exit 0
fi

if [ -z "$JIRA_ISSUE_ID" ]; then
    echo "ℹ️  No Jira issue ID provided. Skipping Jira update."
    exit 0
fi

# Set default transition name if not provided
TRANSITION_NAME="${JIRA_TRANSITION_NAME:-In Review}"

echo "Updating Jira issue: $JIRA_ISSUE_ID"
echo "Target status: $TRANSITION_NAME"

# Remove trailing slash from JIRA_URL if present
JIRA_URL="${JIRA_URL%/}"

# Get available transitions for the issue
echo "Fetching available transitions..."
TRANSITIONS_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -u "${JIRA_USER}:${JIRA_API_TOKEN}" \
    -H "Content-Type: application/json" \
    -X GET \
    "${JIRA_URL}/rest/api/2/issue/${JIRA_ISSUE_ID}/transitions")

HTTP_CODE=$(echo "$TRANSITIONS_RESPONSE" | tail -n1)
TRANSITIONS_BODY=$(echo "$TRANSITIONS_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ne 200 ]; then
    echo "❌ Failed to fetch transitions for issue $JIRA_ISSUE_ID"
    echo "HTTP Status: $HTTP_CODE"
    echo "Response: $TRANSITIONS_BODY"
    exit 1
fi

echo "Available transitions retrieved successfully"

# Find the transition ID for the target status
# This searches for transition name (case-insensitive)
TRANSITION_ID=$(echo "$TRANSITIONS_BODY" | grep -i "\"name\":\"$TRANSITION_NAME\"" | head -1 | sed -E 's/.*"id":"?([0-9]+)"?.*/\1/')

if [ -z "$TRANSITION_ID" ]; then
    echo "⚠️  Transition '$TRANSITION_NAME' not found for issue $JIRA_ISSUE_ID"
    echo "Available transitions:"
    echo "$TRANSITIONS_BODY" | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"$//' || echo "Could not parse transitions"
    echo ""
    echo "Please check that:"
    echo "1. The transition name is correct"
    echo "2. The issue is in a status that allows this transition"
    echo "3. Your Jira user has permission to perform this transition"
    exit 0
fi

echo "Found transition ID: $TRANSITION_ID"

# Prepare comment text
COMMENT_TEXT="Code review initiated via GitHub PR"
COMPLETION_TYPE="${COMPLETION_TYPE:-}"

if [ -n "$PR_NUMBER" ] && [ -n "$PR_URL" ]; then
    case "$COMPLETION_TYPE" in
        "merged")
            COMMENT_TEXT="PR #${PR_NUMBER} has been merged. Issue marked as complete. View PR: ${PR_URL}"
            ;;
        "closed")
            COMMENT_TEXT="PR #${PR_NUMBER} has been closed without merge. View PR: ${PR_URL}"
            ;;
        *)
            COMMENT_TEXT="Code review for PR #${PR_NUMBER} has been initiated. View PR: ${PR_URL}"
            ;;
    esac
fi

# Perform the transition
echo "Performing transition..."
TRANSITION_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -u "${JIRA_USER}:${JIRA_API_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "{\"transition\":{\"id\":\"${TRANSITION_ID}\"}}" \
    "${JIRA_URL}/rest/api/2/issue/${JIRA_ISSUE_ID}/transitions")

HTTP_CODE=$(echo "$TRANSITION_RESPONSE" | tail -n1)
TRANSITION_BODY=$(echo "$TRANSITION_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 204 ] || [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ Successfully updated Jira issue $JIRA_ISSUE_ID to '$TRANSITION_NAME'"
    
    # Add a comment to the Jira issue
    echo "Adding comment to Jira issue..."
    COMMENT_RESPONSE=$(curl -s -w "\n%{http_code}" \
        -u "${JIRA_USER}:${JIRA_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "{\"body\":\"${COMMENT_TEXT}\"}" \
        "${JIRA_URL}/rest/api/2/issue/${JIRA_ISSUE_ID}/comment")
    
    COMMENT_HTTP_CODE=$(echo "$COMMENT_RESPONSE" | tail -n1)
    if [ "$COMMENT_HTTP_CODE" -eq 201 ]; then
        echo "✅ Comment added to Jira issue"
    else
        echo "⚠️  Could not add comment to Jira issue (non-critical)"
    fi
else
    echo "❌ Failed to update Jira issue $JIRA_ISSUE_ID"
    echo "HTTP Status: $HTTP_CODE"
    echo "Response: $TRANSITION_BODY"
    exit 1
fi

echo "Jira update completed successfully"

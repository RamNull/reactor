#!/bin/bash
# Script: resolve-review.sh
# Purpose: Resolve review comments when appropriate
# This script checks if a review comment should be resolved based on committer responses

set -e

echo "✅ Checking if review comments should be resolved..."

PR_NUMBER="${PR_NUMBER:-$1}"
COMMENT_ID="${COMMENT_ID:-$2}"

if [ -z "$PR_NUMBER" ]; then
    echo "Error: PR_NUMBER not provided"
    exit 1
fi

echo "Checking PR #$PR_NUMBER"

# Get all comments on the PR
COMMENTS=$(gh pr view "$PR_NUMBER" --json comments --jq '.comments[] | {id: .id, author: .author.login, body: .body, createdAt: .createdAt}')

echo "Analyzing comment thread..."

# Count bot comments vs user comments
BOT_COMMENTS=$(echo "$COMMENTS" | jq -s '[.[] | select(.author == "github-actions" or .author | contains("bot"))] | length')
USER_COMMENTS=$(echo "$COMMENTS" | jq -s '[.[] | select(.author != "github-actions" and (.author | contains("bot") | not))] | length')

echo "Bot comments: $BOT_COMMENTS"
echo "User comments: $USER_COMMENTS"

# Check if user has responded substantively
if [ "$USER_COMMENTS" -gt 0 ]; then
    echo "User has responded to review"
    
    # Get the latest user comment
    LATEST_USER_COMMENT=$(echo "$COMMENTS" | jq -s '[.[] | select(.author != "github-actions" and (.author | contains("bot") | not))] | sort_by(.createdAt) | last | .body')
    
    # Check if the response indicates the issue is addressed
    if echo "$LATEST_USER_COMMENT" | grep -qiE "(fixed|done|updated|addressed|implemented|resolved|changed)"; then
        echo "✅ User indicates issue is addressed"
        
        # Post a resolution comment
        gh pr comment "$PR_NUMBER" --body "## ✅ Review Issue Resolved

Thank you for addressing this feedback! The issue appears to be resolved based on your response.

This review thread is now considered resolved."
        
        echo "Review marked as resolved"
    else
        echo "Response doesn't indicate resolution yet"
    fi
else
    echo "No user response yet"
fi

echo "🎉 Resolution check complete!"

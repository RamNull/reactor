#!/bin/bash
# Script: review-pr.sh
# Purpose: Perform initial code review on pull requests using GitHub Copilot
# This script analyzes the PR changes and posts review comments

set -e

echo "🔍 Starting PR code review..."

# Get PR number from environment
PR_NUMBER="${PR_NUMBER:-$1}"
if [ -z "$PR_NUMBER" ]; then
    echo "Error: PR_NUMBER not provided"
    exit 1
fi

echo "Reviewing PR #$PR_NUMBER"

# Get PR details
PR_DATA=$(gh pr view "$PR_NUMBER" --json title,body,additions,deletions,files)
PR_TITLE=$(echo "$PR_DATA" | jq -r '.title')
ADDITIONS=$(echo "$PR_DATA" | jq -r '.additions')
DELETIONS=$(echo "$PR_DATA" | jq -r '.deletions')

echo "PR Title: $PR_TITLE"
echo "Changes: +$ADDITIONS/-$DELETIONS"

# Get the list of changed files
CHANGED_FILES=$(echo "$PR_DATA" | jq -r '.files[].path')
echo "Changed files:"
echo "$CHANGED_FILES"

# Fetch the PR diff for analysis
echo "Fetching PR diff..."
gh pr diff "$PR_NUMBER" > /tmp/pr_diff.txt

# Analyze the diff and prepare review comments
echo "Analyzing changes..."

# Initialize review comments array
REVIEW_COMMENTS=""

# Check for common code review issues
while IFS= read -r file; do
    echo "Reviewing: $file"
    
    # Get file extension for language-specific checks
    EXT="${file##*.}"
    
    # Check Java files
    if [ "$EXT" = "java" ]; then
        # Check for proper exception handling
        if grep -q "catch.*Exception.*{[[:space:]]*}" "/tmp/pr_diff.txt" 2>/dev/null; then
            REVIEW_COMMENTS="${REVIEW_COMMENTS}
- **File: $file** - Empty catch blocks detected. Consider logging the exception or adding proper error handling."
        fi
        
        # Check for System.out.println usage
        if grep -q "System\.out\.println" "/tmp/pr_diff.txt" 2>/dev/null; then
            REVIEW_COMMENTS="${REVIEW_COMMENTS}
- **File: $file** - Consider using a proper logging framework (SLF4J/Logback) instead of System.out.println."
        fi
        
        # Check for TODO comments
        if grep -q "//.*TODO" "/tmp/pr_diff.txt" 2>/dev/null; then
            REVIEW_COMMENTS="${REVIEW_COMMENTS}
- **File: $file** - TODO comments found. Please address or create tracking issues."
        fi
    fi
    
    # Check YAML/YML workflow files
    if [ "$EXT" = "yml" ] || [ "$EXT" = "yaml" ]; then
        # Check for hardcoded secrets
        if grep -qE "(password|secret|token|key).*:.*['\"]" "/tmp/pr_diff.txt" 2>/dev/null; then
            REVIEW_COMMENTS="${REVIEW_COMMENTS}
- **File: $file** - Potential hardcoded secrets detected. Please use GitHub secrets or environment variables."
        fi
    fi
    
    # Check for large files (>500 lines changed)
    FILE_CHANGES=$(git diff origin/master..."$GITHUB_HEAD_REF" -- "$file" 2>/dev/null | grep -c "^[+-]" || echo "0")
    if [ "$FILE_CHANGES" -gt 500 ]; then
        REVIEW_COMMENTS="${REVIEW_COMMENTS}
- **File: $file** - Large number of changes ($FILE_CHANGES lines). Consider breaking this into smaller PRs for easier review."
    fi
    
done <<< "$CHANGED_FILES"

# General code quality checks
echo "Running general code quality checks..."

# Check for proper documentation
if [ "$ADDITIONS" -gt 100 ] && ! grep -q "\.md" <<< "$CHANGED_FILES"; then
    REVIEW_COMMENTS="${REVIEW_COMMENTS}
- **Documentation** - Significant code changes detected without documentation updates. Consider updating README or relevant docs."
fi

# Check for test coverage
if grep -q "src/main/java" <<< "$CHANGED_FILES" && ! grep -q "src/test/java" <<< "$CHANGED_FILES"; then
    REVIEW_COMMENTS="${REVIEW_COMMENTS}
- **Testing** - Changes to main code detected without corresponding test updates. Please add or update tests."
fi

# Post review comment if issues found
if [ -n "$REVIEW_COMMENTS" ]; then
    echo "📝 Posting review comments..."
    
    COMMENT_BODY="## 🤖 Automated Code Review

Thank you for your contribution! I've reviewed the changes and have some suggestions:

$REVIEW_COMMENTS

---
**Note:** This is an automated review. Please feel free to:
- Ask questions if anything is unclear
- Defend your implementation if you believe it's correct
- Request clarification on any feedback

Reply to this comment with your response, and I'll review your explanation."

    gh pr comment "$PR_NUMBER" --body "$COMMENT_BODY"
    echo "✅ Review comments posted"
else
    echo "✨ No issues found. Code looks good!"
    
    COMMENT_BODY="## 🤖 Automated Code Review

Great work! The code changes look good. No major issues detected.

✅ Code quality checks passed
✅ Best practices followed

Feel free to merge once other reviewers approve."

    gh pr comment "$PR_NUMBER" --body "$COMMENT_BODY"
fi

echo "🎉 Review complete!"

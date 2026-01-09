# GitHub Actions Scripts for Code Review and Jira Integration

This directory contains scripts used by the automated code review and Jira integration workflow.

## Scripts Overview

### 1. extract-jira-issue.sh

**Purpose**: Extract Jira issue ID from PR title or description.

**Supported Formats**:
- `[PROJ-123]` - Brackets at the start
- `PROJ-123:` - Colon at the start  
- `PROJ-123 -` - Dash at the start
- `PROJ-123` - Anywhere in the text

**Environment Variables**:
- `PR_TITLE` - The pull request title
- `PR_BODY` - The pull request description/body

**Outputs**:
- `issue_id` - The extracted Jira issue ID (or empty if not found)

**Exit Codes**:
- `0` - Success (whether or not an issue ID was found)

### 2. update-jira-status.sh

**Purpose**: Update Jira issue status via REST API.

**Required Environment Variables**:
- `JIRA_URL` - Jira instance URL (e.g., https://company.atlassian.net)
- `JIRA_USER` - Jira user email
- `JIRA_API_TOKEN` - Jira API token
- `JIRA_ISSUE_ID` - The issue ID to update
- `JIRA_TRANSITION_NAME` - Target status name (e.g., "In Review")

**Optional Environment Variables**:
- `PR_NUMBER` - Pull request number (for comment)
- `PR_URL` - Pull request URL (for comment)

**Behavior**:
- Fetches available transitions for the issue
- Finds the transition ID matching the target status name
- Performs the transition
- Adds a comment to the Jira issue with PR link
- Gracefully handles missing configuration or invalid transitions

**Exit Codes**:
- `0` - Success or graceful skip (missing config/issue ID)
- `1` - Error (API failure, invalid credentials, etc.)

## Usage

These scripts are called by the GitHub Actions workflow defined in `.github/workflows/code-review-jira.yml`.

### Manual Testing

You can test the scripts locally:

```bash
# Test issue ID extraction
export PR_TITLE="[PROJ-123] Fix bug"
export PR_BODY="This fixes the login issue"
.github/scripts/extract-jira-issue.sh

# Test Jira update (requires valid credentials)
export JIRA_URL="https://yourcompany.atlassian.net"
export JIRA_USER="user@company.com"
export JIRA_API_TOKEN="your-token"
export JIRA_ISSUE_ID="PROJ-123"
export JIRA_TRANSITION_NAME="In Review"
.github/scripts/update-jira-status.sh
```

## Customization

### Adding New Issue ID Patterns

Edit `extract-jira-issue.sh` and add your pattern in the `extract_issue_id` function:

```bash
# Pattern N: Your custom format
if [[ "$text" =~ YourRegexPattern ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
fi
```

### Changing Jira API Version

The `update-jira-status.sh` script uses Jira REST API v2. To use v3:

1. Change API URLs from `/rest/api/2/` to `/rest/api/3/`
2. Update JSON payloads according to v3 API spec

### Adding Additional Jira Actions

You can extend `update-jira-status.sh` to:
- Assign the issue to a user
- Add labels
- Update custom fields
- Link issues
- Add attachments

## Error Handling

Both scripts implement comprehensive error handling:

1. **Missing Configuration**: Scripts exit gracefully with informative messages
2. **API Failures**: HTTP status codes are checked and errors are logged
3. **Invalid Data**: Invalid issue IDs or transitions are caught and reported
4. **Network Issues**: Curl failures are detected and handled

## Security

- **No Secrets in Logs**: Scripts never echo sensitive data
- **Secure API Calls**: Uses basic auth over HTTPS
- **Token Protection**: API tokens are passed via environment variables only
- **Input Validation**: Issue IDs and status names are validated

## Dependencies

- **bash** (4.0+)
- **curl** (for API calls)
- **grep**, **sed** (for text processing)

These are available by default in GitHub Actions runners.

## Debugging

Enable verbose output by adding to workflow:

```yaml
- name: Debug Issue Extraction
  run: |
    set -x  # Enable bash debugging
    .github/scripts/extract-jira-issue.sh
```

Check GitHub Actions logs for detailed output from each script execution.

## Contributing

When modifying scripts:

1. **Test locally** before committing
2. **Maintain backward compatibility** with existing patterns
3. **Update documentation** for any new features
4. **Add comments** for complex logic
5. **Follow existing code style**

## Support

For issues with these scripts:
1. Check GitHub Actions workflow logs
2. Review error messages carefully
3. Verify environment variables are set correctly
4. Test issue ID patterns manually
5. Verify Jira API credentials and permissions

---

**Maintainer**: Development Team  
**Last Updated**: 2026-01-09

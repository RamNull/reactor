# Example GitHub Secrets Configuration for Jira Integration

This file provides examples of how to configure GitHub secrets and variables for the Jira integration workflow.

## Required Secrets

Navigate to: **Repository Settings → Secrets and variables → Actions → Secrets**

### JIRA_URL
Your Jira instance URL (without trailing slash)

**Examples**:
- Jira Cloud: `https://yourcompany.atlassian.net`
- Jira Server: `https://jira.yourcompany.com`
- Jira Data Center: `https://jira.internal.company.com`

### JIRA_USER
Your Jira user email address (for Jira Cloud) or username (for Jira Server)

**Examples**:
- Jira Cloud: `developer@company.com`
- Jira Server: `jsmith` or `john.smith@company.com`

### JIRA_API_TOKEN
Your Jira API token

**How to generate**:
1. **Jira Cloud**: 
   - Go to https://id.atlassian.com/manage-profile/security/api-tokens
   - Click "Create API token"
   - Copy the generated token

2. **Jira Server/Data Center**:
   - May use API token or password depending on configuration
   - Check with your Jira administrator

**Format**: `ATATxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` (for Cloud)

## Optional Variables

Navigate to: **Repository Settings → Secrets and variables → Actions → Variables**

### JIRA_REVIEW_STATUS
The Jira status name to transition to when a PR is opened for review.

**Default**: `In Review`

**Other common values**:
- `Code Review`
- `Peer Review`
- `Under Review`
- `Reviewing`

**Important**: Must match exactly the status name in your Jira workflow (case-sensitive).

### JIRA_REVIEWED_STATUS
The Jira status name to transition to when a PR is approved.

**Default**: `Reviewed`

**Other common values**:
- `Review Complete`
- `Approved`
- `Review Done`
- `Ready for QA`
- `Ready to Merge`

**Important**: Must match exactly the status name in your Jira workflow (case-sensitive).

### JIRA_DONE_STATUS
The Jira status name to transition to when a PR is merged (completed).

**Default**: `Done`

**Other common values**:
- `Completed`
- `Resolved`
- `Finished`
- `Deployed`
- `Closed`

**Important**: Must match exactly the status name in your Jira workflow (case-sensitive).

### JIRA_CLOSED_STATUS
The Jira status name to transition to when a PR is closed without merge.

**Default**: `Closed`

**Other common values**:
- `Cancelled`
- `Rejected`
- `Won't Do`
- `Abandoned`
- `Declined`

**Important**: Must match exactly the status name in your Jira workflow (case-sensitive).

## Verification Checklist

Before using the workflow, verify:

- [ ] All three secrets are configured (JIRA_URL, JIRA_USER, JIRA_API_TOKEN)
- [ ] JIRA_URL does not have a trailing slash
- [ ] JIRA_USER is correct (email for Cloud, username for Server)
- [ ] JIRA_API_TOKEN is valid and not expired
- [ ] Status names match your Jira workflow exactly (all four: In Review, Reviewed, Done, Closed)
- [ ] Your Jira user has permission to transition issues to all required statuses
- [ ] Your Jira user has permission to add comments

## Testing Configuration

### Test 1: Manual API Call

Test your credentials with curl:

```bash
# For Jira Cloud
curl -u "your-email@company.com:YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  https://yourcompany.atlassian.net/rest/api/2/myself

# Should return your user information
```

### Test 2: Check Available Transitions

Check what transitions are available for a test issue:

```bash
# Replace TEST-123 with your actual issue
curl -u "your-email@company.com:YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  https://yourcompany.atlassian.net/rest/api/2/issue/TEST-123/transitions

# Should return list of available transitions
```

### Test 3: Test Issue ID Extraction

Run the extraction script locally:

```bash
export PR_TITLE="[PROJ-123] Your PR title"
export PR_BODY="Description with PROJ-456 mentioned"
export GITHUB_OUTPUT="/tmp/output.txt"
.github/scripts/extract-jira-issue.sh
cat /tmp/output.txt
# Should show: issue_id=PROJ-123
```

## Common Jira Workflow Configurations

### Standard Agile Workflow
```
To Do → In Progress → In Review → Reviewed → Done
        ^                ^           ^         ^
        |                |           |         |
    PR Created      PR Opened   PR Approved  PR Merged
```

**Variables**:
- `JIRA_REVIEW_STATUS=In Review`
- `JIRA_REVIEWED_STATUS=Reviewed`
- `JIRA_DONE_STATUS=Done`
- `JIRA_CLOSED_STATUS=Closed`

### Kanban Workflow
```
Backlog → In Development → Code Review → Done
                              ^          ^
                              |          |
                         PR Opened   PR Merged
```

**Variables**:
- `JIRA_REVIEW_STATUS=Code Review`
- `JIRA_REVIEWED_STATUS=Code Review`
- `JIRA_DONE_STATUS=Done`
- `JIRA_CLOSED_STATUS=Backlog`

### Custom Workflow
```
New → Development → Peer Review → Testing → Deployed
                        ^            ^         ^
                        |            |         |
                   PR Opened    PR Approved  PR Merged
```

**Variables**:
- `JIRA_REVIEW_STATUS=Peer Review`
- `JIRA_REVIEWED_STATUS=Testing`
- `JIRA_DONE_STATUS=Deployed`
- `JIRA_CLOSED_STATUS=Cancelled`

## Security Best Practices

1. **Never commit credentials**: Secrets should only be in GitHub Secrets
2. **Use API tokens**: Not passwords or personal access tokens when possible
3. **Limit permissions**: API token should have minimal required permissions
4. **Rotate regularly**: Change API tokens every 90 days
5. **Use service accounts**: Consider using a dedicated Jira service account
6. **Audit access**: Regularly review who has access to secrets

## Troubleshooting

### Error: "401 Unauthorized"
- Check JIRA_USER is correct
- Verify JIRA_API_TOKEN is valid
- Ensure token hasn't expired

### Error: "404 Not Found"
- Verify JIRA_URL is correct
- Check issue ID exists in Jira
- Ensure you have access to the project

### Error: "Transition not found"
- Status name doesn't match exactly
- Check your Jira workflow configuration
- Verify issue can transition to that status

### Warning: "No issue ID found"
- PR title/description doesn't match supported formats
- Use: `[PROJ-123]`, `PROJ-123:`, or `PROJ-123 -`
- Ensure project key is UPPERCASE

## Support Resources

- **Jira Cloud REST API**: https://developer.atlassian.com/cloud/jira/platform/rest/v2/
- **GitHub Actions Secrets**: https://docs.github.com/en/actions/security-guides/encrypted-secrets
- **Jira API Tokens**: https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/

---

**Last Updated**: 2026-01-09

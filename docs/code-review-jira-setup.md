# Code Review with Jira Integration - Setup Guide

This guide explains how to set up the automated code review workflow with Jira integration for the reactor repository.

## Overview

This workflow automatically:
1. **Requests code review** when a PR is opened
2. **Extracts Jira issue ID** from PR title or description
3. **Updates Jira status** to "In Review" when PR is created
4. **Updates Jira status** to "Reviewed" when PR is approved
5. **Updates Jira status** to "Done" when PR is merged
6. **Updates Jira status** to "Closed" when PR is closed without merge
7. **Skips Jira updates** if no issue ID is found

## Features

- ✅ Automatic code review request on PR creation
- ✅ Intelligent Jira issue ID extraction
- ✅ Complete workflow lifecycle (PR → Jira at every stage)
- ✅ Handles PR merge and closure events
- ✅ Graceful handling of missing Jira configuration
- ✅ Support for multiple issue ID formats
- ✅ Detailed logging and error messages

## Prerequisites

1. **GitHub Repository** with Actions enabled
2. **Jira Instance** (Cloud or Server)
3. **Jira API Token** with appropriate permissions
4. **Admin access** to GitHub repository settings

## Configuration

### Step 1: Create Jira API Token

1. Log in to your Jira account
2. Go to **Account Settings** → **Security** → **API Tokens**
3. Click **Create API Token**
4. Give it a name (e.g., "GitHub Actions Integration")
5. Copy the generated token (you won't be able to see it again)

### Step 2: Configure GitHub Secrets

Add the following secrets in your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `JIRA_URL` | Your Jira instance URL (without trailing slash) | `https://yourcompany.atlassian.net` |
| `JIRA_USER` | Your Jira user email | `user@company.com` |
| `JIRA_API_TOKEN` | The API token created in Step 1 | `ATATxxxxxxxxxxxxx` |

### Step 3: Configure GitHub Variables (Optional)

You can customize the Jira status names using repository variables:

**Settings → Secrets and variables → Actions → Variables tab**

| Variable Name | Description | Default Value |
|---------------|-------------|---------------|
| `JIRA_REVIEW_STATUS` | Status to set when PR is opened | `In Review` |
| `JIRA_REVIEWED_STATUS` | Status to set when PR is approved | `Reviewed` |
| `JIRA_DONE_STATUS` | Status to set when PR is merged | `Done` |
| `JIRA_CLOSED_STATUS` | Status to set when PR is closed without merge | `Closed` |

### Step 4: Verify Jira Workflow

Ensure your Jira project has the following transitions available:

1. A transition to **"In Review"** status (or your custom status name)
2. A transition to **"Reviewed"** status (or your custom status name)
3. A transition to **"Done"** status (or your custom status name)
4. A transition to **"Closed"** status (or your custom status name)

2. A transition to **"Reviewed"** status (or your custom status name)

The script will automatically find the correct transition ID based on the status name.

## Usage

### Creating a PR with Jira Integration

To link a PR to a Jira issue, include the issue ID in the PR title or description using one of these formats:

#### Supported Formats

1. **Brackets at start**: `[PROJ-123] Fix login bug`
2. **Colon at start**: `PROJ-123: Fix login bug`
3. **Dash at start**: `PROJ-123 - Fix login bug`
4. **Anywhere in text**: `Fix login bug (addresses PROJ-123)`

#### Examples

**Good PR Titles:**
```
[REACT-456] Add user authentication
BACKEND-789: Implement caching layer
API-123 - Fix response timeout
```

**Good PR Descriptions:**
```
This PR fixes the authentication issue mentioned in PROJ-456.

Related to issue PROJ-456
```

### Without Jira Integration

If your PR doesn't have a Jira issue ID, the workflow will:
- ✅ Still request code review
- ✅ Skip Jira updates gracefully
- ℹ️  Log that no issue ID was found

## Workflow Behavior

### When a PR is Opened

1. **Workflow triggers** on `pull_request` opened event
2. **Extracts issue ID** from title/description
3. **Posts comment** indicating code review request
4. **Updates Jira** (if issue ID found) to "In Review"
5. **Adds comment** to Jira with PR link

### When a PR is Approved

1. **Workflow triggers** on `pull_request_review` submitted event
2. **Extracts issue ID** from title/description
3. **Updates Jira** (if issue ID found) to "Reviewed"
4. **Posts comment** on PR confirming Jira update

### When a PR is Merged

1. **Workflow triggers** on `pull_request` closed event (with merged=true)
2. **Extracts issue ID** from title/description
3. **Updates Jira** (if issue ID found) to "Done"
4. **Adds comment** to Jira indicating PR was merged
5. **Posts comment** on PR confirming completion

### When a PR is Closed Without Merge

1. **Workflow triggers** on `pull_request` closed event (with merged=false)
2. **Extracts issue ID** from title/description
3. **Updates Jira** (if issue ID found) to "Closed"
4. **Adds comment** to Jira indicating PR was closed
5. **Posts comment** on PR confirming closure

## Troubleshooting

### Issue: "Transition not found"

**Cause**: The status name doesn't match any available transition in Jira.

**Solution**:
1. Check your Jira workflow transitions
2. Update the `JIRA_REVIEW_STATUS` or `JIRA_REVIEWED_STATUS` variable to match exact status name
3. Ensure your Jira user has permission to perform the transition

### Issue: "Authentication failed"

**Cause**: Invalid Jira credentials.

**Solution**:
1. Verify `JIRA_USER` is the email address used for Jira login
2. Regenerate `JIRA_API_TOKEN` if it's expired
3. Check that `JIRA_URL` is correct and accessible

### Issue: "No issue ID found"

**Cause**: PR title/description doesn't match any supported format.

**Solution**:
1. Use one of the supported formats: `[PROJ-123]`, `PROJ-123:`, or `PROJ-123 -`
2. Ensure the project key is in UPPERCASE
3. Check the issue number format (should be PROJECT-NUMBER)

### Issue: "Workflow doesn't run"

**Cause**: Workflow file not in the correct location or permissions issue.

**Solution**:
1. Ensure workflow file is at `.github/workflows/code-review-jira.yml`
2. Check that Actions are enabled in repository settings
3. Verify the workflow has correct permissions in the YAML file

## Testing the Integration

### Test Without Jira (Dry Run)

1. Create a PR without a Jira issue ID in the title
2. Workflow should run and post a comment
3. No Jira updates should occur (check logs for "No Jira issue ID found")

### Test With Jira (Full Integration)

1. Create a test Jira issue (e.g., `TEST-1`)
2. Create a PR with title: `[TEST-1] Test integration`
3. Workflow should:
   - Post a comment on PR
   - Update Jira issue to "In Review"
   - Add a comment to Jira with PR link
4. Approve the PR
5. Workflow should:
   - Update Jira issue to "Reviewed"
   - Post a confirmation comment on PR

## Security Best Practices

1. **Never commit secrets** to the repository
2. **Use API tokens** instead of passwords
3. **Limit token scope** to minimum required permissions
4. **Rotate tokens** periodically
5. **Use secrets** for sensitive data, variables for non-sensitive configuration

## Customization

### Changing Status Names

Edit the repository variables:
```
JIRA_REVIEW_STATUS=Your Custom Status
JIRA_REVIEWED_STATUS=Another Custom Status
```

### Adding More Jira Updates

You can extend the workflow to trigger on additional events:
- When PR is merged → Update to "Done"
- When PR is closed without merge → Update to "Closed"
- On specific label additions → Update to custom status

### Customizing Issue ID Pattern

Edit `.github/scripts/extract-jira-issue.sh` to add your own regex patterns:

```bash
# Pattern 5: Custom format
if [[ "$text" =~ YourPattern ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
fi
```

## Files Structure

```
.github/
├── workflows/
│   └── code-review-jira.yml          # Main workflow file
└── scripts/
    ├── extract-jira-issue.sh          # Issue ID extraction logic
    └── update-jira-status.sh          # Jira API interaction
docs/
└── code-review-jira-setup.md         # This file
```

## Support

For issues or questions:
1. Check the **Actions** tab in GitHub for workflow logs
2. Review the **Troubleshooting** section above
3. Open an issue in the repository
4. Check Jira permissions and workflow configuration

## Version History

- **v1.0.0** (2026-01-09): Initial release
  - Automatic code review request
  - Jira integration with status updates
  - Support for multiple issue ID formats
  - Comprehensive error handling

---

**Last Updated**: 2026-01-09
**Status**: Production Ready ✅

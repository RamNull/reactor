# Testing Guide for Code Review and Jira Integration

This guide explains how to test the code review and Jira integration workflow.

## Automated Tests

### Test 1: Issue ID Extraction

All extraction patterns have been validated:

| Test Case | Expected Result | Status |
|-----------|----------------|--------|
| `[REACT-123] Fix login bug` | REACT-123 | ✅ PASS |
| `BACKEND-456: Implement caching` | BACKEND-456 | ✅ PASS |
| `API-789 - Update documentation` | API-789 | ✅ PASS |
| `Fix bug (mentioned in PROJ-999)` | PROJ-999 | ✅ PASS |
| `Update README` | (empty) | ✅ PASS |
| `[abc-123] lowercase project key` | (empty) | ✅ PASS |
| `MIXED-123 and TEST-456` | MIXED-123 | ✅ PASS |

### Test 2: Script Executability

Scripts are executable and have correct permissions:

```
✅ .github/scripts/extract-jira-issue.sh (755)
✅ .github/scripts/update-jira-status.sh (755)
```

### Test 3: YAML Validation

Workflow file syntax validated:

```
✅ .github/workflows/code-review-jira.yml (valid YAML)
```

## Manual Testing Procedures

### Prerequisites

Before testing, ensure you have:
- [ ] Access to a Jira instance
- [ ] Valid Jira API credentials
- [ ] A test Jira project with at least one issue
- [ ] Admin access to the GitHub repository

### Test Scenario 1: PR with Jira Issue (Full Integration)

**Objective**: Test complete workflow from PR creation to Jira update.

**Steps**:

1. **Configure Secrets**:
   ```
   Settings → Secrets and variables → Actions → New repository secret
   - JIRA_URL: https://yourcompany.atlassian.net
   - JIRA_USER: your-email@company.com
   - JIRA_API_TOKEN: your-api-token
   ```

2. **Create Test Issue in Jira**:
   - Create a new issue (e.g., `TEST-100`)
   - Ensure it's in a status that can transition to "In Review"

3. **Create Test Branch**:
   ```bash
   git checkout -b test-jira-integration
   echo "test" > test.txt
   git add test.txt
   git commit -m "Test commit"
   git push origin test-jira-integration
   ```

4. **Create Pull Request**:
   - Title: `[TEST-100] Test Jira integration`
   - Description: Any text
   - Base: master/main

5. **Expected Results**:
   - ✅ Workflow runs automatically
   - ✅ Comment posted on PR about code review request
   - ✅ Jira issue TEST-100 transitions to "In Review"
   - ✅ Comment added to Jira with PR link
   - ✅ No errors in Actions logs

6. **Approve the PR**:
   - Get approval from a reviewer

7. **Expected Results**:
   - ✅ Workflow runs on review submission
   - ✅ Jira issue TEST-100 transitions to "Reviewed"
   - ✅ Comment posted on PR confirming Jira update

### Test Scenario 2: PR without Jira Issue

**Objective**: Verify graceful handling of PRs without Jira issues.

**Steps**:

1. **Create Test Branch**:
   ```bash
   git checkout -b test-no-jira
   echo "test2" > test2.txt
   git add test2.txt
   git commit -m "Test without Jira"
   git push origin test-no-jira
   ```

2. **Create Pull Request**:
   - Title: `Update documentation`
   - Description: No Jira issue mentioned

3. **Expected Results**:
   - ✅ Workflow runs automatically
   - ✅ Comment posted on PR about code review request
   - ✅ Jira update steps are skipped
   - ✅ Log shows "No Jira issue ID found"
   - ✅ No errors in Actions logs

### Test Scenario 3: Invalid Jira Credentials

**Objective**: Test error handling for invalid credentials.

**Steps**:

1. **Temporarily Update Secrets**:
   - Change JIRA_API_TOKEN to an invalid value

2. **Create PR with Jira Issue**:
   - Title: `[TEST-101] Test invalid credentials`

3. **Expected Results**:
   - ✅ Workflow runs
   - ✅ Authentication error logged
   - ⚠️ Jira update fails gracefully
   - ✅ PR still created successfully
   - ✅ No workflow crash

4. **Restore Valid Credentials**

### Test Scenario 4: Invalid Transition Name

**Objective**: Test handling of non-existent Jira status.

**Steps**:

1. **Configure Variable**:
   ```
   Settings → Secrets and variables → Actions → Variables
   - JIRA_REVIEW_STATUS: NonExistentStatus
   ```

2. **Create PR with Jira Issue**:
   - Title: `[TEST-102] Test invalid status`

3. **Expected Results**:
   - ✅ Workflow runs
   - ⚠️ Warning logged about transition not found
   - ✅ List of available transitions shown in logs
   - ✅ Workflow completes without crashing

4. **Restore Correct Variable Value**

### Test Scenario 5: Multiple Issue ID Formats

**Objective**: Verify all supported formats work correctly.

**Test Cases**:

| Format | PR Title | Expected Issue |
|--------|----------|---------------|
| Brackets | `[API-200] Fix endpoint` | API-200 |
| Colon | `API-201: Add validation` | API-201 |
| Dash | `API-202 - Update docs` | API-202 |
| In Body | Title: `Fix bug`, Body: `Fixes API-203` | API-203 |

**Steps**: Create a PR for each format and verify issue ID is extracted correctly.

## Debugging Failed Tests

### Check Workflow Logs

1. Go to **Actions** tab in GitHub
2. Click on the failed workflow run
3. Expand each step to see detailed logs
4. Look for error messages or warnings

### Common Issues and Solutions

#### Issue: "Script not found"
```
Solution: Ensure scripts are committed and in correct location
Location: .github/scripts/
```

#### Issue: "Permission denied"
```
Solution: Verify scripts are executable
Command: chmod +x .github/scripts/*.sh
```

#### Issue: "GITHUB_OUTPUT not found"
```
Solution: This error only occurs in local testing
Workaround: export GITHUB_OUTPUT="/tmp/output.txt"
```

#### Issue: "401 Unauthorized" (Jira)
```
Solution: Check Jira credentials in GitHub secrets
- Verify JIRA_USER is correct
- Regenerate JIRA_API_TOKEN
- Test credentials manually with curl
```

#### Issue: "Transition not found"
```
Solution: Status name doesn't match Jira workflow
- Check exact status name in Jira
- Update JIRA_REVIEW_STATUS variable
- Ensure issue can transition to that status
```

## Local Testing

### Test Issue Extraction Locally

```bash
cd /home/runner/work/reactor/reactor

# Test with bracket format
export PR_TITLE="[PROJ-123] Fix bug"
export PR_BODY=""
export GITHUB_OUTPUT="/tmp/output.txt"
.github/scripts/extract-jira-issue.sh
cat /tmp/output.txt
# Expected: issue_id=PROJ-123

# Test with no issue
export PR_TITLE="Update README"
export GITHUB_OUTPUT="/tmp/output2.txt"
.github/scripts/extract-jira-issue.sh
cat /tmp/output2.txt
# Expected: issue_id=
```

### Test Jira Update Locally (with valid credentials)

```bash
export JIRA_URL="https://yourcompany.atlassian.net"
export JIRA_USER="your-email@company.com"
export JIRA_API_TOKEN="your-token"
export JIRA_ISSUE_ID="TEST-100"
export JIRA_TRANSITION_NAME="In Review"
export PR_NUMBER="1"
export PR_URL="https://github.com/user/repo/pull/1"

.github/scripts/update-jira-status.sh
# Should update Jira issue if credentials are valid
```

## Continuous Testing

### Recommended Testing Schedule

1. **After Initial Setup**: Run all test scenarios
2. **After Configuration Changes**: Test affected scenarios
3. **Quarterly**: Full regression testing
4. **Before Major Changes**: Backup test of current functionality

### Test Coverage Checklist

- [ ] PR with valid Jira issue ID (bracket format)
- [ ] PR with valid Jira issue ID (colon format)
- [ ] PR with valid Jira issue ID (dash format)
- [ ] PR with issue ID in description only
- [ ] PR without Jira issue ID
- [ ] PR approval updates Jira correctly
- [ ] Multiple PR updates (synchronize event)
- [ ] Invalid Jira credentials handling
- [ ] Invalid transition name handling
- [ ] Network error handling
- [ ] Script permission verification
- [ ] YAML syntax validation

## Performance Testing

### Expected Performance

- **Issue extraction**: < 1 second
- **Jira API call**: 2-5 seconds (depends on network)
- **Total workflow time**: 30-60 seconds

### Performance Issues

If workflow takes longer than 2 minutes:
1. Check Jira API response time
2. Verify network connectivity
3. Review workflow logs for delays
4. Consider Jira instance performance

## Test Results

### Script Tests
✅ All 7 extraction test cases passed
✅ Scripts have correct permissions
✅ YAML syntax validated

### Integration Tests
⚠️ Requires manual testing with actual Jira instance
📋 Follow test scenarios above

## Next Steps

1. ✅ Complete automated script testing
2. ⏳ Manual integration testing (requires Jira setup)
3. ⏳ User acceptance testing
4. ⏳ Production deployment

---

**Last Updated**: 2026-01-09
**Test Status**: Script tests passed, integration tests pending

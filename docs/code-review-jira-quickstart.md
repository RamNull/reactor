# Quick Reference: PR with Jira Integration

## How to Create a PR with Jira Link

### Format Your PR Title

Use one of these formats to automatically link to Jira:

```
[PROJ-123] Your PR title here
PROJ-123: Your PR title here
PROJ-123 - Your PR title here
```

### What Happens Automatically

1. ✅ **PR opened** → Code review requested, Jira → "In Review"
2. ✅ **PR approved** → Jira → "Reviewed"
3. ✅ **PR merged** → Jira → "Done"
4. ✅ **PR closed** (without merge) → Jira → "Closed"

### No Jira Issue?

No problem! Just create your PR normally:
- Code review will still be requested
- Jira steps will be skipped automatically

## Examples

### Good PR Titles
```
✅ [BACKEND-456] Add user authentication
✅ API-789: Fix timeout issue
✅ FRONTEND-123 - Update login UI
```

### Also Works
```
✅ Fix authentication (BACKEND-456)
✅ Related to JIRA-123: Fix bug
```

### Won't Work
```
❌ backend-456 (lowercase)
❌ PROJ 123 (no hyphen)
❌ Fix the bug (no issue ID)
```

## Need Help?

See the [full setup guide](code-review-jira-setup.md) for:
- Configuration details
- Troubleshooting
- Customization options

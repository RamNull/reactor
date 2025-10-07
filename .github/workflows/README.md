# PR Review Agent

This repository includes an automated PR review agent that runs on every pull request.

## Features

The automated PR review agent provides the following features:

### 1. **Automatic Review Comments**
When a pull request is opened or updated, the agent automatically posts a review comment with:
- Number of files changed
- Lines added and deleted
- Total change count
- PR size assessment
- A review checklist

### 2. **Size-based Labeling**
The agent automatically labels PRs based on their size:

| Label | Total Changes | Assessment |
|-------|--------------|------------|
| `size/XS` | < 50 lines | Very small PR - Great for quick reviews! |
| `size/S` | 50-199 lines | Small PR - Easy to review |
| `size/M` | 200-499 lines | Medium PR - Consider breaking up if possible |
| `size/L` | 500-999 lines | Large PR - Should be broken into smaller PRs |
| `size/XL` | ≥ 1000 lines | Very large PR - Difficult to review, please split |

### 3. **Review Checklist**
Each PR receives an automated checklist to ensure quality:
- Code follows the project's coding standards
- Tests have been added/updated
- Documentation has been updated (if needed)
- All CI checks pass
- PR has been reviewed by at least one team member

## How It Works

The workflow is triggered on the following events:
- When a PR is opened (`opened`)
- When new commits are pushed to an existing PR (`synchronize`)
- When a closed PR is reopened (`reopened`)

### Workflow Steps

1. **Checkout Code**: Fetches the repository code with full history
2. **Get PR Details**: Retrieves information about the PR including files changed and line counts
3. **Check PR Size**: Calculates the total changes and assigns an appropriate size label
4. **Post Review Comment**: Creates a detailed comment on the PR with statistics and checklist
5. **Add Size Label**: Applies the size label to the PR (creates the label if it doesn't exist)

## Permissions

The workflow requires the following permissions:
- `contents: read` - To checkout the repository
- `pull-requests: write` - To comment on PRs
- `issues: write` - To add labels (PRs are treated as issues for labeling)

## Customization

You can customize the workflow by editing `.github/workflows/pr-review.yml`:

### Adjust Size Thresholds
Modify the size calculations in the "Check PR size" step:
```yaml
if (totalChanges < 50) {
  sizeLabel = 'size/XS';
} else if (totalChanges < 200) {
  sizeLabel = 'size/S';
}
# ... etc
```

### Change Label Colors
Update the color mapping in the "Add size label" step:
```yaml
const colors = {
  'size/XS': '00ff00',  // Green
  'size/S': '90EE90',   // Light green
  'size/M': 'FFD700',   // Gold
  'size/L': 'FFA500',   // Orange
  'size/XL': 'FF0000'   // Red
};
```

### Modify Review Checklist
Edit the `reviewComment` template in the "Post review comment" step to add or remove checklist items.

## Example Output

When a PR is opened, the agent will post a comment like this:

```markdown
## 🤖 Automated PR Review

### PR Statistics
- **Files changed:** 5
- **Lines added:** +127
- **Lines deleted:** -43
- **Total changes:** 170

### Size Assessment
✅ This is a small PR. Should be easy to review.

### Checklist
Please ensure the following before merging:
- [ ] Code follows the project's coding standards
- [ ] Tests have been added/updated
- [ ] Documentation has been updated (if needed)
- [ ] All CI checks pass
- [ ] PR has been reviewed by at least one team member

---
*This is an automated review. Please reach out to maintainers if you have questions.*
```

## Disabling the Workflow

If you need to temporarily disable the workflow, you can:

1. Comment out or remove the workflow file
2. Or add a condition to skip certain PRs:
   ```yaml
   jobs:
     review:
       if: "!contains(github.event.pull_request.labels.*.name, 'skip-review')"
   ```

## Troubleshooting

### Labels Not Being Created
If the size labels aren't being created automatically:
1. Check that the workflow has `issues: write` permission
2. Manually create the labels in the repository settings
3. Verify the GitHub Actions token has sufficient permissions

### Comments Not Appearing
If review comments aren't being posted:
1. Ensure `pull-requests: write` permission is granted
2. Check the workflow run logs in the Actions tab
3. Verify the PR is from the same repository (not a fork with restricted permissions)

## Contributing

To improve this workflow:
1. Fork the repository
2. Make your changes to `.github/workflows/pr-review.yml`
3. Test the workflow in your fork
4. Submit a PR with your improvements

## License

This workflow is part of the reactor project. See the repository license for details.
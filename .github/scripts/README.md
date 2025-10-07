# Copilot Code Review Workflow

This directory contains the automated code review workflow and supporting scripts that enable GitHub Copilot to review pull requests and interact with developers.

## Overview

The Copilot Code Review system provides automated code quality checks and interactive review capabilities. It follows the principle of **separation of concerns** by dividing responsibilities into distinct, focused scripts.

## Architecture

### Workflow File
- **`copilot-code-review.yml`** - Main GitHub Actions workflow that orchestrates the review process

### Review Scripts (Separation of Concerns)

#### 1. `review-pr.sh` - Initial Code Review
**Purpose:** Performs the initial automated code review when a PR is opened or updated.

**Responsibilities:**
- Fetches PR details and changes
- Analyzes code for common issues:
  - Empty catch blocks in Java
  - Use of System.out.println instead of logging frameworks
  - TODO comments without tracking
  - Hardcoded secrets in YAML files
  - Large file changes (>500 lines)
- Checks for documentation updates
- Verifies test coverage
- Posts review comments with findings

**Triggered by:** PR opened, synchronized, or reopened

#### 2. `handle-review-response.sh` - Response Handler
**Purpose:** Processes committer responses to review comments and provides contextual replies.

**Responsibilities:**
- Reads and analyzes committer responses
- Classifies responses into types:
  - **Questions** - Provides detailed explanations
  - **Defense/Explanation** - Evaluates the reasoning
  - **Agreement** - Acknowledges and encourages
- Generates appropriate responses based on context
- Validates defenses with specific technical criteria

**Triggered by:** Comments on PR (not from bots)

#### 3. `resolve-review.sh` - Review Resolution
**Purpose:** Determines when review comments should be resolved based on committer actions.

**Responsibilities:**
- Analyzes comment threads
- Checks if issues are addressed
- Marks reviews as resolved when appropriate
- Posts resolution confirmation

**Triggered by:** After handling a review response

## Workflow Triggers

### Pull Request Events
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
```
- **opened**: Initial review when PR is created
- **synchronize**: Re-review when new commits are pushed
- **reopened**: Review when PR is reopened

### Comment Events
```yaml
on:
  issue_comment:
    types: [created]
```
- Triggers when a developer responds to review comments
- Excludes bot comments to prevent loops

## How It Works

### 1. Initial Review Flow
```
PR Opened/Updated
    ↓
review-pr.sh runs
    ↓
Analyzes changes
    ↓
Posts review comments
```

### 2. Interactive Review Flow
```
Developer responds to review
    ↓
handle-review-response.sh runs
    ↓
Classifies response type
    ↓
Generates contextual reply
    ↓
resolve-review.sh runs
    ↓
Checks if issue is resolved
    ↓
Marks as resolved if appropriate
```

## Review Capabilities

### Code Quality Checks

#### Java Files
- Empty exception handlers
- Console output (System.out.println)
- TODO comments

#### YAML Files
- Hardcoded secrets
- Security vulnerabilities

#### General Checks
- File size (prevents massive changes)
- Documentation updates
- Test coverage

### Response Handling

#### Questions from Developers
The bot provides detailed explanations about:
- Why logging frameworks are preferred
- Importance of tests
- Documentation benefits
- Best practices

#### Defenses from Developers
The bot evaluates defenses based on:
- **Performance considerations** - Benchmarks, profiling data
- **Backward compatibility** - Legacy system constraints
- **Framework limitations** - External dependency requirements

Valid defenses result in automatic resolution with recommendations.

#### Agreements from Developers
The bot acknowledges fixes and encourages the developer.

## Example Interactions

### Example 1: Initial Review
```
🤖 Automated Code Review

Thank you for your contribution! I've reviewed the changes and have some suggestions:

- File: UserService.java - Consider using a proper logging framework 
  (SLF4J/Logback) instead of System.out.println.
- Testing - Changes to main code detected without corresponding test 
  updates. Please add or update tests.
```

### Example 2: Developer Asks Question
**Developer:** "Why should I use a logging framework instead of System.out?"

**Bot Response:**
```
🤖 Response to Your Question

Regarding logging frameworks:
Using a proper logging framework like SLF4J with Logback provides:
- Configurable log levels (DEBUG, INFO, WARN, ERROR)
- Better performance with lazy evaluation
- Support for structured logging
- Production-ready features like log rotation
...
```

### Example 3: Developer Defends Implementation
**Developer:** "Actually, I used System.out here because our framework requires it for startup logging before the logger initializes."

**Bot Response:**
```
🤖 Review of Your Explanation

✅ Framework constraint noted. External dependencies can limit 
implementation choices.

Your explanation makes sense. I'll mark this review comment as resolved.

Recommendation: Consider adding a code comment explaining this 
decision for future maintainers.

✅ Review comment resolved - valid justification provided.
```

## Configuration

### Required Permissions
```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write
```

### Environment Variables
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions
- `PR_NUMBER` - Pull request number
- `GITHUB_REPOSITORY` - Repository name
- `COMMENT_ID` - Comment identifier (for responses)

## Customization

### Adding New Review Rules

Edit `review-pr.sh` to add new checks:

```bash
# Example: Check for specific pattern
if grep -q "PATTERN" "/tmp/pr_diff.txt" 2>/dev/null; then
    REVIEW_COMMENTS="${REVIEW_COMMENTS}
- **File: $file** - Your custom message here."
fi
```

### Adding New Response Templates

Edit `handle-review-response.sh` to add new response types:

```bash
if echo "$COMMENT_BODY" | grep -qiE "(your|pattern)"; then
    REPLY="${REPLY}Your custom response here"
fi
```

## Benefits

1. **Separation of Concerns**: Each script has a single, well-defined purpose
2. **Maintainability**: Easy to update individual components
3. **Reusability**: Scripts can be used independently or combined
4. **Testability**: Each script can be tested in isolation
5. **Extensibility**: Easy to add new review rules or response types

## Troubleshooting

### Review Not Triggering
- Check if workflow file is in `.github/workflows/`
- Verify permissions in workflow file
- Check GitHub Actions logs

### Bot Not Responding to Comments
- Ensure comment is on a PR (not a regular issue)
- Verify the comment isn't from a bot
- Check if the comment contains the bot marker (🤖)

### Scripts Not Executable
Run: `chmod +x .github/scripts/*.sh`

## Future Enhancements

Potential improvements:
- Integration with static analysis tools (SonarQube, Checkstyle)
- AI-powered code suggestions using GPT models
- Custom review rules per file type
- Review comment templates
- Sentiment analysis of developer responses
- Automated conflict resolution suggestions

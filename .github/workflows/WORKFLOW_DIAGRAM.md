# PR Review Workflow - Complete Flow Diagram

## Workflow Trigger Events

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Events                             │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
         ┌──────▼──────┐ ┌───▼────┐  ┌────▼──────────┐
         │ pull_request│ │ review │  │ issue_comment │
         │  - opened   │ │submitted│  │   - created   │
         │  - sync     │ └────┬───┘  └────┬──────────┘
         │  - reopened │      │           │
         └──────┬──────┘      │           │
                │             │           │
                ▼             ▼           ▼
         ┌──────────────┐ ┌──────────────────────┐
         │  Job: review │ │ Job: respond-to-     │
         │              │ │      review          │
         └──────────────┘ └──────────────────────┘
```

## Job 1: Automated PR Review

**Triggers:** pull_request [opened, synchronize, reopened]

```
┌─────────────────────────────────────────────────────────────┐
│                   Automated PR Review                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                   ┌──────────────────┐
                   │ Checkout Code    │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ Get PR Details   │
                   │  - File count    │
                   │  - Additions     │
                   │  - Deletions     │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ Check PR Size    │
                   │  < 50    → XS    │
                   │  50-199  → S     │
                   │  200-499 → M     │
                   │  500-999 → L     │
                   │  1000+   → XL    │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ Post Review      │
                   │ Comment with:    │
                   │  - Statistics    │
                   │  - Size label    │
                   │  - Checklist     │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ Add Size Label   │
                   │ to PR            │
                   └──────────────────┘
```

## Job 2: Respond to Review Comments

**Triggers:** pull_request_review, pull_request_review_comment, issue_comment

```
┌─────────────────────────────────────────────────────────────┐
│               Respond to Review Comments                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                   ┌──────────────────┐
                   │ Extract Comment  │
                   │ Content & Type   │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ Is from Bot?     │
                   └────────┬─────────┘
                            │
                   ┌────────┴────────┐
                   │                 │
                 YES               NO
                   │                 │
                   ▼                 ▼
              ┌────────┐    ┌──────────────┐
              │  SKIP  │    │ Check for    │
              │        │    │ Question     │
              └────────┘    │ Keywords     │
                            └──────┬───────┘
                                   │
                          ┌────────┴────────┐
                          │                 │
                        FOUND            NOT FOUND
                          │                 │
                          ▼                 ▼
                 ┌────────────────┐   ┌────────┐
                 │ Analyze Topic  │   │  SKIP  │
                 │  - Testing     │   └────────┘
                 │  - Docs        │
                 │  - Performance │
                 │  - Security    │
                 │  - Breaking    │
                 └────────┬───────┘
                          │
                          ▼
                 ┌────────────────┐
                 │ Generate       │
                 │ Contextual     │
                 │ Response       │
                 └────────┬───────┘
                          │
                          ▼
                 ┌────────────────┐
                 │ Post Response  │
                 │ as PR Comment  │
                 └────────────────┘
```

## Response Keywords Detection

The bot looks for these keywords to determine if a response is needed:

| Keyword Category | Examples |
|------------------|----------|
| Question Marks | `?` |
| Question Words | `why`, `how`, `what` |
| Requests | `could you`, `can you`, `please explain` |
| Clarification | `clarify`, `unclear`, `confused` |
| Help | `help`, `question`, `wondering` |

## Topic-Specific Responses

The bot analyzes comments for specific topics and provides relevant guidance:

| Topic Keywords | Response Includes |
|----------------|-------------------|
| `test`, `testing` | Test coverage guidelines, CI checks |
| `document`, `doc` | Documentation update reminders |
| `breaking`, `backward` | Compatibility considerations, versioning |
| `performance`, `perf` | Profiling, benchmarking suggestions |
| `security`, `secure` | Security review checklist |

## Benefits of This Workflow

### ✅ For PR Authors
- **Immediate Feedback**: Get automated review as soon as PR is opened
- **Clear Guidance**: Understand what reviewers are looking for
- **Size Awareness**: Know if your PR is too large

### ✅ For Reviewers
- **Helpful Context**: Get automated responses to common questions
- **Consistent Standards**: Everyone gets the same quality checklist
- **Time Savings**: Common concerns are addressed automatically

### ✅ For the Team
- **Quality Assurance**: Consistent review process
- **Documentation**: Review guidelines are always available
- **Efficiency**: Reduces back-and-forth on common issues

## Example Workflow Run

### 1. Developer Opens PR
```
User: Opens PR with 150 lines changed
  ↓
Workflow: Triggers "review" job
  ↓
Bot: Posts automated review comment with statistics
Bot: Adds "size/S" label
```

### 2. Reviewer Comments
```
Reviewer: "Have tests been added for this?"
  ↓
Workflow: Triggers "respond-to-review" job
  ↓
Bot: Detects question keyword "?"
Bot: Identifies "test" topic
Bot: Posts response with testing guidelines
```

### 3. Reviewer Approves
```
Reviewer: "LGTM! Great work!"
  ↓
Workflow: Triggers "respond-to-review" job
  ↓
Bot: No question keywords found
Bot: Does not post response (prevents spam)
```

## Anti-Loop Protection

The workflow includes protection against infinite loops:

1. **Bot Detection**: Checks if sender is a bot
2. **Question Detection**: Only responds to actual questions
3. **No Self-Response**: Bots ignore other bot comments

## Permissions Required

| Permission | Scope | Purpose |
|------------|-------|---------|
| `contents` | read | Checkout repository code |
| `pull-requests` | write | Post review comments |
| `issues` | write | Add labels to PRs |

## Configuration Files

- **Workflow**: `.github/workflows/pr-review.yml` (321 lines)
- **Documentation**: `.github/workflows/README.md`
- **Examples**: `.github/workflows/REVIEW_RESPONSE_EXAMPLES.md`
- **Summary**: `IMPLEMENTATION_SUMMARY.md`

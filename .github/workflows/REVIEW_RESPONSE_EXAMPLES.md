# PR Review Response Examples

This document demonstrates how the automated review response system works with different types of reviewer comments.

## How It Works

The workflow detects questions or requests for clarification in review comments by looking for keywords like:
- `?` (question mark)
- `why`, `how`, `what`
- `could you`, `can you`
- `please explain`, `clarify`
- `unclear`, `confused`
- `help`, `question`, `wondering`

When any of these keywords are detected, the bot automatically responds with helpful guidance.

## Example Scenarios

### Example 1: Testing Question

**Reviewer Comment:**
> "Have tests been added for this new feature?"

**Bot Response:**
```markdown
## 🤖 Copilot Review Response

Thank you for your review feedback! 

Regarding testing:
- This PR should include relevant tests as noted in the review checklist.
- Please ensure test coverage is maintained or improved.
- Check that all existing tests still pass.

---
*This is an automated response to help address common review concerns. The PR author will provide specific answers to your questions.*
```

---

### Example 2: Documentation Question

**Reviewer Comment:**
> "Could you add documentation for this new API endpoint?"

**Bot Response:**
```markdown
## 🤖 Copilot Review Response

Thank you for your review feedback! 

Regarding documentation:
- Please update relevant documentation if this PR changes behavior or adds features.
- Consider updating README, inline comments, or API documentation as needed.

---
*This is an automated response to help address common review concerns. The PR author will provide specific answers to your questions.*
```

---

### Example 3: Performance Concern

**Reviewer Comment:**
> "What is the performance impact of this change?"

**Bot Response:**
```markdown
## 🤖 Copilot Review Response

Thank you for your review feedback! 

Regarding performance:
- Consider performance implications of the changes.
- Add benchmarks if introducing performance-sensitive code.
- Profile the changes if there are concerns about efficiency.

---
*This is an automated response to help address common review concerns. The PR author will provide specific answers to your questions.*
```

---

### Example 4: Security Question

**Reviewer Comment:**
> "How does this handle sensitive data? Are there any security implications?"

**Bot Response:**
```markdown
## 🤖 Copilot Review Response

Thank you for your review feedback! 

Regarding security:
- Please review for potential security vulnerabilities.
- Ensure sensitive data is properly handled.
- Consider running security scanning tools.

---
*This is an automated response to help address common review concerns. The PR author will provide specific answers to your questions.*
```

---

### Example 5: Breaking Changes

**Reviewer Comment:**
> "Is this a breaking change? Will it affect backward compatibility?"

**Bot Response:**
```markdown
## 🤖 Copilot Review Response

Thank you for your review feedback! 

Regarding compatibility:
- Please verify if this introduces any breaking changes.
- Consider versioning and migration strategies if needed.
- Update CHANGELOG if applicable.

---
*This is an automated response to help address common review concerns. The PR author will provide specific answers to your questions.*
```

---

### Example 6: Multiple Topics

**Reviewer Comment:**
> "Could you clarify how this handles performance and security? Also, are there tests for the edge cases?"

**Bot Response:**
```markdown
## 🤖 Copilot Review Response

Thank you for your review feedback! 

Regarding testing:
- This PR should include relevant tests as noted in the review checklist.
- Please ensure test coverage is maintained or improved.
- Check that all existing tests still pass.

Regarding performance:
- Consider performance implications of the changes.
- Add benchmarks if introducing performance-sensitive code.
- Profile the changes if there are concerns about efficiency.

Regarding security:
- Please review for potential security vulnerabilities.
- Ensure sensitive data is properly handled.
- Consider running security scanning tools.

---
*This is an automated response to help address common review concerns. The PR author will provide specific answers to your questions.*
```

---

### Example 7: Generic Question (No Specific Topic)

**Reviewer Comment:**
> "Why did you choose this approach?"

**Bot Response:**
```markdown
## 🤖 Copilot Review Response

Thank you for your review feedback! 

Your comment has been noted. The PR author will review your feedback and provide clarification or make necessary changes.

**Common review items to check:**
- [ ] Code quality and standards compliance
- [ ] Test coverage and correctness
- [ ] Documentation completeness
- [ ] Performance considerations
- [ ] Security implications

---
*This is an automated response to help address common review concerns. The PR author will provide specific answers to your questions.*
```

---

### Example 8: Statement (No Question) - Bot Does NOT Respond

**Reviewer Comment:**
> "Looks good to me! Nice work on the refactoring."

**Bot Response:**
*(No automated response - the comment doesn't contain question keywords)*

---

### Example 9: Bot Comment - Bot Does NOT Respond

**Comment from:** `github-actions[bot]`

**Bot Response:**
*(No automated response - bots don't respond to other bots to prevent infinite loops)*

---

## Benefits

1. **Faster Feedback**: Reviewers get immediate automated guidance
2. **Consistency**: All reviews get the same quality of automated responses
3. **Education**: Helps guide reviewers and authors on what to consider
4. **No Spam**: Only responds when questions are detected
5. **No Loops**: Ignores bot comments to prevent infinite response cycles
6. **Human-Friendly**: Makes it clear this is automated and that human follow-up is expected

## Customization

To customize the response logic, edit the `respond-to-review` job in `.github/workflows/pr-review.yml`:

- Add new keywords to detect
- Add new topic-specific responses
- Modify the response templates
- Adjust the bot detection logic

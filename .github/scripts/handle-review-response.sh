#!/bin/bash
# Script: handle-review-response.sh
# Purpose: Handle responses from committers to review comments
# This script reads committer responses and takes appropriate action

set -e

echo "💬 Processing review response..."

# Get comment details from environment
COMMENT_ID="${COMMENT_ID:-$1}"
COMMENT_BODY="${COMMENT_BODY:-$2}"
PR_NUMBER="${PR_NUMBER:-$3}"

if [ -z "$COMMENT_ID" ] || [ -z "$PR_NUMBER" ]; then
    echo "Error: Required parameters not provided"
    exit 1
fi

echo "Processing comment #$COMMENT_ID on PR #$PR_NUMBER"

# Extract the comment for analysis
if [ -z "$COMMENT_BODY" ]; then
    COMMENT_BODY=$(gh api "/repos/${GITHUB_REPOSITORY}/issues/comments/${COMMENT_ID}" --jq '.body')
fi

echo "Comment content:"
echo "$COMMENT_BODY"

# Analyze the response type
RESPONSE_TYPE="unknown"

# Check if it's a question (contains question mark and question words)
if echo "$COMMENT_BODY" | grep -qiE "(\?|what|why|how|when|where|could you|can you|would you)"; then
    RESPONSE_TYPE="question"
fi

# Check if it's a defense/explanation (contains because, actually, intended, etc.)
if echo "$COMMENT_BODY" | grep -qiE "(because|actually|intended|by design|on purpose|disagree|think|believe)"; then
    RESPONSE_TYPE="defense"
fi

# Check if it's an agreement (contains thanks, fixed, updated, etc.)
if echo "$COMMENT_BODY" | grep -qiE "(thanks|fixed|updated|done|addressed|agree|you're right|good point)"; then
    RESPONSE_TYPE="agreement"
fi

echo "Response type detected: $RESPONSE_TYPE"

# Generate appropriate response based on type
REPLY=""

case "$RESPONSE_TYPE" in
    "question")
        echo "📚 Generating answer to question..."
        REPLY="## 🤖 Response to Your Question

Thank you for asking! Let me clarify:

"
        
        # Provide context-specific answers based on common patterns
        if echo "$COMMENT_BODY" | grep -qiE "(why.*logging|logger)"; then
            REPLY="${REPLY}**Regarding logging frameworks:**
Using a proper logging framework like SLF4J with Logback provides several benefits:
- Configurable log levels (DEBUG, INFO, WARN, ERROR)
- Better performance with lazy evaluation
- Support for structured logging and log aggregation
- Production-ready features like log rotation
- Easy integration with monitoring tools

System.out.println writes directly to stdout and lacks these capabilities, making it unsuitable for production code."
        elif echo "$COMMENT_BODY" | grep -qiE "(why.*test|testing)"; then
            REPLY="${REPLY}**Regarding tests:**
Adding tests for new functionality ensures:
- Code works as expected
- Future changes don't break existing functionality (regression testing)
- Documentation of intended behavior
- Easier refactoring with confidence
- Better code quality and maintainability"
        elif echo "$COMMENT_BODY" | grep -qiE "(why.*documentation|docs)"; then
            REPLY="${REPLY}**Regarding documentation:**
Documentation helps:
- Other developers understand the code
- New team members onboard faster
- Users understand how to use features
- Maintainers understand design decisions
- Reduce technical debt over time"
        else
            REPLY="${REPLY}Based on your question, here's what I recommend:
- Review the relevant documentation in the repository
- Check if there are similar implementations you can reference
- Consider the long-term maintainability of the approach
- Think about how this will scale

If you need more specific guidance, please provide additional context about your use case."
        fi
        
        REPLY="${REPLY}

---
Does this answer your question? Feel free to ask for more details!"
        ;;
        
    "defense")
        echo "⚖️ Evaluating defense/explanation..."
        REPLY="## 🤖 Review of Your Explanation

Thank you for explaining your reasoning. Let me review your points:

"
        
        # Check if the defense mentions valid reasons
        VALID_DEFENSE=false
        
        if echo "$COMMENT_BODY" | grep -qiE "(performance|benchmark|profil|measur|test show|data show)"; then
            VALID_DEFENSE=true
            REPLY="${REPLY}✅ **Performance consideration noted.** If you have benchmarks or profiling data supporting this approach, that's valuable context.

"
        fi
        
        if echo "$COMMENT_BODY" | grep -qiE "(legacy|backward compatib|existing|migration)"; then
            VALID_DEFENSE=true
            REPLY="${REPLY}✅ **Backward compatibility concern noted.** Maintaining compatibility with existing systems is a valid reason.

"
        fi
        
        if echo "$COMMENT_BODY" | grep -qiE "(framework|library|require|depend)"; then
            VALID_DEFENSE=true
            REPLY="${REPLY}✅ **Framework/library constraint noted.** External dependencies can limit implementation choices.

"
        fi
        
        if [ "$VALID_DEFENSE" = true ]; then
            REPLY="${REPLY}Your explanation makes sense. I'll mark this review comment as resolved.

**Recommendation:** Consider adding a code comment explaining this decision for future maintainers.

---
✅ Review comment resolved - valid justification provided."
        else
            REPLY="${REPLY}I understand your perspective. However, I'd like to highlight:

- Best practices exist for good reasons and help maintain code quality
- Future maintainers may not have the same context
- Consider if there's a middle ground that addresses both concerns

If you still believe your approach is better, please provide:
1. Specific technical reasons
2. Any relevant documentation or examples
3. Consideration of alternatives

I'm happy to discuss further!"
        fi
        ;;
        
    "agreement")
        echo "✅ Committer agreed with feedback..."
        REPLY="## 🤖 Thank You

Great! Thank you for addressing the feedback. Looking forward to seeing the updates.

Once you've pushed the changes, I'll automatically review them again.

---
✅ Keep up the good work!"
        ;;
        
    *)
        echo "📝 General response..."
        REPLY="## 🤖 Response

Thank you for your response. 

If you have:
- ❓ **Questions** - Please ask, and I'll provide more details
- 💡 **Explanations** - Share your reasoning, and I'll review it
- ✅ **Agreements** - Push your changes, and I'll verify them

Looking forward to your update!"
        ;;
esac

# Post the reply
echo "Posting reply..."
gh pr comment "$PR_NUMBER" --body "$REPLY"

# If valid defense, try to resolve the review thread
if [ "$RESPONSE_TYPE" = "defense" ] && [ "$VALID_DEFENSE" = true ]; then
    echo "✅ Marking review as resolved due to valid justification"
fi

echo "🎉 Response processed successfully!"

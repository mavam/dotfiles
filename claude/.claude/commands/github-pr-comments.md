---
description: Work on a Github PR review
allowed-tools: Bash(gh api graphql:*), Bash(gh pr view:*)
---

Your task is to fetch and address all unresolved review comments for the current PR.

If you don't know yet which repo and PR, use the command `gh pr view --json url`.
The relevant data for the current directory can be deduced from the returned url.

# Fetching comments

Use the following command to fetch all unresolved pull requests,
replacing owner, name and number. The example command is for PR #5317
in repo tenzir/tenzir.

```
gh api graphql -f query='
      {
        repository(owner: "tenzir", name: "tenzir") {
          pullRequest(number: 5317) {
            reviewThreads(first: 50) {
              nodes {
                id
                isResolved
                comments(first: 20) {
                  nodes {
                    id
                    body
                    isMinimized
                    minimizedReason
                    path
                    line
                  }
                }
              }
            }
          }
        }
      }'
```

# Replying

Use the following command to reply to a pull request comment, replacing body
and thread id with the correct values:

```
gh api graphql -f query='
      mutation {
        addPullRequestReviewThreadReply(input: {
          pullRequestReviewThreadId: "PRRT_kwDOBxHP9c5Wmkcp"
          body: "And this is a test response"
        }) {
          comment {
            id
          }
        }
      }'
```

The thread id is returned by the command for fetching comments described above.

# Instructions

Go through every comment, and for each ask the user if you should:
 - fix the issue
   -> spawn a subtask to make code changes and commit
   -> if making multiple small adjustments, prefer to amend the previous commit instead
      of making lots of small ones.
 - respond to the review comment
   -> ask for precise wording, don't make things up
   -> use the graphql mutation described in the previous paragraph to add a reply
 - skip it and do nothing for now

Repeat until all unresolved comments are handled.

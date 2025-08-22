---
description: Create an Execution Plan for systematic task implementation
---

## Task description: $ARGUMENTS

Generate a structured execution plan for the specified task. This plan will serve
as persistent memory and enable safe task resumption across sessions.

## When to Use This Command

Use `generate-plan` for:

- Multi-step refactoring tasks
- Complex debugging sessions
- Feature implementations without needing a full PRP
- Any task that might be interrupted and resumed later
- Tasks requiring strict progress tracking

## Plan Generation Process

1. **Analyze the Task**
   - Break down into atomic, verifiable steps
   - Identify dependencies between steps
   - Define clear success criteria

2. **Create Plan Structure**
   - Generate `plans/{task-name}/plan.md`
   - Include anti-drift protocols
   - Set up progress tracking

3. **Define Recovery Points**
   - Each step should be resumable
   - Results must be recorded immediately
   - Context preserved for any future session

## Output

Save the plan as: `plans/{task-name}/plan.md`

Where task-name is derived from the task description (kebab-case).

## Project Detection Guidelines

When generating a plan, first detect the project type by examining:

1. **Package managers**: package.json (Node.js), Cargo.toml (Rust), go.mod (Go),
   requirements.txt/pyproject.toml (Python), pom.xml (Java), etc.
2. **Build files**: Makefile, CMakeLists.txt (C++/CMake), etc.
3. **Configuration files**: .eslintrc, .prettierrc, tox.ini, etc.
4. **Directory structure**: src/, lib/, tests/, etc.

Adapt the plan's commands and paths based on the detected project type.

## Plan Template

````markdown
# [Task Name] Plan

**THIS PLAN FILE**: `plans/{task-name}/plan.md`
**Created**: [DATE TIME]
**Type**: [feature|bugfix|refactor|debug|other]
**Estimated Complexity**: [simple|moderate|complex]

## CRITICAL: Memory Management Protocol

### The Three Commandments

1. **RELOAD BEFORE EVERY ACTION**: This plan is your only memory
2. **UPDATE AFTER EVERY ACTION**: If not written, it didn't happen
3. **TRUST ONLY THE PLAN**: Not memory, only what's written here

## Task Overview

### Objective

[Clear description of what needs to be accomplished]

### Current State

[Starting conditions, existing code, dependencies]

### Success Criteria

[How we know the task is complete]

### Constraints

[Time limits, compatibility requirements, etc.]

## Quick Reference

### Key Commands

```bash
# [Detect and add project-specific commands based on project type]
# Examples:
# - Testing: [test command]
# - Linting: [lint command]
# - Type checking: [typecheck command]
# - Building: [build command]
# - Running: [run command]
```

### Important Paths

<!-- Identify based on project structure -->

- Source directory: [src/, lib/, app/, etc.]
- Test directory: [tests/, test/, spec/, etc.]
- Configuration files: [relevant config files]
- Documentation: [docs/, README, etc.]

## Implementation Steps

### Step 1: [Descriptive Title]

**Status:** ⏳ TODO
**Description:** [What this step accomplishes]
**Actions:**

<!-- Language/tool-specific actions -->

```bash
# Commands specific to the detected project type
```

**Success Criteria:** [How to verify completion]
**Dependencies:** [Any prerequisites]
**Result:** [To be filled when complete]

### Step 2: [Next Step]

**Status:** ⏳ TODO
[Continue pattern...]

## Status Legend

- ⏳ **TODO**: Not started
- 🔄 **IN_PROGRESS**: Currently working (max 1)
- ✅ **DONE**: Completed successfully
- ❌ **FAILED**: Failed, needs retry
- ⏭️ **SKIPPED**: Not needed (explain why)
- 🚫 **BLOCKED**: Can't proceed (explain why)

## Progress Tracking

### Summary

- Total Steps: [N]
- Completed: 0
- In Progress: 0
- Blocked: 0
- Success Rate: 0%

### Execution Log

<!-- Update after each action -->

- [TIMESTAMP]: Step N started
- [TIMESTAMP]: Step N completed with result: [summary]

## Recovery Instructions

If resuming this plan:

1. Read this entire file first
2. Check the Execution Log for last action
3. Find the 🔄 IN_PROGRESS or next ⏳ TODO step
4. Continue from that point
5. Update immediately after each action

## Context Preservation

### Key Decisions Made

<!-- Record important choices and rationale -->

### Lessons Learned

<!-- What worked, what didn't, why -->

### Commands That Worked

```bash
# Save successful command combinations
```

## Related Resources

### Documentation

- [Relevant docs URLs]

### Files Modified

<!-- Track all files touched -->

- [ ] [file path] - [what was changed]
- [ ] [file path] - [what was changed]

### PRP Reference

<!-- If this plan was generated from a PRP -->

PRP Location: `prps/{feature-name}.md` (if applicable)

## Completion Checklist

Before marking complete:

- [ ] All steps marked as ✅ DONE or ⏭️ SKIPPED
- [ ] Success criteria met
- [ ] Tests passing (if applicable)
- [ ] Code reviewed
- [ ] Documentation updated (if needed)

---

_Plan created: [date]_
_Last updated: [date]_
_Estimated time: [hours]_
_Actual time: [to be filled]_

## Best Practices

1. **Atomic Steps**: Each step should be independently verifiable
2. **Immediate Updates**: Record results before moving to next step
3. **Clear Commands**: Include exact commands to run
4. **Failure Recovery**: Document what to do if a step fails
5. **Time Tracking**: Note actual vs estimated time for future planning

## Anti-Patterns to Avoid

- ❌ Don't batch multiple updates - update after each action
- ❌ Don't rely on memory - the plan is your only truth
- ❌ Don't skip recording "obvious" results - everything matters
- ❌ Don't have multiple IN_PROGRESS steps
- ❌ Don't proceed if a dependency failed

Remember: This plan enables ANY AI to continue your work seamlessly.
````

---
description: Create an Execution Plan for systematic task implementation
---

## Usage Options

### Option 1: Generate plan from PRP
```
generate-plan .ai/feature-name-prp.md
```

### Option 2: Generate standalone plan  
```
generate-plan "task description"
```

## Input: $ARGUMENTS

The input can be either:
- **PRP File Path**: Path to an existing `.ai/{feature-name}-prp.md` file
- **Task Description**: Direct description of task to implement

## When to Use This Command

Use `generate-plan` for:

- **From PRP**: Converting a completed PRP into an execution plan (Phase 2 of PRP+PLAN workflow)
- **Standalone**: Multi-step refactoring, debugging, or implementation tasks that don't need a full PRP
- **Resumable Work**: Any task that might be interrupted and resumed later
- **Progress Tracking**: Tasks requiring strict progress tracking

## Plan Generation Process

1. **Detect Input Type**
   - If input starts with `.ai/` and ends with `-prp.md`, treat as PRP file path
   - Otherwise, treat as task description

2. **For PRP Input:**
   - Read the PRP file for complete context
   - Convert PRP tasks to executable steps
   - Reference PRP for requirements and validation gates
   - Maintain context link to PRP

3. **For Task Description:**
   - Analyze the task directly
   - Break down into atomic, verifiable steps
   - Define clear success criteria based on task

4. **Create Plan Structure**
   - Generate `.ai/{task-name}-plan.md`
   - Include anti-drift protocols
   - Set up progress tracking

## Output

**From PRP**: Save as `.ai/{feature-name}-plan.md` (matching the PRP name)
**From Task**: Save as `.ai/{task-name}-plan.md` (derived from task description)

## Plan Template

````markdown
# [Task Name] Execution Plan

**THIS PLAN FILE**: `.ai/{task-name}-plan.md`
[**PRP REFERENCE**: `.ai/{feature-name}-prp.md` (if generated from PRP)]
**Created**: [DATE TIME]
**Type**: [feature|bugfix|refactor|debug|other]
**Estimated Complexity**: [simple|moderate|complex]

## CRITICAL: Execution Protocol

### The Three Commandments

1. **RELOAD BEFORE EVERY ACTION**: This plan is your only memory
2. **UPDATE AFTER EVERY ACTION**: If not written, it didn't happen
3. **TRUST ONLY THE PLAN**: Not memory, only what's written here

## Context

[If from PRP: Pull objective, success criteria, and key references from PRP]
[If standalone: Define objective, current state, success criteria, constraints]

### Objective

[What needs to be accomplished]

### Success Criteria

[How we know the task is complete]

[If from PRP: Reference PRP validation gates]

### Key References

[If from PRP: Pull critical URLs and file paths from PRP]
[If standalone: Identify based on codebase analysis]

## Implementation Steps

[If from PRP: Convert each PRP task to a numbered step]
[If standalone: Break down task into atomic steps]

### Step 1: [Descriptive Title]

**Status:** ⏳ TODO
**Description:** [What this step accomplishes]
**Actions:**

- [Specific commands or code changes]

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

[Record all actions with timestamps]

## Recovery Instructions

If resuming this plan:

1. Read this entire file first
2. [If from PRP: Also review the PRP for context]
3. Check the Execution Log for last action
4. Find the 🔄 IN_PROGRESS or next ⏳ TODO step
5. Continue from that point
6. Update immediately after each action

## Context Preservation

### Key Decisions Made

[Record important choices and rationale]

### Files Modified

[Track all files touched]

- [ ] [file path] - [what was changed]

## Completion Checklist

Before marking complete:

- [ ] All steps marked as ✅ DONE or ⏭️ SKIPPED
- [ ] Success criteria met
- [ ] Tests passing (if applicable)
- [ ] Code reviewed
- [ ] Documentation updated (if needed)
[If from PRP: Reference PRP success criteria]

---

## Anti-Patterns to Avoid

- ❌ Don't batch multiple updates - update after each action
- ❌ Don't rely on memory - the plan is your only truth
- ❌ Don't skip recording results
- ❌ Don't have multiple IN_PROGRESS steps
- ❌ Don't proceed if a dependency failed
[If from PRP: Include anti-patterns from PRP]

Remember: This plan enables ANY AI to continue your work seamlessly.
````
---
description: Create a Product Requirements Prompt (PRP) with Execution Plan
---

## Feature file: $ARGUMENTS

Generate a complete PRP for general feature implementation with thorough
research AND an execution plan for systematic implementation. This creates a
two-phase workflow: Discovery (PRP) → Execution (PLAN).

The AI agent only gets the context you are appending to the PRP and training
data. Assume the AI agent has access to the codebase and the same knowledge
cutoff as you, so its important that your research findings are included or
referenced in the PRP. The Agent has Websearch capabilities, so pass URLs to
documentation and examples.

## Two-Phase Workflow

### Phase 1: Discovery & Requirements (PRP)
- Research and context gathering
- Pattern identification
- Documentation references
- Implementation blueprint

### Phase 2: Execution & Memory Management (PLAN)
- Step-by-step implementation
- Anti-drift protocols
- Progress tracking
- Safe resumability

## Research Process

1. **Codebase Analysis**
   - Search for similar features/patterns in the codebase
   - Identify files to reference in PRP
   - Note existing conventions to follow
   - Check test patterns for validation approach

2. **External Research**
   - Search for similar features/patterns online
   - Library documentation (include specific URLs)
   - Implementation examples (GitHub/StackOverflow/blogs)
   - Best practices and common pitfalls

3. **User Clarification** (if needed)
   - Specific patterns to mirror and where to find them?
   - Integration requirements and where to find them?

## PRP Generation

Use the template below the `---` marker to generate a PRP.

### Critical context to include and pass to the AI agent

- **Documentation**: URLs with specific sections
- **Code Examples**: Real snippets from codebase
- **Gotchas**: Library quirks, version issues
- **Patterns**: Existing approaches to follow

### Implementation blueprint

- Start with end-user documentation
- Proceed with pseudocode showing approach
- Include error handling strategy
- List tasks to be completed to fullfill the PRP in the order they should be
  completed

### Validation Gates

Include validation gates to understand when you have converged.

Typically, this includes *integration* and/or *unit* tests. If both types of
testing frameworks are available, focus on integration tests first. Use unit
tests only for micro testing component APIs at the lower level.

CRITICAL: AFTER YOU ARE DONE RESEARCHING AND EXPLORING THE CODEBASE BEFORE YOU START WRITING THE PRP

ULTRATHINK ABOUT THE PRP AND PLAN YOUR APPROACH THEN START WRITING THE PRP

## Output

1. Save the PRP as: `prps/{feature-name}.md`
2. Generate and save the execution plan as: `plans/{feature-name}/plan.md`
3. The PLAN should reference the PRP for context
4. Each validation gate in the PRP becomes a step in the PLAN

## Quality Checklist

- [ ] All necessary context included
- [ ] Validation gates are executable by AI
- [ ] References existing patterns
- [ ] Clear implementation path
- [ ] Error handling documented

Score the PRP on a scale of 1-10 (confidence level to succeed in one-pass implementation using claude codes)

## Generate Execution Plan

After creating the PRP, automatically generate a PLAN using the template below.
The PLAN should:
- Reference the PRP for requirements context
- Convert each validation gate into an executable step
- Include anti-drift protocols from the PLAN template
- Provide clear success criteria for each step

Remember: The goal is one-pass implementation success through comprehensive context
and disciplined execution tracking.

---

# Enhanced PRP Template - Context-Rich with Execution Planning

## Purpose

Template optimized for AI agents to implement features with sufficient context
and self-validation capabilities to achieve working code through iterative
refinement.

## Core Principles

1. **Context is king**: Include ALL necessary documentation, examples, and caveats
2. **Validation loops**: Provide executable tests/lints the AI can run and fix
3. **Information dense**: Use keywords and patterns from the codebase
4. **Progressive success**: Start simple, validate, then enhance
5. **Global rules**: Be sure to follow all rules in CLAUDE.md

## Goal

[What needs to be built - be specific about the end state and desires]

## Why

- [Business value and user impact]
- [Integration with existing features]
- [Problems this solves and for whom]

## What

[User-visible behavior and technical requirements]

## All Needed Context

### Documentation & References (list all context needed to implement the feature)

```yaml
# MUST READ - Include these in your context window
- url: [Official API docs URL]
  why: [Specific sections/methods you'll need]
- file: [path/to/example.py]
  why: [Pattern to follow, gotchas to avoid]
- doc: [Library documentation URL]
  section: [Specific section about common pitfalls]
  critical: [Key insight that prevents common errors]
- docfile: [PRPs/ai_docs/file.md]
  why: [docs that the user has pasted in to the project]
```

## Validation Loop

1. Syntax & style
2. Unit tests
3. Integration tests

## Final validation Checklist

- [ ] All tests pass
- [ ] No linting errors
- [ ] Manual test successful
- [ ] Error cases handled gracefully
- [ ] Logs are informative but not verbose
- [ ] Documentation updated if needed

## Memory Management Protocol

### During Implementation
- The execution PLAN is your ONLY memory between sessions
- Update the PLAN after EVERY action
- Record all decisions and their rationale
- If interrupted, the PLAN enables perfect resumption

### Anti-Drift Guidelines
- Reload the PLAN before every action
- Trust only what's written in the PLAN
- The PRP defines the "north star" - reference it regularly
- Mark progress immediately to prevent re-work

## Implementation Order

[List tasks in the order they should be completed - these become PLAN steps]

1. [First task with clear success criteria]
2. [Second task with dependencies noted]
3. [Continue with all tasks...]

## Anti-Patterns to Avoid

- ❌ Don't create new patterns when existing ones work
- ❌ Don't skip validation because "it should work"
- ❌ Don't ignore failing tests - fix them
- ❌ Don't use synchronous functions in an asynchronous context
- ❌ Don't hardcode values that should be config
- ❌ Don't proceed without updating the PLAN
- ❌ Don't trust memory over written documentation

## Execution Plan Reference

The execution plan for this PRP is located at: `plans/{feature-name}/plan.md`

The PLAN contains:
- Step-by-step implementation tasks
- Current progress status
- Detailed results of completed steps
- Recovery instructions if interrupted

---

# PLAN Template - Execution & Memory Management

When generating the execution PLAN, use this template:

```markdown
# [Feature Name] Execution Plan
**PRP Reference**: `prps/{feature-name}.md`
**Created**: [DATE TIME]
**Status**: 🔄 Active

## CRITICAL: Execution Protocol

### The Three Commandments
1. **RELOAD BEFORE EVERY ACTION**: This plan is your only memory
2. **UPDATE AFTER EVERY ACTION**: If not written, it didn't happen
3. **TRUST ONLY THE PLAN**: Not memory, only what's written here

## Context from PRP

### Objective
[Pull from PRP]

### Success Criteria
[Pull from PRP validation gates]

### Key References
[Pull critical URLs and file paths from PRP]

## Implementation Steps

[Convert each PRP validation gate and implementation task into a step]

### Step 1: [Title from PRP task]
**Status:** 📝 TODO
**Description:** [What this accomplishes]
**Actions:**
- [Specific commands or code changes]
**Success Criteria:** [From PRP validation gate]
**Result:** [To be filled when complete]

### Step 2: [Next task]
[Continue for all tasks...]

## Progress Tracking

- Total Steps: [N]
- Completed: [0]
- In Progress: [0]
- Blocked: [0]

## Execution Log

[Timestamp and summary of each action taken]

## Recovery Instructions

If this plan is resumed by another session:
1. Read this entire file
2. Check the last completed step
3. Resume from the next 📝 TODO step
4. Update status immediately after each action
```

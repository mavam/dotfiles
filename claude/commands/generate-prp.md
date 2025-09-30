---
description: Create a Product Requirements Prompt (PRP) for comprehensive feature planning
---

## Feature description: $ARGUMENTS

Generate a complete Product Requirements Prompt (PRP) for the specified feature. 
This is Phase 1 of the two-step PRP + PLAN workflow: Discovery & Requirements.

The PRP will provide comprehensive context for later execution but will NOT 
automatically generate a PLAN. After reviewing and editing the PRP, use 
`generate-plan` with the PRP as input to create the execution plan.

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

Use the template below to generate a comprehensive PRP.

### Critical context to include

- **Documentation**: URLs with specific sections
- **Code Examples**: Real snippets from codebase
- **Gotchas**: Library quirks, version issues
- **Patterns**: Existing approaches to follow

### Implementation blueprint

- Start with end-user documentation
- Proceed with pseudocode showing approach
- Include error handling strategy
- List tasks to be completed in the order they should be completed

### Validation Gates

Include validation gates to understand when you have converged.

Typically, this includes _integration_ and/or _unit_ tests. If both types of
testing frameworks are available, focus on integration tests first. Use unit
tests only for micro testing component APIs at the lower level.

## Output

Save the PRP as: `.ai/{feature-name}-prp.md`

## Next Steps

After the PRP is generated:
1. Review and edit the PRP as needed
2. Run `generate-plan` with the PRP file as input to create the execution plan

## Quality Checklist

- [ ] All necessary context included
- [ ] Validation gates are executable by AI
- [ ] References existing patterns
- [ ] Clear implementation path
- [ ] Error handling documented

Score the PRP on a scale of 1-10 (confidence level to succeed in one-pass implementation).

---

# PRP Template - Context-Rich for AI Implementation

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

### Documentation & References

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

### Codebase Patterns to Follow

[Specific examples from the codebase that should be mimicked]

### Implementation Approach

[Detailed technical approach with pseudocode and architecture decisions]

## Validation Gates

### Testing Strategy

[How to validate the implementation works correctly]

### Performance Criteria

[Any performance requirements or benchmarks]

### Integration Points

[How this feature integrates with existing systems]

## Implementation Order

[List tasks in the order they should be completed - these will become PLAN steps]

1. [First task with clear success criteria]
2. [Second task with dependencies noted]
3. [Continue with all tasks...]

## Anti-Patterns to Avoid

- ❌ Don't create new patterns when existing ones work
- ❌ Don't skip validation because "it should work"
- ❌ Don't ignore failing tests - fix them
- ❌ Don't use synchronous functions in an asynchronous context
- ❌ Don't hardcode values that should be config

## Success Criteria

### Definition of Done

- [ ] All functionality implemented
- [ ] All tests pass
- [ ] No linting errors
- [ ] Manual testing successful
- [ ] Error cases handled gracefully
- [ ] Documentation updated if needed

### Validation Checklist

- [ ] Syntax & style correct
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Performance acceptable
- [ ] Security considerations addressed

## Notes for PLAN Generation

This PRP contains all context needed for implementation. When generating the
execution PLAN:

- Convert each task in "Implementation Order" to a PLAN step
- Use validation gates as step success criteria
- Reference this PRP for context and requirements
- Include anti-drift protocols for safe resumability
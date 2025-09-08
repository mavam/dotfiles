# Claude Code Commands Documentation

Custom commands for Claude Code that enhance AI-assisted software development with structured workflows, planning tools, and specialized integrations.

## Available Commands

| Command              | Description                                         | Use Case                            |
| -------------------- | --------------------------------------------------- | ----------------------------------- |
| `generate-prp`       | Create Product Requirements Prompt with research    | Complex features needing discovery  |
| `generate-plan`      | Create execution plan for systematic implementation | Quick tasks, refactoring, debugging |
| `github-pr-comments` | Fetch and address PR review comments                | Working on GitHub pull requests     |

## Core Workflow: PRP + PLAN System

A clean two-step development workflow that separates discovery/requirements (PRP) from execution planning (PLAN).

## Overview

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Feature   │────▶│     PRP      │────▶│   Review &   │────▶│    PLAN      │
│   Request   │     │  (Research)  │     │    Edit      │     │ (Execution)  │
└─────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
                           │                     │                     │
                           ▼                     │                     ▼
                      .ai/{name}-prp.md          │            .ai/{name}-plan.md
                                                 │
                                         User can edit PRP
```

## Phase 1: Discovery & Requirements (PRP)

**Purpose**: Comprehensive research and context gathering for one-pass implementation success.

**Command**: `generate-prp <feature-description>`

**Output**: `.ai/{feature-name}-prp.md` - Complete requirements and context

**Key Components**:

- External research (documentation, examples)
- Codebase analysis (patterns, conventions)
- Implementation blueprint
- Validation gates
- Task ordering for execution

**Important**: The PRP is generated independently and can be reviewed/edited before creating the PLAN.

## Phase 2: Execution Planning (PLAN)

**Purpose**: Convert PRP or task description into systematic execution plan with anti-drift protocols.

**Commands**:
- `generate-plan .ai/{feature-name}-prp.md` (from existing PRP)
- `generate-plan <task-description>` (standalone task)

**Output**: `.ai/{task-name}-plan.md`

**Key Features**:

- Step-by-step execution tracking
- Persistent memory across sessions
- Anti-drift protocols (reload → execute → update)
- Safe resumability by any AI
- Progress tracking and logging

## How Commands Work

### Understanding $ARGUMENTS

When you run a command like:

```bash
claude code --command generate-prp "Add OAuth login with GitHub"
```

The text `"Add OAuth login with GitHub"` becomes `$ARGUMENTS` in the command file. Claude receives the entire command file content with `$ARGUMENTS` replaced by your input.

### Command Execution Flow

1. **You invoke**: `claude code --command generate-prp "your feature description"`
2. **Claude receives**: The command file with `$ARGUMENTS` → "your feature description"
3. **Claude follows**: The instructions in the command file to generate outputs
4. **Files created**: Based on the template and research Claude performs

## Usage Patterns

### 1. Full Feature Development (Two-Step Process)

```bash
# Step 1: Generate PRP only
claude code --command generate-prp "Add user authentication with OAuth"

# $ARGUMENTS = "Add user authentication with OAuth"
# Claude will:
# - Research OAuth patterns in your codebase
# - Find relevant documentation
# - Generate .ai/user-authentication-oauth-prp.md

# Step 2: Review/edit the PRP, then generate PLAN
claude code --command generate-plan .ai/user-authentication-oauth-prp.md

# Claude will:
# - Read the PRP for complete context
# - Convert PRP tasks to executable steps
# - Generate .ai/user-authentication-oauth-plan.md
# - AI then executes the plan step by step
```

### 2. Quick Tasks (Skip PRP)

```bash
# For simpler tasks that don't need extensive research
claude code --command generate-plan "Refactor database connection pooling"

# $ARGUMENTS = "Refactor database connection pooling"
# Claude will:
# - Analyze the task
# - Generate .ai/refactor-database-pooling-plan.md
# - Start execution immediately

# Immediate execution without PRP phase
```

### 3. Resuming Interrupted Work

```bash
# Any AI can resume by reading the plan
cat .ai/user-authentication-oauth-plan.md

# Find the last completed step and continue
```

### 4. Parallel Workstreams

```bash
.ai/
├── feature-x-plan.md      # Active
├── bugfix-y-plan.md       # Active
└── refactor-z-plan.md     # Paused
```

## Key Principles

### PRP Principles

1. **Context is King**: Include ALL necessary documentation
2. **Validation Loops**: Define clear success criteria
3. **Progressive Success**: Start simple, validate, enhance
4. **Information Dense**: Use codebase keywords and patterns

### PLAN Principles

1. **Plan as Memory**: The plan is the ONLY truth
2. **Immediate Updates**: Record after EVERY action
3. **Anti-Drift**: Reload before acting, update after acting
4. **Safe Resumability**: Any AI can continue the work

## The Three Commandments (from PLAN)

1. **RELOAD BEFORE EVERY ACTION**: Your memory has been wiped
2. **UPDATE AFTER EVERY ACTION**: If not written, it didn't happen
3. **TRUST ONLY THE PLAN**: Not memory, only what's written

## Integration Points

### PRP → PLAN

- Each validation gate becomes a PLAN step
- Implementation order maps to step sequence
- Context references maintained bi-directionally

### PLAN → PRP

- PLAN references PRP for requirements
- Steps validate against PRP success criteria
- Deviations documented with rationale

## Best Practices

### For PRP Creation

- Research thoroughly before writing
- Include specific URLs and code examples
- Define clear validation gates
- Map implementation order to PLAN steps

### For PLAN Execution

- One IN_PROGRESS step at a time
- Update immediately after each action
- Record both successes and failures
- Include enough context for resumption

## When to Use PRP vs PLAN

### Use PRP When

- **New features**: Need to understand existing patterns and conventions
- **Complex integrations**: Multiple systems or dependencies involved
- **Unknown territory**: Unfamiliar with the codebase area
- **High risk changes**: Need thorough planning before execution
- **API/Library usage**: Need to research documentation and best practices

**Examples**:

- "Implement real-time notifications with WebSockets"
- "Add payment processing with Stripe"
- "Integrate with third-party authentication provider"

### Use PLAN When

- **Quick fixes**: Bug is understood, just needs systematic fixing
- **Refactoring**: Clear scope, following existing patterns
- **Simple features**: Well-understood, minimal research needed
- **Debugging sessions**: Need to track investigation steps
- **Maintenance tasks**: Updates, dependency upgrades, etc.

**Examples**:

- "Fix null pointer exception in user service"
- "Refactor database queries to use connection pooling"
- "Update all deprecated API calls"
- "Add input validation to existing endpoints"

## Common Workflows

### New Feature

1. `generate-prp "feature description"`
2. Review and edit the generated PRP as needed
3. `generate-plan .ai/feature-name-prp.md`
4. Execute PLAN step by step
5. Validate against PRP success criteria

### Bug Fix

1. `generate-plan "fix bug in X"`
2. Execute plan immediately
3. Update after each debugging step
4. Document solution for future reference

### Refactoring

1. `generate-plan "refactor Y module"`
2. Create backup/rollback strategy
3. Execute incrementally with validation
4. Preserve working state between steps

## Recovery Scenarios

### Session Timeout

- Read the PLAN file completely
- Find last completed step
- Resume from next TODO

### Context Loss

- PRP provides original requirements
- PLAN shows execution history
- Continue without losing progress

### Multiple Contributors

- PLAN serves as handoff document
- Each person updates immediately
- Async collaboration enabled

## Good vs Bad Examples

### Good $ARGUMENTS for PRP

✅ **Good**: `"Implement user profile page with avatar upload to S3"`

- Specific feature and technology
- Clear scope
- Mentions integration point

✅ **Good**: `"Add Redis caching layer for API responses following our current patterns"`

- References existing patterns
- Specific technology choice
- Clear purpose

✅ **Example Feature Request**:

```
Create a simple command-line task tracker that allows users to:
- Add tasks with descriptions
- Mark tasks as complete
- List all tasks with their status
- Save tasks to a JSON file for persistence

The implementation should:
- Use Python 3
- Follow existing code patterns in the project
- Include error handling for file operations
- Have a simple CLI interface
```

This would generate a comprehensive PRP with research and execution plan.

### Bad $ARGUMENTS for PRP

❌ **Bad**: `"make it faster"`

- Too vague
- No context about what needs optimization
- No success criteria

❌ **Bad**: `"add all the missing features"`

- Undefined scope
- No specific requirements
- Impossible to validate

### Good PLAN Steps

✅ **Good Step**:

```markdown
### Step 2: Implement Avatar Upload Endpoint

**Status:** ⏳ TODO
**Description:** Create POST /api/users/:id/avatar endpoint
**Actions:**

- Add multer middleware for file upload
- Validate file type (jpg, png only)
- Resize image to 256x256 using sharp
- Upload to S3 bucket 'user-avatars'
  **Success Criteria:**
- Endpoint returns 200 with S3 URL
- Image accessible via CDN
- Old avatar deleted from S3
  **Dependencies:** Step 1 (S3 client setup) complete
```

### Bad PLAN Steps

❌ **Bad Step**:

```markdown
### Step 2: Do the upload thing

**Status:** TODO
**Description:** Make uploads work
**Actions:** Write the code
**Success Criteria:** It works
```

- Too vague
- No specific actions
- Unmeasurable success criteria
- Missing dependencies

## Validation Checklist

### PRP Quality

- [ ] All context included for one-pass success
- [ ] Validation gates are executable
- [ ] References existing patterns
- [ ] Clear implementation path
- [ ] Generates executable PLAN

### PLAN Quality

- [ ] Atomic, verifiable steps
- [ ] Clear success criteria
- [ ] Immediate update protocol
- [ ] Recovery instructions
- [ ] PRP reference maintained

## Troubleshooting Common Issues

### Issue: "Claude doesn't understand my feature description"

**Solution**: Be more specific in $ARGUMENTS

- ❌ Bad: `generate-prp "add search"`
- ✅ Good: `generate-prp "add full-text search to product catalog with Elasticsearch"`

### Issue: "Plan steps are too vague"

**Solution**: Claude needs more context about your project

- Ensure project has clear structure (package.json, requirements.txt, etc.)
- Add a CLAUDE.md file with project-specific conventions
- Reference existing similar features in the description

### Issue: "Claude keeps forgetting what it did"

**Solution**: Not following the Three Commandments

- Always reload the plan before continuing work
- Update the plan IMMEDIATELY after each action
- Never trust memory, only trust what's written

### Issue: "Generated files are in wrong location"

**Solution**: Check your working directory

- Commands assume you're in project root
- All outputs go in `.ai/` directory relative to where command is run
- PRPs are named `{feature}-prp.md`
- Plans are named `{feature}-plan.md`

### Issue: "PRP has too much/too little detail"

**Solution**: Adjust the feature description

- More detail → More comprehensive PRP
- Include constraints: "simple", "MVP", "production-ready"
- Reference existing code: "similar to our current auth system"

## Tips for Success

1. **Don't Skip Steps**: The system works when followed completely
2. **Update Immediately**: Memory is unreliable, writing is permanent
3. **Trust the Process**: Anti-drift protocols prevent scope creep
4. **Use Both Tools**: PRP for complex features, PLAN for quick tasks
5. **Keep Plans Active**: Mark completion, archive when done
6. **Be Specific**: The quality of output depends on input clarity

## Command: github-pr-comments

**Purpose**: Fetch and address unresolved review comments on GitHub pull requests.

**Usage**:

```bash
claude code --command github-pr-comments
```

**How it works**:

1. Detects current repository and PR from working directory
2. Fetches all unresolved review threads via GitHub GraphQL API
3. Presents comments for you to address systematically
4. Uses `gh` CLI tool (must be installed and authenticated)

**Required Tools**:

- GitHub CLI (`gh`) installed and authenticated
- Working directory must be in a git repository with an active PR

**Example Workflow**:

1. Navigate to your PR branch
2. Run `claude code --command github-pr-comments`
3. Claude fetches all unresolved comments
4. Address each comment with code changes
5. Mark threads as resolved when complete

## Future Enhancements

- [ ] Plan templates for common task types
- [ ] Automatic plan validation
- [ ] Progress visualization
- [ ] Multi-plan orchestration
- [ ] Plan merging for dependent tasks
- [ ] More GitHub integration commands
- [ ] Custom command templates

---

Remember: The goal is one-pass implementation success through comprehensive
context (PRP) and disciplined execution tracking (PLAN).

# Agent Strategy & Conflict Resolution

## Two Agent Systems - Clear Separation

### 1. Claude-Flow Agents (Generic Tasks)
**When to use:** Generic development tasks, SPARC methodology, swarm coordination
**Access:** Via MCP tools (`mcp__claude-flow__*`)
**Examples:**
- `npx claude-flow sparc tdd` - TDD workflow
- `mcp__claude-flow__swarm_init` - Initialize swarm
- `mcp__claude-flow__agent_spawn` - Spawn generic agents

### 2. Custom Relate Coach Agents (Project-Specific)
**When to use:** Relate Coach specific features and architecture
**Access:** Via Task tool with specific agent markdown files
**Examples:**
- `Task("backend-architect: Design multi-language API")`
- `Task("database-specialist: Optimize PostgreSQL queries")`
- `Task("ai-integration-expert: Improve OpenAI prompts")`

## Decision Tree

```
Is the task Relate Coach specific?
├── YES → Use Custom Agents (/agents/)
│   ├── Multi-language features → ai-integration-expert
│   ├── Database schema → database-specialist
│   ├── React Native UI → react-native-expert
│   └── API design → backend-architect
│
└── NO → Use Claude-Flow Agents
    ├── General coding → coder
    ├── Testing → tester
    ├── Planning → planner
    └── SPARC workflow → sparc-*
```

## Naming Convention to Avoid Conflicts

### Custom Agents (Prefixed with domain):
- `rc-orchestrator` (Relate Coach Orchestrator)
- `rc-backend-architect`
- `rc-typescript-specialist`
- `rc-react-native-expert`
- `rc-database-specialist`
- `rc-ai-integration-expert`
- `rc-code-reviewer`
- `rc-test-engineer`

### Usage Examples

**Generic Task (Claude-Flow):**
```bash
# Use claude-flow for generic TDD
npx claude-flow sparc tdd "user authentication"
```

**Relate Coach Specific (Custom):**
```javascript
// Use custom agents for project-specific work
Task("rc-database-specialist: Design schema for 15-language support")
Task("rc-ai-integration-expert: Optimize personality analysis prompts")
```

## Priority Rules

1. **Project-specific tasks** → Always use Custom Agents
2. **Generic development** → Use Claude-Flow
3. **When in doubt** → Ask user for preference
4. **Never mix** → Don't use both systems for same feature

## Integration Points

Custom agents can invoke Claude-Flow for sub-tasks:
```javascript
// rc-orchestrator can delegate to claude-flow
Task("rc-orchestrator: {
  1. Design API (use rc-backend-architect)
  2. Implement code (delegate to claude-flow coder)
  3. Review (use rc-code-reviewer)
}")
```
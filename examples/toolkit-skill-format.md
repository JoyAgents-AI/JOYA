# Example: Skill Descriptor Format and Adapter Definitions

Implements: `guides/TOOLKIT.md`

How to define skills, configure adapters, and write skills.md files.

---

## Skill Descriptor (skill.json)

Every skill must have a `skill.json` for discoverability and auditability:

```json
{
  "name": "web-search",
  "version": "1.0.0",
  "description": "Search the web and return results",
  "adapters": ["mcp", "openclaw", "scripts"],
  "preferred": "mcp",
  "permissions": ["network"],
  "inputs": [
    { "name": "query", "type": "string", "required": true }
  ],
  "outputs": [
    { "name": "results", "type": "array" }
  ]
}
```

- **`adapters`**: Available implementations. The runtime picks the best match.
- **`preferred`**: Hint for adapter selection.
- **`inputs`/`outputs`**: JSON Schema compatible (aligns with OpenAI function calling and MCP).
- **`permissions`**: Declared capabilities the skill requires.

---

## Supported Adapters

| Adapter | Format | Ecosystem |
|---|---|---|
| `mcp` | MCP server config + tool definitions | Anthropic / Claude / Cursor |
| `openai` | JSON Schema function definitions | OpenAI / GPT |
| `openclaw` | `SKILL.md` (frontmatter + markdown) | OpenClaw |
| `openapi` | OpenAPI 3.x spec | REST APIs |
| `scripts` | Shell/Python scripts | Universal fallback |

New adapters: create a subdirectory with the adapter name.

---

## Creating a Skill

1. Create a directory: `$JOYA_MY/agents/<your-name>/skills/<skill-name>/` (private) or `$JOYA_MY/shared/toolkit/<skill-name>/` (shared).
2. Add `skill.json` with name, description, inputs, outputs, and adapter list.
3. Add at least one adapter implementation (e.g., `scripts/`, `mcp/`, `openclaw/`).
4. Update your `skills.md` to reference the new skill.

## Creating a Script

1. Place the script in `$JOYA_MY/agents/<your-name>/scripts/` (private) or `$JOYA_MY/shared/toolkit/` (shared).
2. Include a comment header explaining purpose and usage.
3. Ensure the script is executable and platform-appropriate.

## Creating an Adapter

1. Create a directory: `$JOYA_MY/shared/toolkit/<adapter-name>/`.
2. Implement the three communication capabilities (point-to-point, broadcast, group discussion).
3. Document configuration requirements in a README.

---

## skills.md Example

```markdown
## Enabled (in addition to shared)
- image-gen

## Disabled
- deploy-production

## Overrides
- web-search: preferred adapter changed to `scripts`
```

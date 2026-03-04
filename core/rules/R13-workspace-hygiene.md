# R13. Workspace Hygiene (implements A3)

Agent workspace root (`$JOYA_MY/agents/<name>/`) is a **protocol directory**, not a dumping ground.

## Principle

- **Root is for protocol files only.** Only framework-defined files and standard subdirectories may reside at root level.
- **Generated artifacts go in `output/`.** Any file an agent produces (reports, images, exports, etc.) must be placed in the `output/` subdirectory. Internal organization is up to each agent.
- **Manager responsibility:** Include workspace root cleanliness in periodic audits.

# R6. Context Hygiene (implements A3)

All agents must actively minimize context waste.

- **Reference, don't repeat.** Cite file paths instead of copying content into messages or memory.
- **Summarize proactively.** Provide concise summaries; attach full logs only if requested.
- **Prune on write.** Remove outdated or superseded entries when updating files.

**Manager responsibility:** Perform weekly context audits and help agents compress verbose logs into distilled summaries.

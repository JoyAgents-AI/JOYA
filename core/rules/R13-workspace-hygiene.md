# R13. Workspace Hygiene (implements A3)

Agent workspace root (`$JOYA_MY/agents/<name>/`) is a **protocol directory**, not a dumping ground.

## Principle

- **Root is for protocol files only.** Only framework-defined files (`*.md` protocol files, `avatar.*`) and standard subdirectories may reside at root level.
- **Generated artifacts go in `output/`.** Any file an agent produces (reports, PDFs, images, exports, etc.) must be placed in `output/` with appropriate subdirectories by type.
- **Temporary files are ephemeral.** Work-in-progress files should use `output/tmp/` and be cleaned up after delivery.

## Standard Layout

```
agents/<name>/
├── *.md                  # Protocol files only (MEMORY, IDENTITY, SOUL, etc.)
├── avatar.*              # Agent avatar
├── output/               # All generated artifacts
│   ├── reports/          # PDFs, HTML reports
│   ├── images/           # Generated images, screenshots
│   ├── tmp/              # Ephemeral work files (auto-clean)
│   └── ...               # Other type-based subdirs as needed
├── scripts/              # Agent scripts/tools
├── memory/               # Memory lifecycle files
├── docs/                 # Agent documentation
├── credentials/          # Auth credentials
├── secrets/              # Encrypted secrets
└── ...                   # Other standard subdirs
```

## Enforcement

- **Manager responsibility:** Include workspace root cleanliness in weekly context audits.
- **Violation:** Stray artifacts at root level should be moved to `output/` during the next audit pass.

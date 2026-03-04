# Changelog

All notable changes to the JOYA framework will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/). This project uses [Semantic Versioning](https://semver.org/).

---

## [1.2.0] — 2026-03-05

### Added
- **Level B Fast Path** (`AGENT_INIT.md`) — OpenClaw agents with cached exam results skip EXAM_RECORDS lookup entirely. Two-condition gate: Level B platform + `exam: PASS` in MEMORY.md.
- **`AGENT_INIT_SETUP.md`** — First-time setup (new agent / fresh instance) split out from AGENT_INIT.md. Returning agents no longer load setup logic.
- **`ENGINEERING_WORKFLOW.md`** — Engineering principles guide (TDD, design-first, systematic debugging, verification gates, trinity rule). Cross-referenced from `ENGINEERING.md`.
- **Onboarding exam Category E** — Stress-test questions for engineering workflow compliance.
- **R13: Workspace Hygiene** — Agent root contains only protocol files; artifacts go to `output/`.
- **Three-tier rule loading** (`shared/rules/README.md`) — Rules tagged `[必読]` (8 files, every session), `[按需]` (19 files, scenario-triggered), `[項目専属]` (4 files, project-scoped).
- **Memory lifecycle pointer** — `MEMORY_LIFECYCLE.md` now references `MEMORY_MAINTENANCE.md` operations SOP.

### Changed
- **`TIERED.md` → `TIERED_FULL.md`** — Retained as full reference for Standard Path; Fast Path agents use inline scan table in AGENT_INIT.md.
- **Setup file rename** — `JOYA_SETUP.md` → `SETUP_INSTANCE.md`, `AGENT_SETUP.md` → `SETUP_AGENT.md`. `AGENT_INIT_SETUP.md` deleted and merged into `AGENT_INIT.md` §First-Time Setup & Exam. Convention: `SETUP_*` = one-time, `AGENT_INIT` = every session.
- **`infra/ESSENTIALS.md`** — Moved from Tier 2 (every session) to Tier 3 (on-demand) with 7-day checkpoint in MEMORY.md.
- **Tier 2 scan table** — All file references now include full path prefixes (`$JOYA_LIB/core/`, `$JOYA_MY/shared/core/`, etc.).
- **`COMPACTION_RESILIENCE.md`** — PREFERENCES.md re-load now conditional ("if it exists").
- **`DIRECTORY.md`** — Per-agent directory lists `scripts/` instead of `toolkit/`.
- **Starter template** — `shared/config/` renamed to `shared/core/` to match production layout. Empty `RELATIONSHIPS.md` stub removed.

### Fixed
- Toolkit scripts (`agent-send`, `mm-agent-listener*.py`, `joy-adapter-openclaw.ps1`) — `instance/agents/` → `my/shared/agents/` path migration.
- `messaging/README.md` — Corrected double-path `$JOY_ROOT/$JOYA_MY` reference.
- `FULL.md`, `AGENT_INIT_SETUP.md` — Updated `TIERED.md` → `TIERED_FULL.md` references.
- `README.md` — Fixed Rex/Bob model labels (GPT → Claude).

## [1.1.0] — 2026-02-26

### Added
- **Platform Adaptation spec** (`core/arch/PLATFORM_ADAPTATION.md`) — Runtime capability levels (A/B/C), loading manifest (`MANIFEST.yaml`), bridge file standard, and compaction × adaptation matrix. Enables JOYA to work reliably on static-injection runtimes like OpenClaw, Cursor, and Windsurf.
- **Compaction Resilience Layer 2.5** — Runtime-aware foundation reload after compaction. Agents now verify base identity and preferences before resuming work, with 4 runtime-agnostic detection signals.
- **Loading chain optimization** (L1–L6) — Reduced per-session token cost by ~3000 tokens through platform injection detection and skip-if-injected logic.
- **Instance-level exam records** — Onboarding exam results are now shared across all agents using the same model+thinking combo, eliminating redundant exams.
- **Thinking upward compatibility** — A PASS at a lower thinking level (e.g., `low`) now covers all higher levels, reducing unnecessary re-examination.
- **External platform safety principles** (`shared/rules/EXTERNAL_PLATFORM_SAFETY.md`) — 22 rules for safe interaction with external platforms (JOYA-4).
- **Framework change governance** — Multi-agent cross-LLM review recommended for core design changes.
- **English-only rule for LIB** — All framework content in `$JOYA_LIB/` must be in English (ENGINEERING.md §7).
- **DUTIES.md trigger** added to Tier 3 loading table.

### Changed
- `AGENT_INIT.md` — Added Step 0 (runtime capability detection) before the session start decision tree.
- `COMPACTION_RESILIENCE.md` — Compaction detection signals updated to be runtime-agnostic (not Claude-specific).
- `ARCHITECTURE.md` — Index updated with `PLATFORM_ADAPTATION.md` entry.
- `TIERED.md` — Added platform injection detection section and `on_reference` keyword matching.

### Fixed
- Bridge/pointer files in workspace context are now documented as an anti-pattern with clear alternatives.

---

## [1.0.0] — 2026-02-21

Initial public release.

### Core
- Multi-agent governance: Principal / Manager / Worker role hierarchy
- 12 operating rules (reporting, security, version control, etc.)
- Tiered loading system (Tier 1 must-load / Tier 2 scan / Tier 3 on-demand)
- Onboarding exam for model qualification
- Memory lifecycle: Hot → Warm → Cold three-tier decay
- Compaction resilience: Write-Through + SESSION.md WAL + post-compaction self-check

### Architecture
- Portable agent identity and memory (`$JOYA_MY/agents/<name>/`)
- Framework/instance separation (`$JOYA_LIB/` vs `$JOYA_MY/`)
- Multi-machine deployment: Git for lib, Syncthing for instance data
- Shared governance with CHANGELOG audit
- Context optimization: 7 principles (Write Less, Load On Demand, Index-First, etc.)

### Guides
- Messaging setup, deployment, lifecycle, toolkit, knowledge management
- Project management with handoff protocol
- Engineering practices (Git workflow, etc.)

[1.1.0]: https://github.com/JoyAgents-AI/JOYA/compare/v1.0.0...main
[1.0.0]: https://github.com/JoyAgents-AI/JOYA/releases/tag/v1.0.0

# Changelog

All notable changes to the JOYA protocol.

Format: `YYYY-MM-DD — description`

---

## v1.2.0 — 2026-02-19

#### Structure
- **Directory restructure**: `core/` → `core/`, `guides/` → `guides/`, `examples/` → `examples/` (top-level)
- `$JOYA_LIB/` now contains only mandatory governance documents; guides and examples are independent subdirectories under lib/
- `toolkit/selfcheck.sh` moved to `toolkit/scripts/`

#### Core
- ARCHITECTURE.md §1: Added Design Philosophy with precedence chain (`Protocol > Guides > Instance Rules > Agent Config`) and Instance Customization Model
- ARCHITECTURE.md §2: Updated directory map to reflect new structure
- ARCHITECTURE.md §5: Completed Worker column in permission matrix (was missing)

#### Fixes
- Removed stale rule references (R17, R18) from LIFECYCLE.md and DEPLOYMENT.md
- Fixed `project-management.md` instance rule referencing non-existent `PROJECTS.md`
- Fixed `ONBOARDING_AUTO.md` referencing old DIRECTORY.json field for bot tokens
- MESSAGING.md Addressing Rule: scope and Listen mode clarification
- CHANGELOG: documented Advisor role removal

---

## v1.1.0 — 2026-02-18

#### Core
- RULES.md: 18→12 rules. Merged pointer-only rules (R5/R9/R16), trimmed R7 Context Hygiene, moved operational details to guides
- ARCHITECTURE.md: 565→166 lines. Converted to overview map, moved Skills system to TOOLKIT.md, replaced directory details with README pointers. Removed Advisor role; permission model simplified to Manager + Worker with extension mechanism
- MESSAGING.md additions: check-before-send anti-loop rule, no-reply-to-ack rule, Principal @specific-agent silence rule, Manager conflict authority

#### Structure
- $JOYA_MY/ restructured: agents/ (private) + shared/ (team)
- shared/{scripts,skills,adapters} merged into shared/toolkit/
- shared/dropzone/ added as agent exchange area
- shared/workspaces/ removed (redundant with agents/)
- README.md added to every instance directory

#### Guides
- HANDOFF.md + ITERATIONS.md merged into PROJECT_MANAGEMENT.md
- PERSISTENCE.md: 195→45 lines
- ENGINEERING.md: compressed to principles + ADR decision records added
- UNINSTALL.md: 103→73 lines
- DEPLOYMENT.md: added onmessage troubleshooting guide

#### i18n
- All protocol and instance docs translated to English (authoritative language)
- joy-translate.sh tool for on-demand localization
- i18n-zhCN/ generated with post-commit auto-translation hook
- README_CN.md removed (replaced by i18n system)

#### Security
- INFRASTRUCTURE.md: credentials sanitized, tokens moved to agent-specific SECRETS.md

---

## v1.0.0 — 2026-02-17

Initial release.

### Core
- **AXIOMS.md**: A0 Principal Authority, A1 Transparency, A2 Acknowledge-before-Act, A3 Context Economy
- **RULES.md**: R1–R12 covering protocol precedence, reporting, accountability, communication, protocol changes, version control, meetings, directory responsibility, override constraints, context hygiene, manager requirement, admin operations, availability, security
- **ARCHITECTURE.md**: Directory structure ($JOYA_LIB/ + toolkit/ + $JOYA_MY/), three roles (Manager/Worker/Advisor), permission matrix, fine-grained permissions, communication interface, synchronization, agent identity & memory portability, skills system with three-layer resolution, instance customization
- **ACCOUNTABILITY.md**: Scoring system V1 with deductions and bonuses aligned to all rules and axioms

### Guides
- **MEETINGS.md**: Structured meeting workflow with proposals, reviews, and summaries
- **MESSAGING.md**: Communication adapter selection guide
- **ENGINEERING.md**: Engineering practices (Git, branching, PR, code review)
- **LIFECYCLE.md**: Agent onboarding, offboarding, migration, model swap, revival
- **TOOLKIT.md**: Tool discovery, creation, sharing, and override patterns

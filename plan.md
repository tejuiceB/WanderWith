# WanderWith Implementation Plan (Master)

## 0) Goals
- Deliver a clear, end-to-end execution plan for this repo.
- Provide developer + product overview documentation.
- Create a GitHub issues backlog aligned to this plan.

## 1) Scope
### In scope
- Documentation: full README update with developer + product overview.
- Planning: a new master plan (this file) with phases, tasks, risks, acceptance criteria, and QA.
- Issues: create a GitHub issues backlog (epics + tasks + bugs + docs).
- Repository hygiene: identify unused or redundant files and propose a cleanup list.

### Out of scope (unless you approve)
- Deleting files without explicit approval.
- Changing production Supabase data.
- Large refactors not tied to the plan.

## 2) Assumptions
- Flutter 3.19+ and Dart 3.1+ are used as per current dependency range.
- Supabase is the backend (Auth, Postgres, Storage, Realtime).
- Offline caching uses Isar with a local cache and queue.
- AI features are powered by Gemini via API key stored in env config.

## 3) Milestones
### M1 - Docs and Planning (1-2 days)
- Create this plan.md and update README.
- Produce a GitHub issues backlog.

### M2 - Repo Hygiene and Security (1-2 days)
- Identify unused or redundant files.
- Propose cleanup list with risks.
- Flag secret exposure risks.

### M3 - Quality and Stability (3-7 days)
- Address high-priority bugs and tech debt.
- Improve offline sync reliability.
- Resolve notification flow gaps.

### M4 - Product Enhancements (Optional)
- Implement new features based on roadmap priorities.

## 4) Workstreams and Tasks

### A) Documentation Workstream
**Goal:** Provide complete developer + product overview documentation.

Tasks:
1. README overhaul
   - Product overview: value proposition and key capabilities.
   - Developer overview: architecture and data flow.
   - Full local setup with env config.
   - Supabase setup and SQL instructions.
   - Build and release steps for Android/iOS/Web.
   - Troubleshooting and FAQ.
2. Screenshots + Recording
   - Add README section with placeholders.
   - Provide capture guide for user-generated assets.

Acceptance criteria:
- README contains setup steps, env keys, architecture, and troubleshooting.
- README contains screenshot/recording section with instructions.

### B) Planning and Issue Backlog
**Goal:** Translate plan into actionable GitHub issues.

Tasks:
1. Create epics:
   - Documentation
   - Repo Hygiene
   - Security
   - Offline/Sync
   - Notifications
   - AI/Gemini
   - Trip Planning
   - Social Feed
   - QA/Testing
2. Create detailed tasks under each epic.
3. Prioritize issues (P0/P1/P2).

Acceptance criteria:
- Each epic has clear scope and task issues.
- Issues reference file paths and expected behavior.

### C) Repo Hygiene and Cleanup (Proposal only until approved)
**Goal:** Remove or archive unused files safely.

Tasks:
1. Inventory and classify files (generated, legacy, docs, SQL migrations).
2. Identify unused or duplicate assets (e.g., old plans, redundant SQL scripts).
3. Produce cleanup proposal with risk rating.

Acceptance criteria:
- Cleanup list includes reason and risk level per file.
- No deletions happen without your approval.

### D) Security and Secrets
**Goal:** Ensure secrets are not committed.

Tasks:
1. Scan for committed secret files and tokens.
2. Add gitignore rules or move files if needed.
3. Document secret handling in README.

Acceptance criteria:
- Secrets are not present in repository history.
- README has clear secret-handling guidance.

### E) Core Stability
**Goal:** Stabilize critical flows.

Key focus areas:
- Auth and deep links
- Offline sync reliability
- Notification delivery and routing
- Trip creation/join flows

Acceptance criteria:
- No crash on offline or login edge cases.
- Notifications route correctly to screens.

## 5) QA and Testing
- Unit tests: core services and parsing logic.
- Widget tests: key screens (login, trip dashboard, plan tab).
- Manual regression checklist:
  - Auth (email + Google)
  - Trip create/join
  - Chat send/receive + offline
  - Plan generation + maps
  - Notifications
  - Profile edit

## 6) Risks and Mitigations
- Risk: removing SQL files that are still needed for setup.
  - Mitigation: keep a single production schema file, archive legacy.
- Risk: deleting build artifacts that are referenced by scripts.
  - Mitigation: confirm build output references before cleanup.
- Risk: secrets committed in repo.
  - Mitigation: rotate keys and remove from repo.

## 7) Deliverables
- New plan.md (this file).
- Updated README.md.
- GitHub issues backlog.
- Cleanup proposal list.

## 8) Open Questions
- Which GitHub repo should be used for issue creation?
- Do you want issues grouped by milestones or sprints?
- Do you want markdown templates for issues and PRs?
- Who will capture screenshots and recording (I cannot capture UI media directly)?

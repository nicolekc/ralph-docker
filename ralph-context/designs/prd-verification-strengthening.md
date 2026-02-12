# PRD Verification Strengthening Proposal

Proposed improvements to verification criteria across PRDs 001-004. Each entry shows the current verification, proposed verification, and a brief rationale.

**Pattern applied:** Who does what / What happens / How you observe it.

**Constraint honored:** Proposals aim for clear verifiability without becoming implementation recipes (P3). Investigation tasks acknowledge subjective outcomes and propose the best achievable verification for non-code deliverables.

---

## PRD 001: Foundation

### Task 001 — Testability Foundations

**Current:**
> At least one automated check exists for each key mechanism. The approach is documented so future tasks know how to add tests.

**Proposed:**
1. A developer runs a single command (script or test suite) and gets pass/fail output for at least one check per key mechanism: orchestrator dispatch, role prompt behavior, build cycle flow, self-installation correctness.
2. Each check's expected vs actual behavior is visible in the output (not just a silent pass).
3. A new developer can read the approach doc and add a new test for a hypothetical fifth mechanism without asking questions — the doc includes at least one worked example showing the pattern to follow.
4. At least one check exercises a failure mode (e.g., circuit breaker trigger, malformed input), not just the happy path.

**What changed:** The original says "at least one automated check exists" — an existence check on a test. The proposal specifies that the checks must be runnable, produce visible output, cover at least one failure mode, and that the documentation is self-sufficient (observable via a "can someone follow it" test, not just "does the file exist").

---

### Task 002 — Install Script Update

**Current:**
> Install into a temp directory. Verify all expected files exist. Verify .ralph/ matches framework/ contents. Verify the self-install case works.

**Proposed:**
1. Run `install.sh <temp-dir>` on an empty directory. Every file in `framework/` has a corresponding file in `<temp-dir>/.ralph/` with identical content (`diff -r` returns no differences).
2. `<temp-dir>/ralph-context/` and `<temp-dir>/.ralph-tasks/` directories exist and contain the expected bare structure (at minimum, the subdirectories seeded by the framework).
3. `.claude/skills/` are present in the target and contain the skill files (ralph, discover, refine).
4. Run `install.sh` on the ralph-docker repo itself (the self-install case). `.ralph/` is updated from `framework/` without creating circular copies (no `framework/` inside `.ralph/`, no `.ralph/` inside `.ralph/`). A `diff -r framework/ .ralph/` after self-install shows no differences.
5. Run install on a directory that already has a `.ralph/` from a prior install. Existing project-specific files in `ralph-context/` are preserved (not overwritten or deleted).

**What changed:** The original is close but relies on "expected files exist" and "matches" without specifying how to observe the match. The proposal makes the verification mechanical (`diff -r`), adds the re-install preservation case (a failure mode the original misses), and specifies what "bare structure" means for the created directories.

---

### Task 003 — Legacy Cleanup

**Current:**
> Root templates/ directory removed (or emptied to .gitkeep if convention requires it). .claude/skills/refine/ updated to reference current PRD format. No file references old-style paths (RALPH_PROMPT.md, testsPassing, etc.).

**Proposed:**
1. `ls templates/` at repo root returns nothing or only `.gitkeep`.
2. `grep -r "RALPH_PROMPT.md\|testsPassing\|numeric task IDs" .claude/skills/refine/` returns no matches. The refine skill references the current PRD JSON format (field names match those in an actual PRD file).
3. `grep -r "RALPH_PROMPT.md\|testsPassing\|templates/" --include="*.md" --include="*.sh" --include="*.json" .` (repo-wide) returns no matches for dead references, excluding this document and git history.
4. Any content from the old `templates/` directory that was worth preserving is identifiable in its new location (the commit message or a migration note in the PR says where it went).

**What changed:** The original is already fairly strong. The proposal adds the repo-wide dead reference scan (criterion 3) — the original only checks `skills/refine/` but stale references could be anywhere. Also adds the "where did preserved content go" observability (criterion 4) so a reviewer can verify content wasn't silently dropped.

---

## PRD 002: Core Loop

### Task 001 — End-to-End /ralph Test

**Current:**
> Successfully complete at least one task from a test PRD using /ralph. Also trigger a circuit breaker and a signoff gate to verify they work.

**Proposed:**
1. Invoke `/ralph` on a test PRD containing at least 2 tasks. At least one task completes through the full architect/implementer/reviewer cycle, producing a commit with actual code or file changes (not just task state updates).
2. `.ralph-tasks/` is populated with per-task directories containing progress artifacts (progress.txt or equivalent) that show timestamped entries from each role.
3. The circuit breaker is triggered by a task designed to fail review repeatedly. After 3 rejections, the system escalates (to architect or human) rather than looping. Observable in the progress log or task state.
4. A signoff gate (e.g., "architecture" signoff) stops execution after the architect phase. Observable: the task's state shows architect output exists but no implementer was dispatched.
5. Task state in the PRD JSON (or equivalent state file) reflects completion/failure accurately after the run.

**What changed:** The original says "successfully complete" and "trigger a circuit breaker" but doesn't say how you observe success or how you observe the circuit breaker fired. The proposal specifies what artifacts to look at (commits, progress logs, task state) and what "circuit breaker works" looks like observably (escalation after 3 rejections, visible in logs). Also requires the test PRD to have 2+ tasks to exercise dispatch, not just single-task execution.

---

### Task 002 — Spec Review Gate & Progress.txt

**Current:**
> Spec review produces actionable feedback on at least one task. Progress.txt contains coherent per-role entries from a completed build cycle.

**Proposed:**
1. Run spec review on the test PRD. The spec reviewer identifies at least one vague or weak criterion (the test PRD should include an intentionally vague criterion as a control). The reviewer's output names the specific criterion and states what's wrong with it.
2. The spec review output is structured enough that an implementer could act on it without asking clarifying questions — it says what to change, not just "this is vague."
3. After a completed build cycle, `progress.txt` (or equivalent) contains entries attributable to each role that participated (architect, implementer, reviewer). Each entry has a timestamp or ordering and describes what that role did or decided.
4. A person reading `progress.txt` can reconstruct the sequence of events in the build cycle without access to any other artifact.

**What changed:** The original says "actionable feedback" and "coherent entries" — both subjective without a standard. The proposal defines "actionable" (names the problem, states what to change) and "coherent" (a reader can reconstruct the sequence). The intentionally-vague-criterion control is already in the task description but wasn't in the verification.

---

### Task 003 — Branch/Push Hygiene

**Current:**
> Run /ralph and verify it creates a properly named branch, makes clean commits, and pushes successfully.

**Proposed:**
1. Run `/ralph` on a test PRD. A new branch is created whose name follows the documented convention (verify against the convention doc produced by this task). The branch name is predictable from the PRD name/ID.
2. Commits on the branch are attributable to specific tasks (commit messages reference the task or PRD). No commits contain unrelated changes.
3. `git push` succeeds and the remote branch exists with the expected commits.
4. Run `/ralph` again on a different PRD while the first branch exists. The second execution creates a separate branch. No cross-contamination of commits between the two branches.
5. The branch naming convention is documented in a location discoverable by `/ralph` (e.g., in `ralph.md` or a process file).

**What changed:** The original says "properly named" without a reference standard, and "clean commits" without defining clean. The proposal ties branch naming to the convention doc this task produces, defines clean (attributable, no unrelated changes), and adds the concurrent execution case (a key failure mode given the task description mentions multiple PRDs).

---

## PRD 003: Investigations

All PRD 003 tasks are non-code deliverables. Verification of investigation quality is inherently subjective — you cannot write a `diff` assertion against "good recommendations." The approach here: specify what the document must cover (completeness), what structure it must have (navigability), and what a reviewer can check mechanically, while acknowledging that quality judgment remains human.

### Task 001 — AGENTS.md Pattern

**Current:**
> Document exists, covers the noise-vs-knowledge tradeoff, includes a concrete recommendation.

**Proposed:**
1. Document exists in `ralph-context/designs/`.
2. The document has a section (or equivalent) addressing each of: (a) what triggers an AGENTS.md write, (b) what content belongs vs what is noise, (c) how to prevent staleness.
3. It includes a concrete recommendation (not just analysis) — stated as "do X" or "adopt pattern Y," not "consider several options."
4. The recommendation is grounded in at least one example (real or constructed) showing the difference between a useful and a noisy AGENTS.md entry.
5. A reviewer can assess: does this recommendation, if followed, actually reduce noise while preserving knowledge? (Subjective but scoped.)

**What changed:** The original is a bare existence check plus two vague requirements. The proposal ensures the three sub-questions from the task description are each covered (completeness), requires the recommendation to be concrete (not just "consider"), and asks for a grounding example so the reviewer has something tangible to evaluate.

---

### Task 002 — Principle Adherence Hardening

**Current:**
> Document exists with actionable recommendations. At least one is implementable in a subsequent task.

**Proposed:**
1. Document exists in `ralph-context/designs/`.
2. Contains at least 3 distinct recommendations (not variations on the same idea).
3. Each recommendation states: what it addresses (which adherence risk), how it works, and where in the framework it would integrate.
4. At least one recommendation is concrete enough to become a task description in a follow-up PRD without further investigation.
5. The document addresses the tension between ensuring adherence and avoiding prescriptiveness (the meta-problem — hardening adherence without becoming the thing it's guarding against).

**What changed:** The original says "actionable" without a standard and "at least one implementable" which is a low bar. The proposal requires multiple recommendations (breadth), specifies what "actionable" means (what/how/where), and asks for engagement with the core tension — which is the hard part of this investigation.

---

### Task 003 — Human Inbox Mechanism

**Current:**
> Document exists with a recommended approach. Simple enough to implement in one follow-up task.

**Proposed:**
1. Document exists in `ralph-context/designs/`.
2. Describes the problem (how humans currently miss non-code deliverables) with at least one concrete scenario.
3. Recommends a specific approach — not a menu of options without a pick.
4. The recommended approach specifies: where the inbox artifact lives on the filesystem, what information it contains, how it gets populated (who writes to it and when), and how a human discovers it.
5. A developer reading the design could write the implementation task in under 15 minutes (the "one follow-up task" test, made observable).
6. Does not require changes to more than 2 existing framework files (the simplicity constraint, made measurable).

**What changed:** "Simple enough to implement in one follow-up task" is an intent statement, not a verifiable criterion. The proposal operationalizes simplicity (limited file changes, implementation task writeable quickly) and requires the design to specify the key moving parts (where, what, how, who) rather than just "a recommended approach."

---

### Task 004 — Parallelization Principles

**Current:**
> Document exists with actionable guidelines. Covers at least: file conflict detection, shared resource handling, and when NOT to parallelize.

**Proposed:**
1. Document exists in `ralph-context/designs/`.
2. Has a section for each required topic: file conflict detection, shared resource handling, and when NOT to parallelize.
3. Each guideline is stated as a rule with a rationale — "Parallelize when X because Y; don't when Z because W" — not just "be careful."
4. Includes at least one concrete scenario per guideline illustrating the failure mode it prevents.
5. If PRD 002 experience is available, references at least one real observation from that execution. If not, states the gap explicitly.

**What changed:** The original's "covers at least" checklist is already decent for topic coverage. The proposal strengthens the depth requirement — each topic needs a rule-with-rationale and a failure scenario, not just mention. This is the difference between "we covered parallelization" and "a developer could follow these guidelines."

---

### Task 005 — Not-Ready Task Representation

**Current:**
> Document exists with at least 3 options considered and a clear recommendation with tradeoffs.

**Proposed:**
1. Document exists in `ralph-context/designs/`.
2. Presents at least 3 distinct options (not minor variations). Each option includes: how it works, what it costs (complexity, new conventions, breaking changes), and what it doesn't handle.
3. The recommendation is clearly stated and defended — a reviewer can disagree with the reasoning but not with the clarity of the argument.
4. Evaluates each option against the three stated criteria from the task description: (a) signals "not ready" clearly, (b) doesn't add unnecessary machinery, (c) is human-inspectable.
5. Addresses migration: what happens to existing `draft` status tasks under the recommended approach?

**What changed:** The original is already structured (3 options + recommendation). The proposal adds the evaluation matrix (each option against the three criteria from the description) so the reviewer can see the comparison is systematic, and adds the migration question which any recommendation must address to be actionable.

---

### Task 006 — Human-Blocking and Task Parking

**Current:**
> Document exists in ralph-context/designs/. Covers: artifact format, filesystem location convention, how ralph knows to skip parked tasks, how a web companion discovers pending questions, how work resumes after human responds. Design is loosely-coupled.

**Proposed:**
1. Document exists in `ralph-context/designs/`.
2. Each of the five required topics has an explicit section: artifact format, filesystem location, ralph skip behavior, web companion discovery, resume flow.
3. The artifact format section includes a concrete example (a sample artifact for a realistic blocking scenario).
4. "Loosely-coupled" is demonstrated, not just claimed — the document shows how the web companion can discover and display blocking artifacts using only filesystem conventions (no ralph-specific API, no shared database, no IPC).
5. The resume flow addresses: what happens if the human's response invalidates work the agent did before parking? (A failure mode the task description doesn't mention but the design must handle.)

**What changed:** The original's verification is already the strongest in PRD 003 — it lists specific topics to cover. The proposal adds: a concrete artifact example (so the reviewer can evaluate the format against a real scenario), an observable test for "loosely-coupled" (companion works with filesystem only), and the post-resume invalidation failure mode.

---

### Task 007 — Preserving Architectural Intent

**Current:**
> Document exists. Audits existing framework files for where this is already addressed (or missed). Proposes at least one concrete integration point. Avoids creating a rigid template.

**Proposed:**
1. Document exists in `ralph-context/designs/`.
2. Contains an audit section listing at least 5 framework files examined, with a finding for each: does it address intent preservation, partially, or not at all?
3. Proposes at least one concrete integration point — a specific file and a specific addition/change, stated precisely enough to implement.
4. The proposed integration does not introduce a new required field, mandatory template, or rigid format (the "avoids rigid template" constraint, made specific).
5. Includes at least one example of architectural intent being lost (real from Promptly experience or constructed) to ground the problem.

**What changed:** "Audits existing framework files" doesn't say how many or how the audit is observable. The proposal requires the audit to be visible (listed files with findings), makes the "no rigid template" constraint testable (no new required fields), and asks for a grounding example so the problem isn't abstract.

---

### Task 008 — Naming and Organization Audit

**Current:**
> Document exists. Covers every directory in the framework root. Questions the current nesting (not just names). Each proposed scheme is internally consistent. Flags breaking changes honestly. Includes a recommendation.

**Proposed:**
1. Document exists in `ralph-context/designs/`.
2. Contains a directory inventory listing every directory in the framework root with its current purpose.
3. Presents 2-3 coherent schemes. "Coherent" means: within each scheme, all directories follow a consistent naming and nesting logic. A reviewer can check this by looking for naming/nesting exceptions within a scheme.
4. Each scheme includes a migration impact section: which changes are breaking (require code/script changes), which are cosmetic (rename only), and which affect external users vs only this repo.
5. Addresses the dotfile question (`.ralph` vs `ralph-context` vs alternatives) with rationale.
6. The recommendation is stated with a primary reason, not just "we recommend X."
7. At least one scheme proposes a structural change (not just renaming) to validate that nesting was actually questioned.

**What changed:** The original is already one of the stronger verifications. The proposal adds: the explicit directory inventory (so "covers every directory" is observable), the distinction between breaking/cosmetic changes (makes "flags honestly" checkable), and requires at least one structural proposal to ensure the investigation didn't just rename things.

---

## PRD 004: Framework Evolution

### Task 001 — Knowledge Integration Proposal

**Current:**
> Document exists in ralph-context/designs/. Covers all knowledge sources (design-philosophy, frameworks-research, success-criteria-format, problem-statement-structure, PRD_REFINE.md). Each recommendation includes where and why.

**Proposed:**
1. Document exists in `ralph-context/designs/`.
2. Contains a row or section for each of the five named knowledge sources: design-philosophy, frameworks-research, success-criteria-format, problem-statement-structure, PRD_REFINE.md.
3. For each source: states what content to extract (specific sections or concepts, not "the whole file"), which framework file(s) it should go into (specific path), and whether it should move (out of project context) or copy (stays in project context too).
4. Includes a rationale for each recommendation that references the framework/project boundary: why does this belong in the framework (generalizable) vs project context (specific to this repo)?
5. If any knowledge source should be split (parts to framework, parts stay), the split is described at the section level.

**What changed:** The original says "covers all knowledge sources" and "where and why" which is decent. The proposal strengthens "covers" to mean a visible entry per source, and strengthens "where" to mean specific file paths with the extract/move/copy distinction. The split case (criterion 5) addresses a likely reality the original ignores.

---

### Task 002 — 6 Standalone Design Docs

**Current:**
> Each under 2 pages. Each references at least one principle. No doc requires another to make sense.

**Proposed:**
1. Six documents exist, one for each system: Seed, Knowledge Convention, PRD Format, State System, Role Definitions, Orchestrator Pattern.
2. Each is under 2 pages (approximately 1000 words or less).
3. Each references at least one design principle by number (P1-P11) with an explanation of how it applies — not just a citation.
4. A reviewer reads any single doc without reading the others and can answer: what is this system, why does it exist, and how would I use it? If the answer to any of these requires reading another doc, the verification fails.
5. Each doc covers: what the system is, what problem it solves, which principles govern it, and how it composes with (but does not require) other systems.

**What changed:** The original is structurally sound but "references at least one principle" could be satisfied by a throwaway mention. The proposal requires the reference to explain the connection. Also explicitly requires the four content areas (what/why/principles/composition) so "self-contained" is observable, not just asserted.

---

### Task 003 — Additional Role Prompts

**Current:**
> Concise (~1 page), follow P2/P8, work standalone, don't duplicate existing roles.

**Proposed:**
1. 1-2 new role prompts exist in `framework/roles/` (or equivalent location).
2. Each is under 1 page (~500 words).
3. Each role prompt can be read and understood without reading any other role prompt — its purpose, when to use it, and what it produces are clear from the file alone.
4. No new role substantially overlaps with architect, implementer, or reviewer. A reviewer can state what the new role does that no existing role does.
5. Each role prompt states principles, not prescriptions (P2) — it describes what the role cares about and what good output looks like, not step-by-step procedures.
6. If the principle adherence investigation (003/002) produced relevant findings, the role prompt incorporates at least one.

**What changed:** The original's criteria are all judgment calls (concise, standalone, no duplication) without observability. The proposal specifies what "standalone" means (purpose/trigger/output clear from file alone), what "no duplication" means (reviewer can articulate the delta), and what "follows P2" means (principles not procedures). Also ties back to the dependency on 003/002.

---

### Task 004 — Docker Multi-Repo

**Current:**
> Start container with two project directories. Both accessible, git works in each.

**Proposed:**
1. Run `ralph-start.sh` with two project directory arguments (or the equivalent multi-repo invocation). The container starts without errors.
2. Inside the container, both project directories are accessible at their expected mount points. Files can be read and written in each.
3. `git status` in each project directory shows the correct repo (not the other one, not the ralph-docker repo). `git log` shows each project's own history.
4. The ralph framework is available to both projects (`.ralph/` exists or is accessible in each project context).
5. README documents: how to start with multiple repos, what the mount conventions are, and any limitations (e.g., max repos, performance).

**What changed:** The original is a reasonable integration test but misses the framework availability question (can both projects actually use ralph, or just have filesystem access?) and doesn't verify the README documentation requirement from the outcome.

---

### Task 005 — Two-Mode Operation

**Skipped** (status: draft).

---

### Task 006 — Framework README

**Current:**
> README exists. Describes all six primitives in plain language. Includes at least 2 partial adoption paths. Does not require reading any other document to make sense. Under 3 pages.

**Proposed:**
1. README exists at the framework root (or the location determined by the naming audit).
2. Each of the six primitives (Seed, Knowledge Convention, PRD Format, State System, Role Definitions, Orchestrator Pattern) has a section. Each section answers "what is it" and "why would I want it" in plain language — no jargon a new developer would need to look up.
3. At least 2 partial adoption paths are described: specific combinations of primitives that work together without the rest. Each path names which primitives are included and which are not.
4. A developer who has never seen the repo reads only the README and can answer: (a) what problem does this framework solve, (b) what are the main pieces, (c) how do I start using part of it? If any answer requires reading another file, the verification fails.
5. Under 3 pages (~1500 words).
6. Does not read as API documentation or a specification — it reads as an introduction.

**What changed:** The original is already one of the better verifications. The proposal sharpens "plain language" (no jargon requiring lookup), "partial adoption" (must name included/excluded primitives), and adds the tone constraint (introduction, not spec) which matters for a README.

---

### Task 007 — Install/Onboarding Process

**Current:**
> Run the install on a fresh directory. Framework structure is created correctly. Output explains what was created and what to do next. Partial install option exists.

**Proposed:**
1. Run the install command on a fresh, empty directory. The command exits successfully.
2. The directory contains the expected framework structure (verifiable against the structure doc or a reference listing).
3. The install output (stdout) includes: a list of what was created, and at least one "what to do next" instruction (e.g., "edit your CLAUDE.md" or "run /ralph on a PRD").
4. Run the install with a partial option (e.g., "just roles" or "just PRD format"). Only the requested subset is installed. No extra files from other primitives are created.
5. Run the install on a directory that already has some framework files. Existing project-specific files are not overwritten. The output indicates what was updated vs preserved.
6. The install command itself is documented (where to find it, how to run it, what options exist) in the README or a discoverable location.

**What changed:** The original says "correctly" and "partial install option exists" without observability. The proposal specifies what "correctly" means (matches a reference), what the partial install must demonstrate (subset only, no extras), and adds the re-install case (existing files preserved). Also requires the install itself to be documented — otherwise the "new user" in the outcome can't find it.

---

### Task 008 — WHY.md / Blog Post

**Current:**
> Draft exists. Tells a narrative (not just lists features). Addresses the 'doesn't Claude Code already do this?' objection directly. References real experience, not hypotheticals. Under 10 pages. Could be read by a non-engineer PM and make sense.

**Proposed:**
1. Draft exists at the expected location.
2. Has a narrative arc — a beginning (the problem/pain), middle (what was tried, what failed, what was learned), and end (the vision). A reviewer can identify these three sections.
3. Directly addresses the "doesn't Claude Code already do this?" objection — not by ignoring it, but by engaging with it (acknowledging what CC does well and articulating the gap).
4. References at least 2 specific real experiences (from the 160+ Promptly tasks, the framework analysis, etc.) — not "we found that" generalities but "when we tried X, Y happened."
5. Under 10 pages (~5000 words).
6. A non-engineer PM could read it and explain to someone else what the framework does and why it exists. (Subjective, but scoped — the test is "could explain to someone else," not just "could read it.")
7. Includes the competitive positioning (vs OMC, Superpowers, Gas Town) in a way that's fair — states what they do well, not just what they do wrong.

**What changed:** The original is already quite strong for a subjective deliverable. The proposal sharpens "narrative" (arc with identifiable sections), "real experience" (at least 2 specific instances), and adds the fairness requirement for competitive positioning (which was in the task description but not the verification).

---

## Summary of Material Changes

Tasks with the most significant verification strengthening (beyond editorial cleanup):

| Task | Key weakness addressed |
|------|----------------------|
| **001/001** (Testability) | "Exists" changed to runnable + visible output + failure mode coverage + self-sufficient docs |
| **002/001** (E2E /ralph) | "Successfully complete" changed to observable artifacts, specific circuit breaker behavior, and dispatch verification |
| **002/002** (Spec Review) | "Actionable" and "coherent" given operational definitions with observable tests |
| **002/003** (Branch Hygiene) | "Properly named" and "clean commits" given reference standards and concurrent execution test |
| **003/001** (AGENTS.md) | Bare existence + vague coverage changed to sub-question coverage, concrete recommendation requirement, and grounding example |
| **003/002** (Principle Adherence) | Low bar ("at least one implementable") raised to breadth, structure, and meta-tension engagement |
| **003/003** (Human Inbox) | "Simple enough" intent changed to measurable simplicity constraints |
| **004/002** (Design Docs) | "References a principle" changed to meaningful engagement with the principle |
| **004/007** (Install Process) | "Correctly" and "exists" changed to reference-matching, subset-only partials, and re-install safety |

Tasks where current verification was already strong and changes are primarily editorial (adding observability without changing substance): 001/002, 001/003, 003/005, 003/006, 003/008, 004/006, 004/008.

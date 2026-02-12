# Claude Code is a 10x developer with amnesia.

Every session, it does brilliant work. Then the session ends, and it forgets everything.

You start fresh. Re-explain the project. Get great output. Start another session. Re-explain again. Get output that subtly contradicts the first. Three sessions later, nothing works together. You're shipping features that break other features, and you can't tell what's done.

**You don't have a coding problem. You have a coordination problem.**

The code Claude writes is fine. What's missing is everything around it: who remembers what was decided? Who checks if today's work breaks yesterday's? Who decomposes the big goal into steps that can actually be verified? Who reviews from a perspective that isn't "the person who just wrote it"?

---

**The solutions people suggest don't help.**

| "Just use..." | Why it doesn't work |
|---|---|
| **Jira / Linear** | Built for persistent human workers who remember context. AI sessions are ephemeral. A ticket system can't teach a new session what the last one learned. |
| **CI/CD pipelines** | Catches bugs *after* they're written. You need structure that prevents incoherent work from starting. |
| **Heavy agent frameworks** | 30 specialized agents, custom vocabulary, mandatory installs, Go 1.23+. You wanted a tool, not a religion. |
| **Longer prompts** | Counterintuitively, *more detailed instructions produce worse results*. AI follows exact instructions off a cliff instead of using judgment. |

---

**This framework is six independent tools.**

| Tool | What it does | Without it |
|---|---|---|
| **The Seed** | Working principles that persist across every session | Each session reinvents its own standards |
| **Roles** | Architect, reviewer, implementer — different perspectives on the same work | One voice writes and approves its own code |
| **The PRD Format** | Tasks with clear outcomes and verification — the "what done looks like" | Features are "done" when the code exists, not when it works |
| **The State System** | Context that accumulates across sessions — decisions, investigations, knowledge | Every session starts from zero |
| **The Knowledge Convention** | How learnings persist so they're not re-discovered | Same mistakes, repeated forever |
| **The Orchestrator** | Optional coordinator that runs the architect→implement→review cycle | You manually manage every handoff |

**Use all six. Or just one. Nothing requires anything else.**

Want just the Seed? Copy one file. Want PRDs and roles but not the orchestrator? Use three files. Want the full system? It's still just files in a directory.

---

## The deeper story

### What this looks like in practice

You're a founder, a PM, or a solo developer. You're using Claude Code (or Cursor, or Copilot — doesn't matter). You're building something real. The first few sessions go great. Then around session 10, things start to feel off:

- You ask for a feature and it breaks something from last week
- You realize nobody documented *why* that API was structured that way
- You give Claude detailed instructions and get robotic output that technically follows the spec but misses the point
- You start a new session and spend 20 minutes re-establishing context before any real work happens
- You can't tell which of your 15 tasks are actually done vs "the code exists but nobody tested the edge cases"

This isn't a Claude problem. Claude is doing exactly what you asked, every single time. The problem is that "what you asked" keeps changing, context keeps getting lost, and nobody's watching the whole board.

### The counterintuitive insight

After 160+ tasks of real AI-assisted development, the single most important discovery was this:

> **The more detailed the task specification, the worse the results.**

When you give Claude the gist — the intent, the context, the "why" — it applies creativity when it hits obstacles. It walks around walls. It makes judgment calls that a senior engineer would make.

When you give Claude exact step-by-step instructions, it follows them off a cliff. If step 3 doesn't work as expected, it forces step 3 to work instead of reconsidering the approach. It optimizes against your specification, not against reality.

The sweet spot: **rich context + trust.** Enough to understand the intent. Enough freedom to execute with judgment.

This is what the framework is built on. Not more process. Not more detail. *Better context and structured trust.*

### What this is NOT

- **Not a project management tool.** No dashboards, no burndown charts, no sprint planning.
- **Not an agent framework.** No custom runtime, no agent registry, no execution engine.
- **Not a replacement for Claude Code.** It makes Claude Code better. It doesn't compete with it.
- **Not all-or-nothing.** The heaviest thing about it is choosing which parts you want.

### Who this is for

**You, if:**
- You're using AI to build real software (not just prototypes)
- You've felt the pain of sessions that don't cohere into a product
- You want structure without bureaucracy
- You want to tech-lead a team of AI agents the way a good tech lead manages humans: clear intent, trust in execution, review the output

**Not you, if:**
- You're building one-off scripts or prototypes that don't need to be maintained
- You have a large human engineering team with existing process that works
- You want AI to replace your judgment rather than amplify it

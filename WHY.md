# The death spiral of AI-assisted development

```
  "Build me a feature"
         ↓
  First result: impressive. 80% there.
         ↓
  "Fix this bug" → fixed, but broke something else
         ↓
  "Fix that too" → fixed, but subtle regression
         ↓
  "Be more specific" → follows instructions literally, stops thinking
         ↓
  Reactive patching. Whack-a-mole. Going in circles.
         ↓
  Weird warts buried 3 steps back. Don't know what depends on them.
         ↓
  Ship it broken   — or —   throw it away and start over.
```

**Your instinct is to give more detail. It makes things worse.**

```
  What you try             What actually happens
  ─────────────────────    ─────────────────────────────────────────
  More detailed prompts  → Worse results. Follows instructions off a cliff.
  More iterations        → More drift. Each fix breaks something else.
  More steering          → Less coherence. You break its long-horizon planning.
```

**This is not a skill issue. It's a structural one.**

Three things are going wrong, and none of them are about the AI being bad at coding:

**Context decay.** Interactive prompting forces short cycles and frequent interruptions. Every time you steer, you break the agent's long-horizon planning. It loses the thread of what the system *should become* and starts optimizing for the thing on your screen right now.

**Local optimization.** You see a bug, you fix the bug. The agent sees a test fail, it patches the test. Nobody steps back to ask "is this the right approach?" You're playing whack-a-mole, and each swing makes the next mole harder to hit.

**Architecture drift.** Without explicit phases — spec, design, implement, review — everything collapses into one long vibe-coding session. You optimize what you can see, not what the system needs. Decisions get made implicitly and buried in the diff.

**This is the same problem that engineering teams solved decades ago with code review, design docs, and tech leads.** But those solutions assume human teams. You're working with AI agents that start fresh every session, don't remember what they decided yesterday, and are constitutionally inclined to be helpful rather than critical of their own work.

---

**The solutions people suggest don't help.**

| "Just use..." | Why it doesn't work |
|---|---|
| **Jira / Linear** | Built for persistent human workers who remember context. AI sessions are ephemeral. A ticket system can't give a new session the judgment the last one developed. |
| **CI/CD pipelines** | Catches bugs *after* they're written. You need structure that prevents incoherent work from starting. |
| **Heavy agent frameworks** | 30 specialized agents, custom vocabulary, mandatory installs, Go 1.23+. You wanted a tool, not a religion. |
| **Longer, more detailed prompts** | Counterintuitively, *more detailed instructions produce worse results*. The agent follows your exact steps off a cliff instead of using judgment when the plan doesn't survive contact with reality. |
| **"Just keep iterating"** | This is the death spiral. Each iteration optimizes locally while drifting globally. More iterations make it worse, not better. |

---

**This framework is six independent tools.**

| Tool | What it does | Without it |
|---|---|---|
| **The Seed** | Working principles that persist across every session — the agent's engineering standards | Each session reinvents its own standards, or has none |
| **Roles** | Architect, reviewer, implementer — different *perspectives* on the same work | One voice writes, evaluates, and approves its own code |
| **The PRD Format** | Tasks with clear outcomes and verification — "what done actually looks like" | Features are "done" when the code exists, not when it works |
| **The State System** | Context that accumulates across sessions — decisions, investigations, knowledge | Every session starts from zero. Same mistakes, repeated. |
| **The Knowledge Convention** | How learnings persist so the next session is smarter than the last | Hard-won insights evaporate when the session ends |
| **The Orchestrator** | Enforces spec→design→implement→review phases so work doesn't collapse into one long vibe session | You manually manage every handoff, or more likely, you don't |

**Use all six. Or just one. Nothing requires anything else.**

Want just the Seed to improve any Claude Code session? Copy one file. Want PRDs and roles but not the orchestrator? Use three files. Want the full system running autonomously? It's still just files in a directory.

---

## The deeper story

### Why "just use Claude Code" isn't the answer

Claude Code is exceptional at executing within a session. But "executing within a session" is a small part of building software that works. The gaps:

**Within a single session:** Claude gets a great first result, but the refinement loop is where quality collapses. Without separate architect/reviewer perspectives, the agent can't challenge its own assumptions. It patches locally instead of reconsidering globally. It's helpful when it should be critical.

**Across sessions:** Context doesn't persist. The design rationale, the investigation that ruled out approach B, the subtle constraint discovered during implementation — all gone. The next session makes decisions the last session already disproved.

**At project scale:** Without explicit "what does done look like" criteria, you can't tell the difference between "the code exists" and "this actually works." Features accumulate without anyone verifying they cohere into a system.

The framework fills these gaps with lightweight structure — not process for the sake of process, but the minimum scaffolding that prevents the death spiral.

### The counterintuitive insight

After 160+ tasks of real AI-assisted development, the single most important discovery was this:

> **The more detailed the task specification, the worse the results.**

When you give Claude the gist — the intent, the context, the "why" — it applies creativity when it hits obstacles. It walks around walls. It makes judgment calls that a senior engineer would make.

When you give Claude exact step-by-step instructions, it follows them off a cliff. If step 3 doesn't work as expected, it forces step 3 to work instead of reconsidering the approach. It optimizes against your specification, not against reality.

The sweet spot: **rich context + trust.** Enough to understand the intent. Enough freedom to execute with judgment. This is exactly how a good tech lead manages a strong team — and it's how you should manage AI agents.

### What this is NOT

- **Not a project management tool.** No dashboards, no burndown charts, no sprint planning.
- **Not an agent framework.** No custom runtime, no agent registry, no execution engine.
- **Not a replacement for Claude Code.** It makes Claude Code better at building real software. It doesn't compete with it.
- **Not all-or-nothing.** The heaviest thing about it is choosing which parts you want.

### Who this is for

**You, if:**
- You've used AI to build something real and felt the excitement of the first result followed by the frustration of the refinement death spiral
- You've abandoned a project (or wanted to) because the codebase became untrusted spaghetti after too many AI-assisted iterations
- You want to tech-lead a team of AI agents the way a good tech lead manages humans: clear intent, structured review, trust in execution
- You want structure without bureaucracy

**Not you, if:**
- You're building one-off scripts or prototypes that don't need to be maintained
- You have a large human engineering team with established process
- You want AI to replace your judgment rather than amplify it

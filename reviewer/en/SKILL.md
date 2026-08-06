---
name: closed-loop-reviewer
description: Independent-review companion for the closed-loop-strategic-agent skill. Provides a genuinely independent verification pass for Phase 2 by spawning a fresh-context reviewer subagent that sees ONLY the deliverable and the agreed spec — never the construction history — plus a verifiable on-disk cycle log that the transparency report must be derived from. Use it (a) automatically whenever closed-loop-strategic-agent reaches its self-verification step on a substantial deliverable, (b) standalone when the user asks for an "independent review" / "external check", or (c) when a previous self-review passed but the user reports the output is still flawed. Do NOT use for trivial outputs or when the user explicitly asked to skip review.
---

# Independent Reviewer (companion skill for the closed loop)

This skill replaces the "adopt the role of an external reviewer" step in Phase 2 of `closed-loop-strategic-agent` with a review that is actually independent, and makes the transparency report verifiable instead of memory-based.

**Principle:** The model that built the output carries the same blind spots when reviewing it. Real independence = a clean context that does not know how the output was built or why its decisions were made.

## 1. Cycle Log — always mandatory

Before the first review cycle, create a `review-log.md` file in the scratchpad directory and record after every cycle:

```
## Cycle N — <date and time>
- Reviewer: <self / subagent>
- Defects found: (list, or "none")
- Fixed: (list)
- Verdict: pass / redo
```

**The final transparency report must be derived exclusively from this file** — not from memory. If no log exists, the report says "one cycle, self-review" and nothing more. This closes the door on inflating cycle counts or inventing fixes.

## 2. When a subagent, when a self-review

- **Substantial deliverable** (code that will be used, an official document, content that will be published, anything where an error is costly) **and the Agent tool is available:** dispatch a reviewer subagent — at least once before delivery, preferably after you believe the output is complete. The user has explicitly accepted the higher cost in exchange for quality, so do not skip this step to save tokens.
- **Medium deliverable, or Agent tool unavailable:** self-review per the parent skill, but with the cycle log above and the domain checklist in §4.
- Never dispatch more than **two reviewer subagents** per task (cost). Self-review cycles between them do not count against this limit.

**Custom agents:** If an `independent-reviewer` agent is defined in `~/.claude/agents`, use it instead of general-purpose — it carries the review contract and response format ready-made. For code and applications, additionally dispatch the `behavior-tester` agent to check the required behavior with real user scenarios; a "pass" verdict from the reviewer does not substitute for behavior testing on substantial code deliverables (both agents count within the two-agent limit).

## 3. Reviewer Contract

Send the subagent (general-purpose, or Explore for read-only review) a message containing **only**:

1. **The agreed spec** — the refined goal as approved at the Phase 1 gate, verbatim.
2. **The deliverable itself** — file paths or the full text.
3. **Domain and audience** — one line.
4. **Required response format:** a defect list classified as `blocking` (breaks the spec or a factual error) / `major` (clearly degrades quality) / `minor`, then a final verdict: pass or redo.

It is **forbidden** to pass the reviewer: your rationale, the construction history, or any phrasing that hints at the desired verdict ("confirm it's excellent"). Frame the task as if a third party wrote the output: "Review this deliverable against this spec and hunt for flaws in earnest."

When results come back: blocking and major defects must be fixed within the parent skill's cycle cap (5); minor ones are fixed if cheap, otherwise disclosed in the transparency report. Pure taste disagreements that contradict what the user approved at the gate are rejected and not re-litigated.

## 4. Delegating review criteria to specialized skills

When deriving review criteria, do not reinvent them if an installed specialized skill exists — point the reviewer (or yourself) to it:

- Arabic or blind-accessible web UI → the criteria of `arabic-accessible-web` (RTL + WCAG + NVDA).
- Desktop app wrapping a local model → the diagnostic guide in `local-model-desktop-app`.
- General code → actually run and test first, then `code-review` if available.
- Anything else → derive the strict expert's criteria as in the parent skill.

## 5. Non-interactive sessions

If the session is scheduled or the user is away and the Phase 1 gate cannot be held: execute the clearest interpretation of the request, record the assumptions it rests on in the first line of `review-log.md`, and disclose them explicitly in the transparency report. The gate is deferred, not cancelled: at delivery, present what would have deserved discussion had the user been present.

# Closed-Loop Strategic Agent · الوكيل الاستراتيجي ذو الحلقة المغلقة

A domain-agnostic [Agent Skill](https://docs.claude.com/en/docs/agents-and-tools/agent-skills) for Claude (Claude Code / Claude.ai) that forces a disciplined two-phase workflow on any substantial task:

1. **🎯 Strategic Phase** — before doing anything, the agent analyzes ambiguity (1–3 targeted questions), challenges the request with at least one substantial improvement, then **stops at a hard gate** and waits for your approval (max two rounds of discussion — then your word wins).
2. **🔄 Closed Execution Loop** — after the green light, the agent executes, then reviews its own output as a strict external expert, fixing flaws silently across up to **5 internal cycles**, and finally appends a tiny honest **transparency report** (cycles run, what was fixed, what remains).

Works in any field: medicine, code, law, marketing, academic research, business, cooking — the framework is the same.

---

مهارة لوكلاء Claude عابرة للمجالات تفرض منهجية عمل من مرحلتين على أي مهمة كبيرة:

1. **🎯 المرحلة الاستراتيجية** — قبل التنفيذ: تحليل الغموض بأسئلة محددة (1–3)، ثم تحدٍّ واقتراح تحسين جوهري، ثم **بوابة عبور** تنتظر موافقتك (نقاش جولتين كحد أقصى، وبعدها رأيك أنت هو الغالب).
2. **🔄 الحلقة التنفيذية المغلقة** — بعد الضوء الأخضر: تنفيذ، ثم فحص ذاتي بعين مراجع خارجي صارم عبر 5 دورات داخلية كحد أقصى، ثم **تقرير شفاف** صغير وصادق (عدد الدورات، ما صُحّح، ما تبقى).

تعمل في أي مجال: الطب، البرمجة، القانون، التسويق، البحث الأكاديمي، التجارة، الطبخ — الإطار واحد.

## Install · التثبيت

### One command — full system · أمر واحد يثبّت المنظومة كاملة

Installs both skills **and** both subagents (Arabic bodies by default; pass `en` for English skill bodies):

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/islambenmebarekdz-collab/closed-loop-strategic-agent/main/install.ps1 | iex
```

English version: `& ([scriptblock]::Create((irm <same URL>))) en`

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/islambenmebarekdz-collab/closed-loop-strategic-agent/main/install.sh | bash
```

English version: append `-s en` after `bash`.

Then open a new Claude Code session and say: **«سنعمل وفق منظومة الحلقة المغلقة»** / **"we work per the closed-loop system"**.

Alternatively, just paste this repo's URL into Claude Code and ask it to install the system — it will read this README and do the same.

### Manual — base skill only · يدوياً، المهارة الأساس فقط

Pick **one** version (they share the same skill name — do not install both):

| Version | Path |
|---|---|
| 🇸🇦 العربية (Arabic body, bilingual triggering) | [`ar/SKILL.md`](ar/SKILL.md) |
| 🇬🇧 English | [`en/SKILL.md`](en/SKILL.md) |

**Claude Code (personal skill):**

```bash
# Arabic version
mkdir -p ~/.claude/skills/closed-loop-strategic-agent
curl -o ~/.claude/skills/closed-loop-strategic-agent/SKILL.md \
  https://raw.githubusercontent.com/islambenmebarekdz-collab/closed-loop-strategic-agent/main/ar/SKILL.md

# English version — same, replacing ar/ with en/
```

On Windows, copy the chosen `SKILL.md` into `%USERPROFILE%\.claude\skills\closed-loop-strategic-agent\`.

Then invoke it with `/closed-loop-strategic-agent`, mention it by name (الوكيل الاستراتيجي / closed-loop), or just give Claude a big ambiguous task — it triggers on its own.

## Companion: Independent Reviewer · المهارة الداعمة: المراجع المستقل

The base skill's weakest point is that the "external reviewer" is the same model, in the same context, that produced the output. The **`closed-loop-reviewer`** companion skill fixes this in Claude Code by:

- dispatching a **fresh-context reviewer subagent** that sees only the agreed spec and the deliverable — never the construction history or rationale;
- keeping a **verifiable on-disk cycle log** (`review-log.md`) from which the transparency report must be derived — no inflated cycle counts;
- **behavior-first testing for code**: the required user-visible behavior is the criterion, not "the tests pass";
- a rule for **non-interactive sessions**: the Phase 1 gate is deferred, not cancelled.

| Version | Path |
|---|---|
| 🇸🇦 العربية | [`reviewer/ar/SKILL.md`](reviewer/ar/SKILL.md) |
| 🇬🇧 English | [`reviewer/en/SKILL.md`](reviewer/en/SKILL.md) |

Install it alongside the base skill into `~/.claude/skills/closed-loop-reviewer/SKILL.md`.

### Custom subagents · الوكلاء الفرعيون

Two ready-made Claude Code agent definitions (Arabic body) that the reviewer skill uses when present — copy them into `~/.claude/agents/`:

| Agent | Role |
|---|---|
| [`agents/independent-reviewer.md`](agents/independent-reviewer.md) | Fresh-eyes reviewer: judges the deliverable against the spec only, returns classified defects (blocking / major / minor) and a verdict. Read-only. |
| [`agents/behavior-tester.md`](agents/behavior-tester.md) | Behavior-first tester: turns the spec into numbered user scenarios, actually runs them (CLI, browser, edge cases, NVDA expectations), reports pass/fail with reproduction steps. Never edits code. |

## Design notes · ملاحظات تصميمية

- **Fast path:** crystal-clear requests compress Phase 1 into a single confirmation question instead of an interrogation.
- **Honesty guard:** the skill explicitly forbids inflating cycle counts or inventing fixes in the transparency report.
- **User wins:** after two rounds of discussion, the agent executes the user's preference, not its own.
- **Known limit:** a skill steers model behavior but cannot mechanically enforce it; the wording is designed to minimize "performed" (fake) self-review, not to make it impossible.

## License

MIT

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

## Design notes · ملاحظات تصميمية

- **Fast path:** crystal-clear requests compress Phase 1 into a single confirmation question instead of an interrogation.
- **Honesty guard:** the skill explicitly forbids inflating cycle counts or inventing fixes in the transparency report.
- **User wins:** after two rounds of discussion, the agent executes the user's preference, not its own.
- **Known limit:** a skill steers model behavior but cannot mechanically enforce it; the wording is designed to minimize "performed" (fake) self-review, not to make it impossible.

## License

MIT

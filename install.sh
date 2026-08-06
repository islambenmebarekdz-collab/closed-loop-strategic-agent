#!/usr/bin/env bash
# Installs the full closed-loop system (2 skills + 2 agents) for Claude Code on Linux/macOS.
# Usage:  curl -fsSL https://raw.githubusercontent.com/islambenmebarekdz-collab/closed-loop-strategic-agent/main/install.sh | bash
# English skill bodies instead of Arabic:  ... | bash -s en
set -euo pipefail

LANG_CHOICE="${1:-ar}"
case "$LANG_CHOICE" in ar|en) ;; *) echo "Usage: install.sh [ar|en]" >&2; exit 1 ;; esac

BASE="https://raw.githubusercontent.com/islambenmebarekdz-collab/closed-loop-strategic-agent/main"
CLAUDE="$HOME/.claude"

install_file() {
    mkdir -p "$(dirname "$2")"
    curl -fsSL "$1" -o "$2"
    echo "Installed: $2"
}

install_file "$BASE/$LANG_CHOICE/SKILL.md"          "$CLAUDE/skills/closed-loop-strategic-agent/SKILL.md"
install_file "$BASE/reviewer/$LANG_CHOICE/SKILL.md" "$CLAUDE/skills/closed-loop-reviewer/SKILL.md"
install_file "$BASE/agents/independent-reviewer.md" "$CLAUDE/agents/independent-reviewer.md"
install_file "$BASE/agents/behavior-tester.md"      "$CLAUDE/agents/behavior-tester.md"

echo
echo "Done ($LANG_CHOICE version). Open a new Claude Code session and say:"
echo '  "سنعمل وفق منظومة الحلقة المغلقة" / "we work per the closed-loop system"'

#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SKILLS_DIR="$SCRIPT_DIR/skills"

if [ ! -d "$SOURCE_SKILLS_DIR" ]; then
    echo "Error: Source skills directory not found at $SOURCE_SKILLS_DIR" >&2
    exit 1
fi

DESTINATIONS=()

if [ "$TARGET" = "all" ] || [ "$TARGET" = "opencode" ]; then
    DESTINATIONS+=("$HOME/.config/opencode/skills")
fi

if [ "$TARGET" = "all" ] || [ "$TARGET" = "agents" ]; then
    DESTINATIONS+=("$HOME/.agents/skills")
fi

if [ "$TARGET" = "all" ] || [ "$TARGET" = "claude" ]; then
    DESTINATIONS+=("$HOME/.claude/skills")
fi

echo "Installing Flutter Clean Skills..."

for dest in "${DESTINATIONS[@]}"; do
    mkdir -p "$dest"
    echo "Target: $dest"
    for skill_path in "$SOURCE_SKILLS_DIR"/*/; do
        skill_name="$(basename "$skill_path")"
        cp -R "$skill_path" "$dest/$skill_name"
        echo "  -> Installed $skill_name"
    done
done

echo ""
echo "All skills successfully installed!"

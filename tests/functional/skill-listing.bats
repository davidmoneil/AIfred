#!/usr/bin/env bats
# Skill structure validation

load helpers/setup

@test "every skill directory has SKILL.md" {
    local failures=0
    for skill_dir in "$PROJECT_ROOT/.claude/skills"/*/; do
        [[ "$(basename "$skill_dir")" == "_template" ]] && continue
        if [[ ! -f "$skill_dir/SKILL.md" ]]; then
            echo "MISSING: $skill_dir/SKILL.md" >&2
            failures=$((failures + 1))
        fi
    done
    [ "$failures" -eq 0 ]
}

@test "all skill config.json files are valid JSON" {
    local tested=0
    local failures=0
    while IFS= read -r config; do
        if ! jq empty "$config" 2>/dev/null; then
            echo "INVALID: $config" >&2
            failures=$((failures + 1))
        fi
        tested=$((tested + 1))
    done < <(find "$PROJECT_ROOT/.claude/skills" -name "config.json" -type f)
    [ "$failures" -eq 0 ]
    [ "$tested" -gt 0 ] || skip "no config.json files found"
}

@test "skills index exists and references real skills" {
    local index="$PROJECT_ROOT/.claude/skills/_index.md"
    [ -f "$index" ]
    # Verify at least some skill names appear in the index
    local found=0
    for skill_dir in "$PROJECT_ROOT/.claude/skills"/*/; do
        name="$(basename "$skill_dir")"
        [[ "$name" == "_template" ]] && continue
        if grep -q "$name" "$index" 2>/dev/null; then
            found=$((found + 1))
        fi
    done
    [ "$found" -gt 0 ]
}

@test "skill SKILL.md files are non-empty" {
    local failures=0
    while IFS= read -r skillmd; do
        if [[ ! -s "$skillmd" ]]; then
            echo "EMPTY: $skillmd" >&2
            failures=$((failures + 1))
        fi
    done < <(find "$PROJECT_ROOT/.claude/skills" -name "SKILL.md" -type f)
    [ "$failures" -eq 0 ]
}

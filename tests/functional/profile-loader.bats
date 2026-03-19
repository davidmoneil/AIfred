#!/usr/bin/env bats
# Profile loader functional tests

load helpers/setup

@test "profile-loader.js exists and is valid JS" {
    run node --check "$PROJECT_ROOT/scripts/profile-loader.js"
    [ "$status" -eq 0 ]
}

@test "profile-loader --dry-run produces output" {
    cd "$PROJECT_ROOT"
    run node scripts/profile-loader.js --dry-run
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "profile-loader --list shows available profiles" {
    cd "$PROJECT_ROOT"
    run node scripts/profile-loader.js --list
    [ "$status" -eq 0 ]
    [[ "$output" == *"general"* ]]
}

@test "profile-loader --current shows active layers" {
    cd "$PROJECT_ROOT"
    run node scripts/profile-loader.js --current
    # May fail if no active profile set — that's okay, just shouldn't crash
    [[ "$status" -eq 0 ]] || [[ "$output" == *"No active"* ]] || [[ "$output" == *"not found"* ]]
}

@test "all profile YAML files are parseable by profile-loader" {
    cd "$PROJECT_ROOT"
    for profile in profiles/*.yaml; do
        [[ "$(basename "$profile")" == "schema.yaml" ]] && continue
        [[ "$(basename "$profile")" == "_template.yaml" ]] && continue
        # Just verify the loader doesn't crash when listing (which reads all profiles)
        run node scripts/profile-loader.js --list
        [ "$status" -eq 0 ]
        break  # --list reads all profiles, one pass is enough
    done
}

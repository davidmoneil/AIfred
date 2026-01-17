# Prompts Used in Experiment

## Phase 1: Build Decompose-Official

### Initial Build Prompt

```
/ralph-loop:ralph-loop "Build a Plugin Decomposition Tool for Jarvis.

## Core Requirements

1. **Plugin Discovery** (--discover)
   - Search both ~/.claude/plugins/cache/ and ~/.claude/plugins/marketplaces/
   - Accept plugin name or path as argument
   - Return full path to plugin directory

2. **Plugin Review** (--review PATH)
   - Analyze plugin structure: commands/, hooks/, scripts/
   - Document each component's purpose and functionality
   - Generate structured review report

3. **Integration Analysis** (--analyze PATH)
   - Classify each component as ADOPT/ADAPT/DEFER/SKIP
   - Compare against existing Jarvis capabilities
   - Output adoption recommendation

4. **Redundancy Scan** (--scan-redundancy)
   - Spawn code-analyzer agent to reverse-engineer plugin functions
   - Perform semantic comparison against Jarvis codebase
   - Output functional overlap report (not just name matching)

5. **Decomposition Plan** (--decompose PATH)
   - Generate file mapping from plugin to Jarvis locations
   - Create integration checklist

6. **Interactive Browser** (--browse)
   - List available plugins in menu format
   - Allow selection for subsequent operations

## Implementation

Create these files:
- .claude/commands/plugin-decompose.md
- .claude/scripts/plugin-decompose.sh
- .claude/skills/plugin-decompose/SKILL.md

Test each feature against a real plugin.

Output <promise>DECOMPOSE TOOL V1 COMPLETE</promise> when all features work."
--max-iterations 15
--completion-promise "ALL TOOL FEATURES TESTED AGAINST A REAL PLUGIN. DECOMPOSE TOOL V1 COMPLETE"
```

### Enhancement Prompt (--execute feature)

```
/ralph-loop:ralph-loop "Enhance the Plugin Decomposition Tool with --execute functionality.

## Context

The plugin-decompose tool exists at:
- .claude/scripts/plugin-decompose.sh
- .claude/commands/plugin-decompose.md
- .claude/skills/plugin-decompose/SKILL.md

It currently has these features: --discover, --review, --analyze, --scan-redundancy, --decompose, --browse

## New Requirement: --execute

Add an --execute flag that performs actual plugin integration:

### --execute <path> [--dry-run]

1. **Pre-flight checks**
   - Verify --review, --analyze, and --decompose reports exist for this plugin
   - If missing, generate them automatically first
   - Parse the decomposition plan to get file mappings

2. **Integration execution**
   - For COPY actions: Copy files to Jarvis locations
   - For MERGE actions:
     - Create backup of existing file
     - Prompt user (or auto-merge if --auto flag)
     - Generate diff showing proposed merge
   - For hooks: Register in .claude/settings.json
   - For skills: Add to skills directory
   - For commands: Add to commands directory

3. **Post-integration validation**
   - Verify all copied files exist
   - Verify hooks are registered
   - Run basic syntax check on scripts (bash -n)
   - Generate integration report

4. **Rollback capability**
   - Create .rollback-{plugin}-{timestamp}.json with all changes
   - Implement --rollback <file> to undo integration

### --dry-run modifier
When combined with --execute, shows what WOULD happen without making changes.

## Implementation

1. Add the --execute function to plugin-decompose.sh
2. Add --dry-run flag support
3. Add --rollback function
4. Update plugin-decompose.md command documentation
5. Update SKILL.md documentation

## Validation Requirements (ALL must pass)

After implementation, validate EVERY feature:

1. **Existing features** (test against example-plugin):
   - [ ] --discover example-plugin → finds plugin
   - [ ] --review → generates review report
   - [ ] --analyze → generates analysis report
   - [ ] --scan-redundancy → generates redundancy report
   - [ ] --decompose → generates decomposition plan
   - [ ] --browse → lists plugins

2. **New features** (test against example-plugin):
   - [ ] --execute --dry-run → shows planned changes without executing
   - [ ] --execute → actually integrates the plugin
   - [ ] Verify example-command.md exists in .claude/commands/
   - [ ] Verify example-skill/ exists in .claude/skills/
   - [ ] --rollback → successfully reverts the integration
   - [ ] Verify files are removed after rollback

3. **End-to-end validation**:
   - [ ] Run /example-command (or invoke the skill) to prove it works
   - [ ] Confirm the integrated components function correctly

Output <promise>EXECUTE FEATURE COMPLETE AND ALL INTEGRATIONS VALIDATED</promise> ONLY when:
- All 6 original features still work
- --execute successfully integrates example-plugin
- --dry-run shows changes without making them
- --rollback successfully reverts changes
- The integrated plugin components actually work in Jarvis"
--max-iterations 20
--completion-promise "EXECUTE FEATURE COMPLETE AND ALL INTEGRATIONS VALIDATED AND THE NEW INTEGRATED JARVIS-NATIVE TOOL FUNCTIONS HAVE ALSO BEEN VALIDATED"
```

---

## Phase 3: Build Decompose-Native

### Initial Build Prompt
(Identical to Phase 1 Initial Build Prompt - used with Jarvis-native `/ralph-loop`)

### Enhancement Prompt
(Identical to Phase 1 Enhancement Prompt - used with Jarvis-native `/ralph-loop`)

---

## Notes

- Both Tier 2 systems (Official-built and Native-built) were constructed using identical prompts
- The only difference was the Tier 1 system used to execute the prompts
- This controlled experiment design allows direct comparison of outputs

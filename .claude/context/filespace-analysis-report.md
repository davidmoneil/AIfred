# Jarvis Filespace — Network Analysis Report

**Generated**: 2026-02-11 19:17

**Scanner**: graph-scanner.py (enhanced v2)


## Summary

| Metric | Value |
|--------|-------|
| Nodes | 815 |
| Edges | 5002 |
| Density | 0.0075 |
| Avg Clustering | 0.2606 |
| Weakly Connected Components | 86 |
| Strongly Connected Components | 412 |
| Non-trivial SCCs (mutual refs) | 5 |
| Isolated nodes | 85 |
| Bridges | 77 |

## Layer Distribution

| Layer | Files |
|-------|-------|
| pneuma | 434 |
| nous | 223 |
| soma-projects | 153 |
| root | 5 |

## Edge Type Distribution

| Type | Count |
|------|-------|
| doc_reference | 2520 |
| references_code | 1059 |
| reference | 921 |
| config_reference | 235 |
| reads_from | 162 |
| code_dependency | 105 |

## Top 20 Files by PageRank (most important)

| Rank | File | PageRank |
|------|------|----------|
| 1 | `.claude/context/session-state.md` | 0.029225 |
| 2 | `CLAUDE.md` | 0.022010 |
| 3 | `.claude/context/psyche/capability-map.yaml` | 0.018086 |
| 4 | `.claude/context/current-priorities.md` | 0.014642 |
| 5 | `.claude/scripts/jarvis-watcher.sh` | 0.012572 |
| 6 | `.claude/hooks/session-start.sh` | 0.011137 |
| 7 | `README.md` | 0.010526 |
| 8 | `.claude/skills/pdf/forms.md` | 0.010081 |
| 9 | `.claude/scripts/virgil.sh` | 0.010031 |
| 10 | `.claude/scripts/launch-jarvis-tmux.sh` | 0.009959 |
| 11 | `.claude/skills/knowledge-ops/SKILL.md` | 0.009428 |
| 12 | `.claude/context/patterns/_index.md` | 0.008443 |
| 13 | `projects/project-aion/roadmap.md` | 0.007332 |
| 14 | `paths-registry.yaml` | 0.006942 |
| 15 | `.claude/agents/memory/docker-deployer/learnings.json` | 0.006779 |
| 16 | `.claude/scripts/jicm-watcher.sh` | 0.006657 |
| 17 | `.claude/context/integrations/capability-matrix.md` | 0.006509 |
| 18 | `.claude/context/designs/jicm-v5-design-addendum.md` | 0.006460 |
| 19 | `.claude/skills/_index.md` | 0.006124 |
| 20 | `.claude/hooks/virgil-tracker.js` | 0.006105 |

## Top 20 Files by In-Degree (most referenced)

| Rank | File | In-Degree |
|------|------|-----------|
| 1 | `.claude/context/session-state.md` | 150 |
| 2 | `CLAUDE.md` | 126 |
| 3 | `.claude/context/current-priorities.md` | 95 |
| 4 | `.claude/hooks/session-start.sh` | 82 |
| 5 | `.claude/scripts/jarvis-watcher.sh` | 69 |
| 6 | `.claude/context/psyche/capability-map.yaml` | 68 |
| 7 | `.claude/skills/knowledge-ops/SKILL.md` | 56 |
| 8 | `README.md` | 52 |
| 9 | `paths-registry.yaml` | 51 |
| 10 | `.claude/context/patterns/_index.md` | 48 |
| 11 | `.claude/scripts/launch-jarvis-tmux.sh` | 48 |
| 12 | `.claude/hooks/context-accumulator.js` | 47 |
| 13 | `.claude/scripts/README.md` | 43 |
| 14 | `.claude/skills/_index.md` | 43 |
| 15 | `.claude/config/autonomy-config.yaml` | 40 |
| 16 | `.claude/context/psyche/jarvis-identity.md` | 40 |
| 17 | `.claude/commands/README.md` | 38 |
| 18 | `.claude/context/_index.md` | 38 |
| 19 | `.claude/hooks/telemetry-emitter.js` | 38 |
| 20 | `projects/project-aion/roadmap.md` | 38 |

## Top 20 Files by Out-Degree (most outgoing references)

| Rank | File | Out-Degree |
|------|------|------------|
| 1 | `.claude/context/archive/session-state/session-state-2026-01-20.md` | 169 |
| 2 | `CHANGELOG.md` | 156 |
| 3 | `projects/project-aion/reports/archive/pr-10-inventory-audit-2026-01-09.md` | 134 |
| 4 | `projects/project-aion/reports/Test4_results.txt` | 84 |
| 5 | `.claude/context/psyche/capability-map.yaml` | 74 |
| 6 | `.claude/context/psyche/nous-map.md` | 71 |
| 7 | `projects/project-aion/progress/2026-01-22-organization-findings.md` | 64 |
| 8 | `.claude/context/patterns/tool-selection-intelligence.md` | 58 |
| 9 | `projects/project-aion/evolution/aifred-integration/sync-reports/comprehensive-analysis-2026-01-21.md` | 57 |
| 10 | `.claude/plans/roadmap-ii.md` | 56 |
| 11 | `.claude/context/_index.md` | 54 |
| 12 | `.claude/context/patterns/_index.md` | 52 |
| 13 | `.claude/context/.context-captured.txt` | 48 |
| 14 | `.claude/context/.context-captured-escaped.txt` | 47 |
| 15 | `projects/project-aion/reports/archive/pr-10-organization-cleanup-final-2026-01-09.md` | 41 |
| 16 | `projects/project-aion/roadmap.md` | 41 |
| 17 | `.claude/logs/orchestration-detections.jsonl` | 40 |
| 18 | `projects/project-aion/evolution/aifred-integration/roadmap.md` | 40 |
| 19 | `.claude/context/reference/hook-consolidation-plan.md` | 39 |
| 20 | `projects/project-aion/plans/archive/pr-10-design-plan.md` | 38 |

## Top 20 Files by Betweenness Centrality (bridge/bottleneck files)

| Rank | File | Betweenness |
|------|------|-------------|
| 1 | `.claude/context/session-state.md` | 0.099370 |
| 2 | `.claude/context/psyche/capability-map.yaml` | 0.059477 |
| 3 | `CLAUDE.md` | 0.048818 |
| 4 | `.claude/context/patterns/_index.md` | 0.040036 |
| 5 | `CHANGELOG.md` | 0.037992 |
| 6 | `.claude/context/archive/session-state/session-state-2026-01-20.md` | 0.034780 |
| 7 | `.claude/skills/_index.md` | 0.030854 |
| 8 | `.claude/context/_index.md` | 0.029708 |
| 9 | `.claude/hooks/README.md` | 0.028926 |
| 10 | `.claude/context/psyche/nous-map.md` | 0.024491 |
| 11 | `.claude/scripts/jarvis-watcher.sh` | 0.024059 |
| 12 | `.claude/context/current-priorities.md` | 0.022599 |
| 13 | `.claude/plans/roadmap-ii.md` | 0.022278 |
| 14 | `README.md` | 0.019868 |
| 15 | `projects/project-aion/roadmap.md` | 0.015923 |
| 16 | `.claude/logs/orchestration-detections.jsonl` | 0.015496 |
| 17 | `.claude/context/patterns/multi-repo-credential-pattern.md` | 0.015222 |
| 18 | `.claude/context/patterns/session-completion-pattern.md` | 0.014619 |
| 19 | `.claude/context/psyche/_index.md` | 0.014241 |
| 20 | `.claude/agents/compression-agent.md` | 0.013904 |

## Top 20 Hub Files (link to many important files)

| Rank | File | Hub Score |
|------|------|-----------|
| 1 | `.claude/context/archive/session-state/session-state-2026-01-20.md` | 0.025652 |
| 2 | `CHANGELOG.md` | 0.023920 |
| 3 | `projects/project-aion/reports/archive/pr-10-inventory-audit-2026-01-09.md` | 0.021505 |
| 4 | `projects/project-aion/reports/Test4_results.txt` | 0.013223 |
| 5 | `.claude/context/patterns/tool-selection-intelligence.md` | 0.011687 |
| 6 | `projects/project-aion/progress/2026-01-22-organization-findings.md` | 0.011654 |
| 7 | `projects/project-aion/evolution/aifred-integration/sync-reports/comprehensive-analysis-2026-01-21.md` | 0.010320 |
| 8 | `.claude/context/_index.md` | 0.010202 |
| 9 | `projects/project-aion/reports/archive/pr-10-organization-cleanup-final-2026-01-09.md` | 0.009552 |
| 10 | `projects/project-aion/roadmap.md` | 0.008983 |
| 11 | `projects/project-aion/plans/archive/pr-10-design-plan.md` | 0.008735 |
| 12 | `.claude/context/psyche/nous-map.md` | 0.008576 |
| 13 | `.claude/context/.context-captured.txt` | 0.008250 |
| 14 | `projects/project-aion/designs/current/phase-6-autonomy-design.md` | 0.008113 |
| 15 | `.claude/context/.context-captured-escaped.txt` | 0.007881 |
| 16 | `projects/project-aion/evolution/aifred-integration/roadmap.md` | 0.007879 |
| 17 | `.claude/context/patterns/archon-architecture-pattern.md` | 0.007862 |
| 18 | `.claude/context/configuration-summary.md` | 0.007661 |
| 19 | `.claude/logs/jicm/archive/compressed-context-20260210-005039.md` | 0.007540 |
| 20 | `.claude/logs/orchestration-detections.jsonl` | 0.007257 |

## Top 20 Authority Files (referenced by many important files)

| Rank | File | Authority Score |
|------|------|-----------------|
| 1 | `.claude/context/session-state.md` | 0.020675 |
| 2 | `CLAUDE.md` | 0.018623 |
| 3 | `.claude/context/current-priorities.md` | 0.015756 |
| 4 | `.claude/hooks/session-start.sh` | 0.013312 |
| 5 | `.claude/hooks/context-accumulator.js` | 0.009635 |
| 6 | `.claude/context/psyche/jarvis-identity.md` | 0.008761 |
| 7 | `.claude/commands/README.md` | 0.008693 |
| 8 | `.claude/skills/_index.md` | 0.008655 |
| 9 | `.claude/context/_index.md` | 0.008501 |
| 10 | `.claude/context/psyche/capability-map.yaml` | 0.008208 |
| 11 | `.claude/context/patterns/_index.md` | 0.008084 |
| 12 | `.claude/scripts/jarvis-watcher.sh` | 0.007917 |
| 13 | `paths-registry.yaml` | 0.007600 |
| 14 | `projects/project-aion/roadmap.md` | 0.007514 |
| 15 | `.claude/skills/knowledge-ops/SKILL.md` | 0.007227 |
| 16 | `.claude/scripts/README.md` | 0.006882 |
| 17 | `.claude/hooks/archive/selection-audit.js` | 0.006790 |
| 18 | `.claude/hooks/cross-project-commit-tracker.js` | 0.006685 |
| 19 | `.claude/logs/context-estimate.json` | 0.006233 |
| 20 | `.claude/hooks/self-correction-capture.js` | 0.006143 |

## Weakly Connected Components

Total: 86 components

| Component | Size | Sample Members |
|-----------|------|----------------|
| wcc_0 | 730 | `.claude/agents/README.md`, `.claude/agents/_archive/deep-research.md`, `.claude/agents/_archive/docker-deployer.md` ... +727 |
| wcc_1 | 1 | `.claude/agents/_archive/_template-agent.md`  |
| wcc_2 | 1 | `.claude/agents/memory/deep-research/afk-code-safety-reliability-2026-02-05.md`  |
| wcc_3 | 1 | `.claude/agents/memory/deep-research/vestige-research-2026-02-05.md`  |
| wcc_4 | 1 | `.claude/commands/example-command.md.backup.20260117_133243`  |
| wcc_5 | 1 | `.claude/config/autonomy-config.yaml.backup`  |
| wcc_6 | 1 | `.claude/config/credentials.local.yaml`  |
| wcc_7 | 1 | `.claude/context/.active-tasks.txt`  |
| wcc_8 | 1 | `.claude/context/.capture-complete`  |
| wcc_9 | 1 | `.claude/context/.command-output`  |
| wcc_10 | 1 | `.claude/context/.ennoia-state`  |
| ... | ... | 75 more components |

## Strongly Connected Components (Mutual Reference Clusters)

Total non-trivial SCCs: 5

### scc_200 (393 files)

- `.claude/agents/README.md`
- `.claude/agents/code-analyzer.md`
- `.claude/agents/code-review.md`
- `.claude/agents/compression-agent.md`
- `.claude/agents/context-compressor.md`
- `.claude/agents/docker-deployer.md`
- `.claude/agents/jicm-agent.md`
- `.claude/agents/memory-bank-synchronizer.md`
- `.claude/agents/memory/deep-research/_index.md`
- `.claude/agents/memory/deep-research/marvin-chief-of-staff-analysis.md`
- ... +383 more

### scc_220 (6 files)

- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/dml-chart.xsd`
- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/dml-chartDrawing.xsd`
- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/dml-diagram.xsd`
- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/dml-lockedCanvas.xsd`
- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/dml-main.xsd`
- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/dml-picture.xsd`

### scc_173 (4 files)

- `.claude/skills/pdf/forms.md`
- `.claude/skills/pdf/scripts/check_bounding_boxes.py`
- `.claude/skills/pdf/scripts/extract_form_field_info.py`
- `.claude/skills/pdf/scripts/fill_fillable_fields.py`

### scc_302 (3 files)

- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/dml-wordprocessingDrawing.xsd`
- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/shared-math.xsd`
- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/wml.xsd`

### scc_313 (2 files)

- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/vml-main.xsd`
- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/vml-officeDrawing.xsd`

## Isolated Nodes (no edges)

- `.claude/agents/_archive/_template-agent.md`
- `.claude/agents/memory/deep-research/afk-code-safety-reliability-2026-02-05.md`
- `.claude/agents/memory/deep-research/vestige-research-2026-02-05.md`
- `.claude/commands/example-command.md.backup.20260117_133243`
- `.claude/config/autonomy-config.yaml.backup`
- `.claude/config/credentials.local.yaml`
- `.claude/context/.active-tasks.txt`
- `.claude/context/.capture-complete`
- `.claude/context/.command-output`
- `.claude/context/.ennoia-state`
- `.claude/context/.jicm-config`
- `.claude/context/.jicm-rewrite-log.md`
- `.claude/context/.jicm-standdown`
- `.claude/context/.jicm-status.json`
- `.claude/context/jicm/.current-session-id`
- `.claude/context/jicm/sessions/20260210-010545/decisions.yaml`
- `.claude/context/jicm/sessions/20260210-010545/observations.yaml`
- `.claude/context/jicm/sessions/20260210-010545/working-memory.yaml`
- `.claude/context/jicm/sessions/20260210-082201/decisions.yaml`
- `.claude/context/jicm/sessions/20260210-082201/observations.yaml`
- `.claude/context/jicm/sessions/20260210-082201/working-memory.yaml`
- `.claude/context/jicm/sessions/20260210-082205/decisions.yaml`
- `.claude/context/jicm/sessions/20260210-082205/observations.yaml`
- `.claude/context/jicm/sessions/20260210-082205/working-memory.yaml`
- `.claude/context/jicm/sessions/20260210-145442/decisions.yaml`
- `.claude/context/jicm/sessions/20260210-145442/observations.yaml`
- `.claude/context/jicm/sessions/20260210-145442/working-memory.yaml`
- `.claude/context/jicm/sessions/20260210-145445/decisions.yaml`
- `.claude/context/jicm/sessions/20260210-145445/observations.yaml`
- `.claude/context/jicm/sessions/20260210-145445/working-memory.yaml`
- `.claude/logs/.session-activity`
- `.claude/logs/jarvis-watcher-test.log`
- `.claude/logs/latest`
- `.claude/logs/mcp-validation/testing-mcps-selection.md`
- `.claude/logs/milestone-detector.log`
- `.claude/logs/setup-hook.log`
- `.claude/logs/telemetry/events-2026-01-20.jsonl`
- `.claude/logs/telemetry/events-2026-02-08.jsonl`
- `.claude/logs/telemetry/events-2026-02-09.jsonl`
- `.claude/logs/telemetry/events-2026-02-11.jsonl`
- `.claude/logs/telemetry/events-2026-02-12.jsonl`
- `.claude/plans/hazy-sparking-seahorse.md`
- `.claude/scripts/dev/graph-export.py`
- `.claude/scripts/test-keystroke.sh`
- `.claude/skills/_shared/ooxml/schemas/ISO-IEC29500-4_2016/shared-additionalCharacteristics.xsd`
- `.claude/skills/_shared/ooxml/schemas/ecma/fouth-edition/opc-contentTypes.xsd`
- `.claude/skills/_shared/ooxml/schemas/ecma/fouth-edition/opc-coreProperties.xsd`
- `.claude/skills/_shared/ooxml/schemas/ecma/fouth-edition/opc-digSig.xsd`
- `.claude/skills/_shared/ooxml/schemas/ecma/fouth-edition/opc-relationships.xsd`
- `.claude/skills/_shared/ooxml/scripts/validate.py`
- `.claude/skills/_shared/ooxml/scripts/validation/__init__.py`
- `.claude/skills/_shared/ooxml/scripts/validation/base.py`
- `.claude/skills/_shared/ooxml/scripts/validation/docx.py`
- `.claude/skills/_shared/ooxml/scripts/validation/pptx.py`
- `.claude/skills/_shared/ooxml/scripts/validation/redlining.py`
- `.claude/skills/docx/scripts/__init__.py`
- `.claude/skills/docx/scripts/templates/comments.xml`
- `.claude/skills/docx/scripts/templates/commentsExtended.xml`
- `.claude/skills/docx/scripts/templates/commentsExtensible.xml`
- `.claude/skills/docx/scripts/templates/commentsIds.xml`
- `.claude/skills/docx/scripts/templates/people.xml`
- `.claude/skills/mcp-builder/scripts/connections.py`
- `.claude/skills/mcp-builder/scripts/example_evaluation.xml`
- `.claude/skills/pdf/scripts/check_bounding_boxes_test.py`
- `.claude/skills/pdf/scripts/convert_pdf_to_images.py`
- `.claude/skills/pptx/scripts/thumbnail.py`
- `.claude/skills/skill-creator/references/output-patterns.md`
- `.claude/state/components/setup-hook.json`
- `.mcp.json`
- `projects/mtg-card-sales/Screenshot 2026-01-30 at 4.54.52 PM.png`
- `projects/mtg-card-sales/Screenshot 2026-01-30 at 4.56.04 PM.png`
- `projects/mtg-card-sales/Screenshot 2026-01-30 at 4.56.37 PM.png`
- `projects/mtg-card-sales/Screenshot 2026-01-30 at 4.57.11 PM.png`
- `projects/mtg-card-sales/Screenshot 2026-02-04 at 7.38.35 PM.png`
- `projects/mtg-card-sales/archived/Screenshot 2026-01-30 at 4.20.26 PM.png`
- `projects/mtg-card-sales/archived/Screenshot 2026-01-30 at 4.20.48 PM.png`
- `projects/mtg-card-sales/archived/Screenshot 2026-01-30 at 4.21.07 PM.png`
- `projects/project-aion/evolution/self-improvement/ai_systems_reference.md`
- `projects/project-aion/ideas/Jarvis-Brainstorm-Scratch`
- `projects/project-aion/ideas/Jarvis_Living_Soul`
- `projects/project-aion/ideas/Jarvis_To_Do_Notes`
- `projects/project-aion/ideas/Jarvis_To_Do_Notes.txt`
- `projects/project-aion/ideas/Weather_Location.txt`
- `projects/project-aion/ideas/current/duckduckgo-mcp-research.md`
- `projects/project-aion/reports/archive/ralph-loop-experiment/data/function-comparison.txt`

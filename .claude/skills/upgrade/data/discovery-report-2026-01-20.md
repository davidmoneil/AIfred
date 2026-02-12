# Upgrade Discovery Report

**Date**: 2026-01-20
**Discovered by**: Automated workflow
**Sources checked**: GitHub Releases, Claude Code Docs, Anthropic News

---

## Summary

| Metric | Count |
|--------|-------|
| Total discoveries | 12 |
| New this run | 9 |
| Pending review | 6 |
| Acknowledged | 5 |
| Applied | 1 |

## Version Status

| Component | Baseline | Current | Status |
|-----------|----------|---------|--------|
| Claude Code | 2.1.14 | 2.1.14 | Up to date |

---

## High-Priority Items (Relevance >= 7)

### UP-004: LSP Tool - Language Server Protocol Integration
- **Relevance**: 8/10 | **Impact**: Medium | **Complexity**: Low
- **Source**: github-changelog
- **Summary**: Code intelligence features: go-to-definition, find references, hover documentation. Added in v2.0.74.
- **Current State**: Available but not actively used
- **Recommendation**: Evaluate for code navigation in large projects

### UP-012: Context Window Blocking Limit Fixed
- **Relevance**: 8/10 | **Impact**: High | **Complexity**: None
- **Source**: github-changelog
- **Summary**: Context window blocking limit was too aggressive (~65%), now fixed to ~98%. Fixed in v2.1.14.
- **Status**: Acknowledged - already benefiting from this fix

### UP-005: Claude in Chrome Extension (Beta)
- **Relevance**: 7/10 | **Impact**: Medium | **Complexity**: Low
- **Source**: github-changelog
- **Summary**: Control browser directly from Claude Code via Chrome extension. Added in v2.0.72.
- **Current State**: Using Playwright MCP for browser automation
- **Recommendation**: Compare with Playwright MCP for interactive browser control use cases

### UP-007: Sub-agent Forking for Skills
- **Relevance**: 7/10 | **Impact**: Medium | **Complexity**: Low
- **Source**: github-changelog
- **Summary**: Skills can run in forked sub-agent context with 'context: fork' setting. Added in v2.1.0.
- **Current State**: Not using forked context for skills
- **Recommendation**: Evaluate for parallel-dev and other heavy skills to improve isolation

---

## Medium-Priority Items (Relevance 5-6)

### UP-002: MCP External Data Sources
- **Relevance**: 6/10 | **Impact**: Medium | **Complexity**: Medium
- **Summary**: Docs mention MCP support for Google Drive, Figma, Slack integrations
- **Action**: Evaluate if these MCP servers would be useful for your hub

### UP-009: MCP Donated to Agentic AI Foundation
- **Relevance**: 6/10 | **Impact**: Low | **Complexity**: None
- **Summary**: Anthropic donated MCP to open-source community (Dec 2025)
- **Status**: Acknowledged - industry development to monitor

### UP-003: Native Install with Auto-Updates
- **Relevance**: 5/10 | **Impact**: Low | **Complexity**: Low
- **Summary**: New native installer available with automatic background updates
- **Current State**: Manual install works fine

### UP-006: Automatic Skill Hot-Reload
- **Relevance**: 5/10 | **Impact**: Low | **Complexity**: None
- **Summary**: Skills update immediately without restarting (v2.1.0)
- **Status**: Acknowledged - already benefiting

### UP-010: Plugin Git SHA Pinning
- **Relevance**: 5/10 | **Impact**: Low | **Complexity**: Low
- **Summary**: Pin plugins to specific git commit SHAs for version control
- **Action**: Consider for critical plugins

---

## Low-Priority Items (Relevance < 5)

- **UP-001**: Documentation URL Change (Applied)
- **UP-008**: Language Configuration Setting (Acknowledged - not needed)
- **UP-011**: History-Based Bash Autocomplete (Acknowledged - QoL improvement)

---

## Ecosystem Updates

### Agentic AI Foundation
- MCP donated to open source community (December 9, 2025)
- May lead to more standardized MCP servers and broader ecosystem support

### Recent Claude Model Updates (from Anthropic News)
- Claude Opus 4.5 (Nov 2025) - Enhanced coding and agent capabilities
- Claude Sonnet 4.5 (Sep 2025) - Claude Agent SDK introduced
- Claude Haiku 4.5 (Oct 2025) - Speed and cost efficiency improvements

---

## Recommended Actions

1. **Evaluate LSP Tool** (UP-004) - High potential for code navigation improvement
2. **Test Chrome Extension** (UP-005) - Compare with Playwright MCP for browser tasks
3. **Experiment with Skill Forking** (UP-007) - Could improve parallel-dev isolation
4. **Consider MCP Integrations** (UP-002) - Slack/Drive may have workflow benefits

---

## Next Discovery

Recommended: 1 week from now (2026-01-27)

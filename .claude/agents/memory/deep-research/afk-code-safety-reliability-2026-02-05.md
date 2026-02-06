# AFK Code Safety & Reliability Analysis

**Date**: 2026-02-05  
**Topic**: How AFK Code achieves trustworthy autonomous operation  
**Full Report**: `.claude/reports/research/afk-code-design-philosophy-2026-02-05.md`

## Key Findings

### Design Philosophy
- **Transparency over automation**: Explicit operational boundaries, no hidden safety nets
- **Human-in-the-loop**: All autonomous actions require explicit approval
- **Stateless relay**: JSONL files are system-of-record (no internal state)
- **Intentional constraints**: No plan mode, no tool relay (prevents runaway API usage)

### Safety Patterns
1. **Feature omission as safety**: Deliberate lack of certain features prevents risk
2. **Type safety first**: TypeScript for compile-time error prevention
3. **Trust boundaries**: Security delegated to chat platform IAM
4. **No automated recovery**: Fail-stop rather than fail-safe

### Reliability Patterns
1. **Hybrid file watching**: inotify (fast) + polling (reliable) fallback
2. **PTY event-driven errors**: Error detection via node-pty events
3. **Sequential JSONL guarantees**: Filesystem atomic appends ensure ordering
4. **Platform abstraction**: Pluggable chat platform interfaces

### Critical Gaps
- No message deduplication
- No health monitoring
- No graceful degradation
- No audit logging
- No circuit breakers
- No kill switch mechanism

## Lessons for Jarvis

### Adopt These Patterns
- Explicit safety boundaries documentation
- Hybrid monitoring (fast primary + reliable fallback)
- Type safety for critical paths
- Structured logging (JSON) for observability

### Implement These Gaps
- Message deduplication (context checksum tracking)
- Health reporting endpoint
- Circuit breakers for autonomous actions
- Graceful degradation fallbacks
- Audit trail for all autonomous decisions
- Kill switch for emergency stop

### Advanced Enhancements
- Runtime supervisor (kill switch + circuit breaker + policy engine)
- Voice/TTS notifications for critical states
- Metrics dashboard
- Crash recovery with checkpointing

## Industry Best Practices (2026)

### Autonomous Agent Safety Primitives
1. Kill switch (global hard stop)
2. Circuit breaker (rate limits, spend governors)
3. Pattern detection (anomaly monitoring)
4. Policy evaluation (runtime permissions)
5. Audit logging (immutable action log)

### File Watching Reliability
- inotify for local filesystems (fast)
- Polling for network/NFS/shared filesystems (reliable)
- 5-second polling interval default
- 0.5-second when inotify unavailable
- tail -F with 1-second retry on rotation

### Message Deduplication
- Unique request IDs for every message
- Processed message tracking (in-memory or DB)
- Retention window (1 hour to 1 month based on needs)
- Idempotent handlers (duplicate = no-op)

### Structured Logging
- JSON format for machine parsing
- ISO 8601 timestamps (UTC)
- Correlation IDs for request tracing
- Log enrichment (environment, region, version, commit)
- Tamper-proof storage (encrypted or blockchain)

## Trusted Sources

### Official Documentation
- Anthropic Claude Code Sandboxing (OS-level isolation, 84% fewer prompts)
- Claude Code Hooks (lifecycle event automation)

### Key Libraries
- node-pty (PTY management, not thread-safe)
- node-tail (zero-dependency file tailing with rotation handling)
- say.js (cross-platform TTS for Node.js)

### Design Patterns
- Idempotent consumer pattern (microservices.io)
- Circuit breaker pattern (resilience engineering)
- Runtime supervisor (autonomous agent safety)

## Implementation Priorities

**High Priority**:
1. Structured JSON logging
2. Health reporting
3. Circuit breakers for JICM

**Medium Priority**:
4. Message deduplication
5. Crash recovery checkpoints
6. Audit trail

**Low Priority**:
7. TypeScript migration
8. Voice notifications
9. Runtime supervisor framework

---

**Research Methodology**: Web search + documentation analysis + industry best practices synthesis  
**Confidence Level**: High (cross-referenced multiple authoritative sources)  
**Related Topics**: Claude Code hooks architecture, MCP autonomous patterns, tmux session management

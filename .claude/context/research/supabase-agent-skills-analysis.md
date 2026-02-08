# Supabase Agent Skills Analysis

**Date**: 2026-02-08  
**Repository**: [github.com/supabase/agent-skills](https://github.com/supabase/agent-skills)  
**Stars**: 1.1k | **Status**: Actively maintained | **Format**: Agent Skills Open Standard

## What It Provides

Supabase Agent Skills offers a single, production-focused skill: **supabase-postgres-best-practices**. This is a structured guide of 33+ reference files organized across 8 priority categories (Query Performance, Connection Management, Schema Design, Concurrency, Security/RLS, Data Access Patterns, Monitoring, Advanced Features). Each reference follows a consistent pattern: anti-pattern → best practice → performance metrics → Supabase-specific context.

## Key Patterns for db-ops Skill

### Architecture Patterns
- **Progressive Disclosure**: Lean manifest (SKILL.md, <500 lines) + detailed references (AGENTS.md compiled) + on-demand reference files
- **Prefix-Based Organization**: Query operations (`query-`), connection (`conn-`), security (`security-`) for agent discoverability
- **Impact Levels**: CRITICAL/HIGH/MEDIUM/LOW tagging for agent prioritization and context decisions

### Database Operation Patterns
- **Connection Management**: Pooling strategies, idle timeouts, prepared statements, connection limits
- **Data Operations**: Batch inserts, pagination, upserts, N+1 prevention
- **CRUD Abstractions**: Covered via schema design + security patterns, not as explicit primitives
- **Query Optimization**: Index selection, covering indexes, partial indexes, EXPLAIN analysis
- **Transactions**: Short-duration emphasis, deadlock prevention, advisory locks, SKIP LOCKED

### Multi-Database Abstraction Insights
**Not covered**: Supabase repo focuses exclusively on PostgreSQL. For chroma/supabase/mongodb/sqlite/neo4j/mindsdb:
- Each DB requires separate reference modules (patterns differ significantly)
- Organize via database prefix (e.g., `pg-`, `mongo-`, `sqlite-`, `neo4j-`)
- Share only connection + error handling templates; CRUD/query syntax must be DB-specific
- RLS patterns are PostgreSQL-specific; adapt to MongoDB roles, Neo4j fine-grained auth

## Recommendation

**Adopt the reference file structure** (manifests + priority tagging + anti-pattern pedagogies) but implement **database-specific modules** rather than unified abstractions. Key decisions:

1. **Create db-ops skill with sub-modules**: `pg-*/`, `mongo-*/`, `sqlite-*/`, `neo4j-*/`, `chroma-*/`, `mindsdb-*/`
2. **Shared patterns only**: Error handling, connection lifecycle, credentials management, observability hooks
3. **Omit unified CRUD layer**: Each DB has different transaction semantics and query models; attempting abstraction will fail under pressure

## Sources

- [Supabase Agent Skills GitHub](https://github.com/supabase/agent-skills)
- [Best Practices Skill Structure](https://github.com/supabase/agent-skills/tree/main/skills/supabase-postgres-best-practices)
- [Reference Files Index](https://github.com/supabase/agent-skills/tree/main/skills/supabase-postgres-best-practices/references)

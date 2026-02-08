# Research Report: Context-Engineering-Marketplace Skills & Prompts

**Date**: 2026-02-08
**Scope**: Comprehensive examination of the Agent-Skills-for-Context-Engineering repository, with focus on skills most valuable for context compression, memory management, and session continuity patterns suitable for JICM (Jarvis Integrated Context Manager).

---

## Executive Summary

The **Agent-Skills-for-Context-Engineering** repository by muratcankoylan is a comprehensive, production-grade collection of 13 reusable skills focused on context engineering—the discipline of managing language model context windows effectively. Unlike traditional prompt engineering, context engineering addresses the holistic problem of curating all information competing for a model's limited attention budget: system prompts, tool definitions, retrieved documents, message history, and tool outputs.

For a context management system like JICM that handles compression, memory, and session continuity, three skills emerge as particularly valuable: **context-compression** (production-ready compression strategies), **memory-systems** (layered memory architectures and session continuity patterns), and **context-optimization** (compaction, masking, and caching strategies). These three skills provide direct, implementable techniques for extending effective context capacity while maintaining performance.

The repository's core insight—that context limitations stem from attention mechanics rather than token capacity alone—has profound implications for designing robust context management systems.

---

## 1. Repository Information

**Repository URL**: https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering

**Owner**: muratcankoylan

**Structure**:
```
skills/          # 13 core skill implementations
examples/        # Complete system demonstrations
template/        # Canonical skill template
docs/            # Documentation
researcher/      # Research materials
.claude-plugin/  # Plugin marketplace configuration
```

---

## 2. Complete List of Available Skills/Prompts

### **Foundational Skills (3)**

1. **context-fundamentals**
   - Covers context anatomy and the five components (system prompts, tool definitions, retrieved documents, message history, tool outputs)
   - Introduces the principle of treating context as a finite resource
   - Teaches progressive disclosure pattern

2. **context-degradation**
   - Documents five failure modes: lost-in-middle phenomenon, context poisoning, context distraction, context confusion, and context clash
   - Explains the U-shaped attention curve and 10-40% recall accuracy loss in middle content
   - Identifies degradation as a structural limitation from attention mechanics

3. **context-compression**
   - Three production-ready compression approaches: Anchored Iterative Summarization, Opaque Compression, Regenerative Full Summary
   - Focuses on tokens-per-task metric rather than tokens-per-request
   - Structured summaries maintain 0.7% more tokens with 0.35 quality point improvement

### **Architectural Skills (5)**

4. **multi-agent-patterns**
   - Orchestrator, peer-to-peer, and hierarchical multi-agent designs
   - Patterns for coordinating distributed agents

5. **memory-systems**
   - Layered spectrum: Working Memory → Short-Term Memory → Long-Term Memory → Entity Memory → Temporal Knowledge Graphs
   - File-system-as-memory, Vector RAG with metadata, Knowledge graphs
   - Session continuity through progressive retrieval layers and just-in-time memory loading

6. **tool-design**
   - Building tools effective for agents rather than general-purpose APIs
   - Agent-aware tool design principles

7. **filesystem-context**
   - Dynamic context discovery via file system traversal
   - Techniques for offloading tool outputs, persisting plans, and sub-agent communication
   - Leverages `ls`, `glob`, `grep`, `read_file` patterns for on-demand context retrieval

8. **hosted-agents**
   - Sandboxed VMs with multiplayer support
   - Infrastructure patterns for scalable agent systems

### **Operational Skills (3)**

9. **context-optimization**
   - Four core strategies: Compaction, Observation Masking, KV-Cache Optimization, Context Partitioning
   - Targets 50-70% token reduction through compaction
   - 60-80% reduction in masked observations
   - Decision framework for applying matching techniques

10. **evaluation**
    - Outcome-focused evaluation rubrics (factual accuracy, completeness, citation accuracy, source quality, tool efficiency)
    - LLM-as-Judge and human evaluation methods
    - Degradation testing and complexity stratification
    - The "95% Rule": token usage (80%), tool calls (10%), model choice (5%) explain most variance

11. **advanced-evaluation**
    - LLM-as-Judge techniques for scaling evaluation
    - Advanced metrics for production agent systems

### **Development Methodology (1)**

12. **project-development**
    - LLM project design from ideation through deployment
    - Project structure and workflow patterns

### **Cognitive Architecture (1)**

13. **bdi-mental-states**
    - BDI (Belief-Desire-Intention) ontology for deliberative reasoning
    - Mental state modeling for autonomous agents

---

## 3. Top 5 Most Valuable Skills for JICM Context Management System

Ranked by direct applicability to compression, memory management, and session continuity:

### **1. CONTEXT-COMPRESSION** (Highest Priority)
**Why it's essential**: 
- Provides three production-ready compression strategies directly applicable to JICM's 65% compression target
- **Anchored Iterative Summarization** maintains structured, persistent summaries (session intent, file modifications, decisions, next steps) that prevent silent information loss
- Opaque Compression achieves >99% compression ratios for extreme constraints
- Regenerative Full Summary balances readability with compression

**Key Techniques Extractable**:
- Structured summary formats with dedicated sections
- Incremental merging rather than regenerative compression on cycles 2+
- Tokens-per-task optimization metric to avoid costly re-fetching
- Trade-off analysis between compression ratio and reconstruction fidelity

**Direct JICM Application**: Replace ad-hoc summarization with Anchored Iterative Summarization at 65% trigger point, retaining file paths and decision context to avoid re-reading during decompression.

---

### **2. MEMORY-SYSTEMS** (Critical for Session Continuity)
**Why it's essential**:
- Provides layered architecture for working memory (context window) through long-term persistent storage
- Progressive retrieval layers enable just-in-time memory loading at attention-favored positions
- Directly supports session continuity across boundaries
- Temporal Knowledge Graphs enable time-aware queries

**Key Techniques Extractable**:
- File-system-as-memory pattern: simple hierarchy-based organization with naming conventions
- Vector RAG with metadata for semantic + entity-tagged retrieval
- Knowledge graphs for explicit entity and relationship tracking
- Short-term session-scoped persistence vs. cross-session long-term storage
- Strategic injection placing memories in attention-favored positions (beginning, end)

**Direct JICM Application**: Implement short-term memory store (session-scoped) for working session state, long-term store (persistent) for cross-session patterns. Use file-system-as-memory for simplicity and debuggability. Retrieve memories just-in-time to inject near context boundaries.

---

### **3. CONTEXT-OPTIMIZATION** (Essential for Extended Sessions)
**Why it's essential**:
- Provides framework for four complementary strategies to extend effective context capacity
- Observation Masking directly addresses the 80%+ token consumption from tool outputs
- KV-Cache Optimization offers frontier-model-specific technique for prefix reuse
- Context Partitioning enables isolation strategy for sub-tasks

**Key Techniques Extractable**:
- **Observation Masking**: Replace verbose tool outputs with compact references while maintaining accessibility
- **Compaction**: Prioritize compressing tool outputs > old turns > retrieved documents, preserve system prompt
- **KV-Cache Optimization**: Order context elements (stable content first) to maximize prefix cache hits across requests
- **Context Partitioning**: Split work across isolated sub-agents to avoid context accumulation
- Decision framework: assess what dominates context type, then apply matching technique

**Direct JICM Application**: Combine Observation Masking for tool outputs with Compaction for old turns. Use KV-Cache principles to structure context ordering (stable system prompts/capability definitions first). Implement Context Partitioning for long-running multi-phase tasks.

---

### **4. CONTEXT-DEGRADATION** (Foundation for Robustness)
**Why it's essential**:
- Documents the actual failure modes JICM will encounter during long sessions
- Explains the scientific basis for compression triggers at 70-80% utilization
- Identifies context poisoning risk in repeated reference (critical for memory systems)
- Provides empirical grounding for threshold decisions

**Key Techniques Extractable**:
- **Lost-in-Middle phenomenon**: U-shaped attention curve, 10-40% lower recall in middle, models drop 30+ points at extended contexts
- **Context Poisoning**: Errors compound through repeated reference—accumulation problem
- **Context Distraction**: Irrelevant information competes for attention, models can't skip it
- **Context Confusion**: Irrelevant information influences responses degrading quality
- **Context Clash**: Contradictory guidance derails reasoning

**Direct JICM Application**: Justify compression triggers empirically (70-80% is not arbitrary—it's where U-shaped attention degrades). Implement context poisoning mitigation: verify retrieved memory before re-injection, maintain explicit confidence scores. Use degradation patterns to guide memory pruning strategy.

---

### **5. FILESYSTEM-CONTEXT** (Supporting Pattern for Memory Storage)
**Why it's essential**:
- Provides practical implementation strategy for persistent memory storage outside context window
- Separates static context (always included) from dynamic context (on-demand)
- Leverages frontier LLM's filesystem traversal understanding
- Enables tool output offloading, plan persistence, and sub-agent communication

**Key Techniques Extractable**:
- Static context (loaded once): system prompts, baseline instructions
- Dynamic context (on-demand): tool outputs, session state, memory indices
- Search and retrieval tools: `ls`, `glob`, `grep`, `read_file` with line ranges
- Tool output offloading: write large results (>2000 tokens) to files, provide summaries with file access
- Plan persistence: multi-step task plans stored in structured files for re-reading
- Structural queries for exact-match retrieval (better than semantic search for technical content)

**Direct JICM Application**: Store session-scoped memory in `/Jarvis/.claude/context/jicm/sessions/{session_id}/` with structured YAML/JSON files. Implement `grep`-based index queries for memory retrieval. Offload compressed context blocks to files with summary + file reference pattern.

---

## 4. Key Techniques and Patterns Extractable for JICM

### **Compression Patterns**

1. **Anchored Iterative Summarization**
   - Maintains persistent, structured summaries with sections: session intent, file modifications, decisions, next steps
   - On compression trigger, merge newly-summarized content into existing sections rather than regenerating from scratch
   - Prevents silent information loss by forcing system to populate dedicated sections
   - Favored trade-off: 0.7% more tokens for 0.35 quality points

2. **Tokens-Per-Task Metric**
   - Optimize for total tokens to complete work, not tokens-per-request
   - Aggressive compression losing file paths costs more in re-fetching than tokens saved
   - Structure compression to retain reconstructability

3. **Progressive Disclosure**
   - Load information only when needed rather than pre-loading
   - Mirrors human cognition: retrieve on-demand vs. memorize everything

### **Memory Management Patterns**

4. **Layered Memory Architecture**
   - Working Memory: context window (zero-latency, volatile)
   - Short-Term Memory: session-scoped persistence (database/file system)
   - Long-Term Memory: cross-session permanent storage (key-value/graph)
   - Entity Memory: relationship tracking across interactions
   - Temporal Knowledge Graphs: time-aware fact validity

5. **Just-In-Time Memory Loading**
   - Retrieve relevant memories only when needed
   - Place retrieved memories in attention-favored positions (beginning, end)
   - Minimize idle context consumption

6. **File-System-as-Memory**
   - Simple hierarchy: `/type/identifier/content.format`
   - Named files for structural queries without semantic search
   - Supports `grep`, `ls`, `read_file` for exact-match retrieval

### **Context Optimization Patterns**

7. **Observation Masking**
   - Replace verbose tool outputs with compact references
   - Maintain accessible full content via file links
   - Typical savings: 60-80% of masked observation tokens

8. **KV-Cache Optimization**
   - Order context: stable content (system prompts, tool definitions) first
   - Dynamic content follows
   - Maximizes prefix cache hits across requests sharing identical prefixes

9. **Context Partitioning**
   - Split work across isolated sub-agents
   - Each agent operates in clean context focused on subtask
   - Prevents context accumulation from shared state

### **Session Continuity Patterns**

10. **Progressive Retrieval Layers**
    - First layer: current task context + immediate history
    - Second layer: session-scoped memory (retrieved via index)
    - Third layer: long-term patterns (cross-session, if relevant)
    - Fourth layer: entity relationships (graph queries)

11. **State Archival Pattern**
    - At session boundaries, archive session state to structured file
    - Include: session intent, decisions made, file modifications, session end markers
    - Next session loads archived state to restore context

### **Robustness Patterns**

12. **Degradation Thresholds**
    - Compression trigger: 70-80% utilization (empirically-justified)
    - Safe operating window: 50-70% for most agent workflows
    - Degradation testing: validate at different context sizes

13. **Context Poisoning Mitigation**
    - Verify retrieved memory before re-injection
    - Maintain confidence scores or timestamps
    - Detect contradictory information in memory vs. current state

14. **Lost-in-Middle Avoidance**
    - Place critical information at attention-favored positions (first, last)
    - Avoid burying dependencies in middle of context
    - Use structural markers for agent parsing (not reliant on attention)

---

## 5. Comparison: JICM Integration Scenarios

| Aspect | Compression-Focused | Memory-Focused | Optimization-Focused |
|--------|-------------------|-----------------|----------------------|
| **Primary Skill** | context-compression | memory-systems | context-optimization |
| **Trigger Mechanism** | % utilization reached | Memory query or time | Context type analysis |
| **Output Format** | Anchored summaries | Layered retrieval | Masked observations |
| **Session Continuity** | Via summary archival | Via persistent store | Via sub-agent isolation |
| **Recovery Cost** | Medium (re-read summaries) | Low (direct retrieval) | Medium (reconstructed partition) |
| **Best For** | Long sessions, variable workload | Cross-session patterns | Tool-output-heavy workflows |

---

## 6. Specific Recommendations for JICM

### **1. Adopt Anchored Iterative Summarization**
- **Why**: Directly addresses JICM's 65% compression target while maintaining reconstructability
- **How**: Implement structured summary format with persistent sections (intent, modifications, decisions, next steps)
- **Caveats**: Requires discipline to maintain sections across cycles; initial state must be well-formed

### **2. Implement File-System-as-Memory with Just-In-Time Retrieval**
- **Why**: Leverages existing JICM file structure pattern; enables session continuity without context pollution
- **How**: Store memories in `/Jarvis/.claude/context/jicm/sessions/{session_id}/` with index; retrieve via grep-based queries
- **Caveats**: Requires tool access to filesystem; semantic search less effective than structural queries

### **3. Apply Context Degradation Thresholds Empirically**
- **Why**: Justifies JICM's trigger points with scientific basis; prevents silent quality loss
- **How**: Use 70-80% trigger for compression; implement degradation testing for task-specific validations
- **Caveats**: Different workload types may have different optimal thresholds

### **4. Combine Observation Masking with Compaction**
- **Why**: Addresses 80%+ token consumption from tool outputs; doubles compression effectiveness
- **How**: Mask verbose tool outputs first; then compact old conversation turns and documents
- **Caveats**: Requires maintaining file references; re-fetching cost must be tracked

### **5. Establish Progressive Retrieval Layers**
- **Why**: Enables memory system without forcing all memories into context
- **How**: Tier 1 = current task, Tier 2 = session memory, Tier 3 = long-term patterns, Tier 4 = graph queries
- **Caveats**: Adds complexity; requires clear decision rules for which tier to query

---

## 7. Integration Roadmap for JICM

**Phase 1: Foundation (Compression)**
- Adopt Anchored Iterative Summarization structure
- Implement at 65% trigger
- Validate reconstruction quality

**Phase 2: Memory (Session Continuity)**
- Introduce file-system-as-memory with session scoping
- Implement session state archival at session boundaries
- Add just-in-time retrieval patterns

**Phase 3: Optimization (Extended Sessions)**
- Introduce Observation Masking for tool outputs
- Validate 60-80% reduction in masked observations
- A/B test against compression-only baseline

**Phase 4: Robustness**
- Implement context poisoning detection
- Add degradation testing suite
- Establish task-specific threshold calibration

---

## 8. Sources and References

1. **Repository**: [Agent-Skills-for-Context-Engineering](https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering) by muratcankoylan
2. **Skill Reference**: context-compression (Anchored Iterative Summarization technique)
3. **Skill Reference**: memory-systems (Layered architecture and session continuity)
4. **Skill Reference**: context-optimization (Compaction, Masking, KV-Cache, Partitioning strategies)
5. **Skill Reference**: context-degradation (Failure modes and U-shaped attention curve)
6. **Skill Reference**: context-fundamentals (Core principles and context anatomy)
7. **Skill Reference**: filesystem-context (Dynamic context discovery via file system)
8. **Skill Reference**: evaluation (Evaluation frameworks and degradation testing)

---

## 9. Uncertainties and Knowledge Gaps

1. **Implementation Details**: The SKILL.md files provide high-level strategies but specific code examples are not available in this research. Recommend accessing the repository directly for example implementations.

2. **JICM-Specific Validation**: While these patterns are production-proven, their specific performance within JICM's architecture (with Lean Core, Manifest Router, AC components) requires empirical validation.

3. **Trade-off Calibration**: The recommended token reduction percentages (50-70% compaction, 60-80% masking) are general guidance. JICM's specific workload profile may require different calibration.

4. **Cross-Skill Integration**: The repository documents individual skills well. The optimal way to combine multiple skills (e.g., compression + masking + memory systems) requires experimental validation.

---

## 10. Related Topics for Future Research

- **KV-Cache Optimization**: Deeper investigation into Claude Opus 4.6 prefix caching implementation details
- **Entity Memory Graphs**: Structured entity relationship tracking for long-running projects
- **Temporal Knowledge Graphs**: Time-aware fact validity for multi-month sessions
- **Advanced Evaluation**: LLM-as-Judge implementation for context effectiveness validation
- **Multi-Agent Patterns**: Orchestrator patterns for splitting JICM across sub-agents
- **Context Marketplace Plugins**: How to integrate additional Claude Code plugins from the marketplace

---

**Report Completed**: 2026-02-08  
**Research Depth**: Comprehensive (13 skills examined, 5 core techniques deep-dived)  
**Confidence Level**: High (primary sources directly examined)

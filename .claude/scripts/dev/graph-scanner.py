#!/usr/bin/env python3
"""
graph-scanner.py — Scan Jarvis filespace for file-to-file references.

Builds a JSON graph of {nodes, edges} by:
1. Indexing all files by basename (resolves partial references)
2. Scanning each text file for path-like patterns (regex + YAML/JSON deep scan)
3. Resolving partial names against the index
4. Running BFS from entry points to find orphans

Output: .claude/context/filespace-graph.json
        .claude/context/filespace-orphans.txt

Usage: python3 graph-scanner.py [--project-dir DIR]
"""

import os
import re
import json
import sys
import yaml  # PyYAML for structured YAML scanning
from collections import defaultdict, deque
from pathlib import Path

# ─── Configuration ─────────────────────────────────────────────────────────
PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.path.expanduser("~/Claude/Jarvis"))

# Entry points for BFS reachability
ENTRY_POINTS = [
    "CLAUDE.md",
    ".claude/context/psyche/_index.md",
    ".claude/context/psyche/nous-map.md",
    ".claude/context/psyche/pneuma-map.md",
    ".claude/context/psyche/soma-map.md",
    ".claude/context/psyche/capability-map.yaml",
    ".claude/context/components/orchestration-overview.md",
    ".claude/context/current-priorities.md",
    ".claude/context/session-state.md",
    ".claude/skills/_index.md",
    ".claude/commands/README.md",
    ".claude/agents/README.md",
    ".claude/context/patterns/_index.md",
    ".claude/settings.json",
    ".mcp.json",
]

# Directories to scan (relative to PROJECT_DIR)
SCAN_DIRS = [
    ".claude/context",
    ".claude/skills",
    ".claude/commands",
    ".claude/agents",
    ".claude/hooks",
    ".claude/scripts",
    ".claude/tests",
    ".claude/state",
    ".claude/plans",
    ".claude/config",
    ".claude/context/psyche",
    ".claude/context/patterns",
    ".claude/context/designs",
    ".claude/context/components",
    ".claude/context/knowledge",
    ".claude/context/reference",
    ".claude/context/troubleshooting",
    ".claude/context/lessons",
    ".claude/context/jicm",
    ".claude/logs",
    ".claude/evolution",
    "projects",
]

# File extensions to scan content of
TEXT_EXTENSIONS = {".md", ".yaml", ".yml", ".json", ".sh", ".js", ".py", ".txt", ".jsonl", ".xsd"}

# Binary/large files to skip content scanning
SKIP_PATTERNS = {".git", "node_modules", "__pycache__", ".DS_Store", "secrets"}

# Files to exclude from graph entirely (scanner outputs, generated data)
EXCLUDE_FILES = {
    ".claude/context/filespace-graph.json",
    ".claude/context/filespace-orphans.txt",
    ".claude/context/filespace-analysis.json",
    ".claude/context/filespace-analysis-report.md",
    ".claude/logs/file-access.json",       # Virgil tracker output (huge out-degree)
    "jarvis_graph.md",                      # Old ChatGPT graph attempt
}

# Directories to exclude entirely from graph (exports, generated)
EXCLUDE_DIRS = {
    ".claude/context/exports",
}

# Regex patterns for file references
PATH_PATTERNS = [
    # Full relative paths: .claude/context/foo.md
    re.compile(r'\.claude/[a-zA-Z0-9_\-/]+\.[a-zA-Z]{1,5}'),
    # @path references: @.claude/scripts/foo.sh
    re.compile(r'@\.claude/[a-zA-Z0-9_\-/]+\.[a-zA-Z]{1,5}'),
    # Bare filenames with extensions: foo-bar.md, some_script.sh
    re.compile(r'(?<![/\w])([a-zA-Z][a-zA-Z0-9_\-]+\.(?:md|sh|js|yaml|yml|json|py|txt|xsd))\b'),
    # Home dir paths: ~/.claude/foo
    re.compile(r'~/\.claude/[a-zA-Z0-9_\-/]+\.[a-zA-Z]{1,5}'),
    # CLAUDE.md (root file)
    re.compile(r'\bCLAUDE\.md\b'),
    # VERSION file
    re.compile(r'\bVERSION\b'),
    # projects/ paths: projects/project-aion/foo.md
    re.compile(r'projects/[a-zA-Z0-9_\-/]+\.[a-zA-Z]{1,5}'),
    # Markdown link targets: [text](path) — extract the path
    re.compile(r'\]\(([a-zA-Z0-9_\-./]+\.(?:md|sh|js|yaml|yml|json|py|txt))\)'),
    # YAML/JSON "file:" or "script:" keys with path values
    re.compile(r'(?:file|script|hook|command|skill):\s*["\']?(\.[a-zA-Z0-9_\-/]+\.[a-zA-Z]{1,5})'),
    # Directory-relative references: ./foo.md, ../foo/bar.md
    re.compile(r'(?<!\w)\./[a-zA-Z0-9_\-/]+\.[a-zA-Z]{1,5}'),
    # Directory references with trailing slash: patterns/, standards/, components/
    re.compile(r'(?<![.\w])([a-zA-Z][a-zA-Z0-9_\-]+)/(?=\s|$|\n|\|)'),
    # Markdown table directory refs: | patterns/ | or | `patterns/` |
    re.compile(r'[|`]\s*([a-zA-Z][a-zA-Z0-9_\-]+)/\s*[|`]'),
    # Code block directory: ├── patterns/  or └── components/
    re.compile(r'[├└─│]\s*([a-zA-Z][a-zA-Z0-9_\-]+)/'),
    # Markdown link to directory: [text](dir/) or [dir](dir/)
    re.compile(r'\]\(([a-zA-Z0-9_\-./]+)/\)'),
    # Skill absorption references: [docx](docx/SKILL.md) style from _index.md
    re.compile(r'\]\(([a-zA-Z0-9_\-]+/SKILL\.md)\)'),
]


def should_skip(path: str, project_dir: str = "") -> bool:
    """Check if path should be skipped."""
    for skip in SKIP_PATTERNS:
        if skip in path:
            return True
    # Check against EXCLUDE_DIRS using relative path
    rel = path
    if project_dir and path.startswith(project_dir):
        rel = os.path.relpath(path, project_dir)
    for excl_dir in EXCLUDE_DIRS:
        if rel.startswith(excl_dir) or ('/' + excl_dir + '/') in ('/' + rel):
            return True
    return False


def collect_files(project_dir: str) -> dict:
    """Collect all files, build basename -> [full_paths] index."""
    all_files = {}  # relative_path -> True
    basename_index = defaultdict(list)  # basename -> [relative_paths]

    for scan_dir in SCAN_DIRS:
        abs_dir = os.path.join(project_dir, scan_dir)
        if not os.path.isdir(abs_dir):
            continue
        for root, dirs, files in os.walk(abs_dir):
            # Filter out skip directories
            dirs[:] = [d for d in dirs if not should_skip(os.path.join(root, d), project_dir)]
            for f in files:
                abs_f = os.path.join(root, f)
                if should_skip(abs_f, project_dir):
                    continue
                abs_path = os.path.join(root, f)
                rel_path = os.path.relpath(abs_path, project_dir)
                if rel_path in EXCLUDE_FILES:
                    continue
                all_files[rel_path] = True
                basename_index[f].append(rel_path)

    # Add root-level files
    for f in os.listdir(project_dir):
        if f.endswith(('.md', '.yaml', '.json', '.txt')):
            rel_path = f
            if rel_path in EXCLUDE_FILES:
                continue
            all_files[rel_path] = True
            basename_index[f].append(rel_path)

    return all_files, basename_index


def extract_references(filepath: str, project_dir: str, basename_index: dict, all_files: dict) -> list:
    """Extract file references from a single file."""
    abs_path = os.path.join(project_dir, filepath)

    # Check extension
    ext = os.path.splitext(filepath)[1].lower()
    if ext not in TEXT_EXTENSIONS:
        return []

    try:
        with open(abs_path, 'r', errors='replace') as f:
            content = f.read()
    except (OSError, IOError):
        return []

    edges = []
    seen_targets = set()

    def add_edge(raw_ref, ref_str):
        """Resolve and add an edge if valid."""
        ref_str = ref_str.lstrip('@').strip().strip('"').strip("'")
        if ref_str == filepath:
            return
        resolved = resolve_reference(ref_str, filepath, basename_index, all_files)
        if resolved and resolved != filepath and resolved not in seen_targets:
            seen_targets.add(resolved)
            edge_type = classify_edge(raw_ref, filepath, resolved)
            edges.append({
                "source": filepath,
                "target": resolved,
                "type": edge_type,
                "raw_ref": raw_ref[:80],
            })

    # Regex-based scanning
    for pattern in PATH_PATTERNS:
        for match in pattern.finditer(content):
            raw_ref = match.group(0)
            # Use capture group if present, else full match
            ref = match.group(1) if match.lastindex else match.group(0)
            add_edge(raw_ref, ref)

    # Structured YAML scanning for file/script/hook keys
    if ext in ('.yaml', '.yml'):
        try:
            docs = list(yaml.safe_load_all(content))
            for doc in docs:
                if doc:
                    _scan_yaml_values(doc, filepath, add_edge)
        except Exception:
            pass

    # Structured JSON scanning for settings.json, .mcp.json
    if ext == '.json' and not ext == '.jsonl':
        try:
            data = json.loads(content)
            _scan_json_values(data, filepath, add_edge)
        except Exception:
            pass

    # Settings.json hook file references (commandPattern -> hook files)
    if filepath == '.claude/settings.json' or filepath.endswith('settings.local.json'):
        try:
            data = json.loads(content)
            for hook_list in data.get('hooks', {}).values():
                if isinstance(hook_list, list):
                    for hook in hook_list:
                        cmd = hook.get('command', '') if isinstance(hook, dict) else ''
                        # Extract .js/.sh file paths from command strings
                        for m in re.finditer(r'[a-zA-Z0-9_\-./]+\.(?:js|sh|py)', cmd):
                            add_edge(cmd[:80], m.group(0))
        except Exception:
            pass

    return edges


def _scan_yaml_values(obj, source_file, add_edge):
    """Recursively scan YAML values for file references."""
    if isinstance(obj, dict):
        for key, val in obj.items():
            if key in ('file', 'script', 'hook', 'command', 'skill', 'replaces'):
                if isinstance(val, str) and ('.' in val or '/' in val):
                    add_edge(f"{key}: {val}", val)
            if key in ('signal_files', 'scripts', 'tools', 'absorbs', 'tags'):
                if isinstance(val, list):
                    for item in val:
                        if isinstance(item, str) and '.' in item:
                            add_edge(f"{key}: {item}", item)
            _scan_yaml_values(val, source_file, add_edge)
    elif isinstance(obj, list):
        for item in obj:
            _scan_yaml_values(item, source_file, add_edge)


def _scan_json_values(obj, source_file, add_edge):
    """Recursively scan JSON values for file path references."""
    if isinstance(obj, dict):
        for key, val in obj.items():
            if isinstance(val, str) and ('.claude/' in val or val.endswith(('.js', '.sh', '.py', '.md'))):
                add_edge(f"{key}: {val}", val)
            _scan_json_values(val, source_file, add_edge)
    elif isinstance(obj, list):
        for item in obj:
            _scan_json_values(item, source_file, add_edge)


def resolve_reference(ref: str, source_file: str, basename_index: dict, all_files: dict) -> str:
    """Resolve a reference string to a full relative path."""
    # Direct match
    if ref in all_files:
        return ref

    # Strip leading ./ or /
    clean = ref.lstrip('./')
    if clean in all_files:
        return clean

    # Home dir expansion (~/.claude/...) — map to relative
    if ref.startswith('~/.claude/'):
        mapped = ref.replace('~/.claude/', '.claude/')
        if mapped in all_files:
            return mapped

    # Resolve relative paths against source dir (./foo.md, ../foo/bar.md, foo/bar.md)
    if '/' in ref:
        source_dir = os.path.dirname(source_file)
        # Explicit relative: ./foo.md, ../foo/bar.md
        if ref.startswith('./') or ref.startswith('../'):
            resolved = os.path.normpath(os.path.join(source_dir, ref))
            if resolved in all_files:
                return resolved
        # Implicit relative: foo/bar.md (no ./ prefix)
        else:
            resolved = os.path.normpath(os.path.join(source_dir, ref))
            if resolved in all_files:
                return resolved
            # Walk up parent directories
            parent = os.path.dirname(source_dir)
            while parent and parent != source_dir:
                resolved = os.path.normpath(os.path.join(parent, ref))
                if resolved in all_files:
                    return resolved
                source_dir = parent
                parent = os.path.dirname(parent)

    # Try with .claude/ prefix if bare path
    if not ref.startswith('.') and not ref.startswith('projects/'):
        prefixed = '.claude/' + ref
        if prefixed in all_files:
            return prefixed

    # Directory reference resolution: patterns/ -> patterns/_index.md or patterns/README.md
    dir_name = ref.rstrip('/')
    is_dir_ref = ref.endswith('/') or ('.' not in os.path.basename(ref) and len(ref) > 2)
    if is_dir_ref and dir_name:
        # Strategy 1: Direct path
        for index_name in ['_index.md', 'README.md', 'SKILL.md']:
            candidate = dir_name + '/' + index_name
            if candidate in all_files:
                return candidate

        # Strategy 2: With common prefixes
        for prefix in ['.claude/', '.claude/context/', '.claude/skills/',
                       '.claude/agents/', 'projects/', 'projects/project-aion/']:
            for index_name in ['_index.md', 'README.md', 'SKILL.md']:
                candidate = prefix + dir_name + '/' + index_name
                if candidate in all_files:
                    return candidate

        # Strategy 3: Relative to source file directory (and ancestors)
        source_dir = os.path.dirname(source_file)
        while source_dir:
            for index_name in ['_index.md', 'README.md', 'SKILL.md']:
                candidate = os.path.normpath(os.path.join(source_dir, dir_name, index_name))
                if candidate in all_files:
                    return candidate
            parent = os.path.dirname(source_dir)
            if parent == source_dir:
                break
            source_dir = parent

        # Strategy 4: Search all files for matching directory name
        for index_name in ['_index.md', 'README.md', 'SKILL.md']:
            if index_name in basename_index:
                for cand in basename_index[index_name]:
                    if '/' + dir_name + '/' in cand or cand.startswith(dir_name + '/'):
                        return cand

    # Basename lookup
    basename = os.path.basename(ref)
    if basename in basename_index:
        candidates = basename_index[basename]
        if len(candidates) == 1:
            return candidates[0]
        # Multiple candidates — try path similarity
        source_dir = os.path.dirname(source_file)
        # Best: same directory
        for cand in candidates:
            if os.path.dirname(cand) == source_dir:
                return cand
        # Good: source dir is a parent of candidate
        for cand in candidates:
            if source_dir in cand:
                return cand
        # OK: partial path overlap with ref
        if '/' in ref:
            ref_parts = ref.split('/')
            best_score = 0
            best_cand = candidates[0]
            for cand in candidates:
                cand_parts = cand.split('/')
                score = sum(1 for p in ref_parts if p in cand_parts)
                if score > best_score:
                    best_score = score
                    best_cand = cand
            return best_cand
        # Fallback: first candidate
        return candidates[0]

    return None


def classify_edge(raw_ref: str, source: str, target: str) -> str:
    """Classify the type of reference edge."""
    if raw_ref.startswith('@'):
        return "at_reference"

    source_ext = os.path.splitext(source)[1]
    target_ext = os.path.splitext(target)[1]

    # Scripts referencing other scripts
    if source_ext in ('.sh', '.js', '.py') and target_ext in ('.sh', '.js', '.py'):
        return "code_dependency"

    # Scripts referencing data files
    if source_ext in ('.sh', '.js', '.py') and target_ext in ('.md', '.yaml', '.json'):
        return "reads_from"

    # Docs referencing docs
    if source_ext == '.md' and target_ext == '.md':
        return "doc_reference"

    # Docs referencing code
    if source_ext == '.md' and target_ext in ('.sh', '.js', '.py'):
        return "references_code"

    # Config referencing files
    if source_ext in ('.yaml', '.yml', '.json'):
        return "config_reference"

    return "reference"


def bfs_reachability(edges: list, entry_points: list, all_files: dict) -> tuple:
    """BFS from entry points. Returns (reachable, orphans)."""
    # Build adjacency list
    adj = defaultdict(set)
    for edge in edges:
        adj[edge["source"]].add(edge["target"])

    # BFS
    visited = set()
    queue = deque()
    for ep in entry_points:
        if ep in all_files:
            queue.append(ep)
            visited.add(ep)

    while queue:
        node = queue.popleft()
        for neighbor in adj[node]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)

    orphans = sorted(set(all_files.keys()) - visited)
    return visited, orphans


def compute_stats(all_files, edges, reachable, orphans, basename_index):
    """Compute graph statistics."""
    # In-degree and out-degree
    in_degree = defaultdict(int)
    out_degree = defaultdict(int)
    for edge in edges:
        out_degree[edge["source"]] += 1
        in_degree[edge["target"]] += 1

    # Files with no incoming references (potential missing targets)
    no_incoming = [f for f in all_files if in_degree[f] == 0 and f not in ENTRY_POINTS]

    # Files with no outgoing references (leaf nodes or scripts)
    no_outgoing = [f for f in all_files if out_degree[f] == 0]

    # Ambiguous basenames (multiple files with same name)
    ambiguous = {k: v for k, v in basename_index.items() if len(v) > 1}

    return {
        "total_files": len(all_files),
        "total_edges": len(edges),
        "reachable": len(reachable),
        "orphans": len(orphans),
        "no_incoming": len(no_incoming),
        "no_outgoing": len(no_outgoing),
        "ambiguous_basenames": len(ambiguous),
        "entry_points_found": sum(1 for ep in ENTRY_POINTS if ep in all_files),
    }


def main():
    project_dir = PROJECT_DIR
    if len(sys.argv) > 1 and sys.argv[1] == "--project-dir":
        project_dir = sys.argv[2]

    print(f"Scanning: {project_dir}")
    print()

    # Phase 1: Collect all files
    all_files, basename_index = collect_files(project_dir)
    print(f"Files indexed: {len(all_files)}")
    print(f"Unique basenames: {len(basename_index)}")

    # Phase 2: Extract references
    all_edges = []
    for filepath in sorted(all_files.keys()):
        edges = extract_references(filepath, project_dir, basename_index, all_files)
        all_edges.extend(edges)

    print(f"Edges found: {len(all_edges)}")

    # Deduplicate edges
    seen = set()
    unique_edges = []
    for edge in all_edges:
        key = (edge["source"], edge["target"])
        if key not in seen:
            seen.add(key)
            unique_edges.append(edge)

    print(f"Unique edges: {len(unique_edges)}")

    # Phase 3: BFS reachability
    reachable, orphans = bfs_reachability(unique_edges, ENTRY_POINTS, all_files)
    stats = compute_stats(all_files, unique_edges, reachable, orphans, basename_index)

    print()
    print("=== Graph Statistics ===")
    for k, v in stats.items():
        print(f"  {k}: {v}")
    print()
    print(f"Reachability: {stats['reachable']}/{stats['total_files']} ({100*stats['reachable']//stats['total_files']}%)")
    print(f"Orphans: {stats['orphans']}")

    # Phase 4: Write outputs
    output_dir = os.path.join(project_dir, ".claude", "context")

    # JSON graph
    graph = {
        "metadata": {
            "scanner": "graph-scanner.py",
            "project_dir": project_dir,
            "stats": stats,
            "entry_points": [ep for ep in ENTRY_POINTS if ep in all_files],
        },
        "nodes": sorted(all_files.keys()),
        "edges": unique_edges,
    }

    graph_path = os.path.join(output_dir, "filespace-graph.json")
    with open(graph_path, 'w') as f:
        json.dump(graph, f, indent=2)
    print(f"\nGraph written: {graph_path}")

    # Orphans list
    orphan_path = os.path.join(output_dir, "filespace-orphans.txt")
    with open(orphan_path, 'w') as f:
        f.write(f"# Filespace Orphans — unreachable from entry points\n")
        f.write(f"# Total: {len(orphans)} / {len(all_files)} files\n")
        f.write(f"# Entry points: {', '.join(ep for ep in ENTRY_POINTS if ep in all_files)}\n\n")
        for orphan in orphans:
            # Check if it has any edges at all
            has_edges = any(e["source"] == orphan or e["target"] == orphan for e in unique_edges)
            marker = " (has edges but unreachable)" if has_edges else " (isolated)"
            f.write(f"{orphan}{marker}\n")
    print(f"Orphans written: {orphan_path}")

    # Edge type breakdown
    type_counts = defaultdict(int)
    for edge in unique_edges:
        type_counts[edge["type"]] += 1
    print("\nEdge types:")
    for t, c in sorted(type_counts.items(), key=lambda x: -x[1]):
        print(f"  {t}: {c}")

    # Print some orphans
    if orphans:
        print(f"\nSample orphans (first 20):")
        for o in orphans[:20]:
            print(f"  {o}")
        if len(orphans) > 20:
            print(f"  ... and {len(orphans) - 20} more")


if __name__ == "__main__":
    main()

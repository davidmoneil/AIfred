#!/usr/bin/env python3
"""
network-analysis.py — Compute network metrics on the Jarvis filespace graph.

Reads: .claude/context/filespace-graph.json
Writes: .claude/context/filespace-analysis.json
        .claude/context/filespace-analysis-report.md

Metrics: degree centrality, betweenness centrality, PageRank, HITS,
         strongly/weakly connected components, isolated subgraphs,
         bridge nodes, clustering coefficient.
"""

import os
import json
import sys
from collections import defaultdict

try:
    import networkx as nx
except ImportError:
    print("ERROR: networkx required. Install with: pip3 install networkx")
    sys.exit(1)

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.path.expanduser("~/Claude/Jarvis"))
GRAPH_FILE = os.path.join(PROJECT_DIR, ".claude/context/filespace-graph.json")
OUTPUT_JSON = os.path.join(PROJECT_DIR, ".claude/context/filespace-analysis.json")
OUTPUT_MD = os.path.join(PROJECT_DIR, ".claude/context/filespace-analysis-report.md")


def load_graph():
    """Load graph from JSON and build networkx DiGraph."""
    with open(GRAPH_FILE) as f:
        data = json.load(f)

    G = nx.DiGraph()

    # Add all nodes with directory-layer attribute
    for node in data["nodes"]:
        parts = node.split('/')
        if node.startswith('.claude/context/'):
            layer = "nous"
        elif node.startswith('.claude/') and not node.startswith('.claude/context/'):
            layer = "pneuma"
        elif node.startswith('projects/'):
            layer = "soma-projects"
        else:
            layer = "root"

        # Finer sublayer
        sublayer = '/'.join(parts[:3]) if len(parts) >= 3 else '/'.join(parts[:2]) if len(parts) >= 2 else parts[0]

        G.add_node(node, layer=layer, sublayer=sublayer)

    # Add directed edges (source references target)
    for edge in data["edges"]:
        G.add_edge(edge["source"], edge["target"],
                   edge_type=edge["type"],
                   raw_ref=edge.get("raw_ref", ""))

    return G, data


def compute_metrics(G):
    """Compute all network metrics."""
    metrics = {}

    print("Computing degree centrality...")
    in_deg = dict(G.in_degree())
    out_deg = dict(G.out_degree())
    metrics["in_degree"] = in_deg
    metrics["out_degree"] = out_deg

    # Normalized degree centrality
    n = G.number_of_nodes()
    if n > 1:
        metrics["in_degree_centrality"] = {k: v / (n - 1) for k, v in in_deg.items()}
        metrics["out_degree_centrality"] = {k: v / (n - 1) for k, v in out_deg.items()}
    else:
        metrics["in_degree_centrality"] = in_deg
        metrics["out_degree_centrality"] = out_deg

    print("Computing PageRank...")
    try:
        metrics["pagerank"] = nx.pagerank(G, alpha=0.85, max_iter=200)
    except Exception as e:
        print(f"  PageRank failed: {e}")
        metrics["pagerank"] = {}

    print("Computing betweenness centrality (may take a moment)...")
    try:
        # Use k-sampling for large graphs
        k = min(100, n) if n > 200 else None
        metrics["betweenness"] = nx.betweenness_centrality(G, k=k, normalized=True)
    except Exception as e:
        print(f"  Betweenness failed: {e}")
        metrics["betweenness"] = {}

    print("Computing HITS (hub/authority scores)...")
    try:
        hubs, authorities = nx.hits(G, max_iter=200, normalized=True)
        metrics["hub_scores"] = hubs
        metrics["authority_scores"] = authorities
    except Exception as e:
        print(f"  HITS failed: {e}")
        metrics["hub_scores"] = {}
        metrics["authority_scores"] = {}

    print("Computing connected components...")
    # Weakly connected (ignoring direction)
    wcc = list(nx.weakly_connected_components(G))
    metrics["weakly_connected_components"] = len(wcc)
    metrics["wcc_sizes"] = sorted([len(c) for c in wcc], reverse=True)
    metrics["wcc_members"] = {f"wcc_{i}": sorted(list(c)) for i, c in enumerate(wcc)}

    # Strongly connected (respecting direction)
    scc = list(nx.strongly_connected_components(G))
    metrics["strongly_connected_components"] = len(scc)
    metrics["scc_sizes"] = sorted([len(c) for c in scc], reverse=True)
    # Only store SCCs with >1 member (mutual reference clusters)
    metrics["scc_nontrivial"] = {
        f"scc_{i}": sorted(list(c))
        for i, c in enumerate(scc) if len(c) > 1
    }

    print("Computing graph density and diameter...")
    metrics["density"] = nx.density(G)
    metrics["nodes"] = G.number_of_nodes()
    metrics["edges"] = G.number_of_edges()

    # Average clustering (undirected view)
    U = G.to_undirected()
    try:
        metrics["avg_clustering"] = nx.average_clustering(U)
    except Exception:
        metrics["avg_clustering"] = 0.0

    # Isolated nodes (no edges at all)
    isolates = list(nx.isolates(G))
    metrics["isolated_nodes"] = isolates
    metrics["isolated_count"] = len(isolates)

    # Bridge detection (on undirected view)
    print("Computing bridges...")
    try:
        bridges = list(nx.bridges(U))
        metrics["bridges_count"] = len(bridges)
        metrics["bridges"] = bridges[:50]  # Top 50 bridges
    except Exception:
        metrics["bridges_count"] = 0
        metrics["bridges"] = []

    # Edge type distribution
    edge_types = defaultdict(int)
    for _, _, d in G.edges(data=True):
        edge_types[d.get("edge_type", "unknown")] += 1
    metrics["edge_type_distribution"] = dict(edge_types)

    # Layer distribution
    layer_counts = defaultdict(int)
    for _, d in G.nodes(data=True):
        layer_counts[d.get("layer", "unknown")] += 1
    metrics["layer_distribution"] = dict(layer_counts)

    return metrics


def top_n(metric_dict, n=20, reverse=True):
    """Get top N entries from a metric dict."""
    return sorted(metric_dict.items(), key=lambda x: x[1], reverse=reverse)[:n]


def generate_report(G, metrics):
    """Generate markdown analysis report."""
    lines = []
    lines.append("# Jarvis Filespace — Network Analysis Report\n")
    lines.append(f"**Generated**: {__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
    lines.append(f"**Scanner**: graph-scanner.py (enhanced v2)\n")
    lines.append("")

    # Summary
    lines.append("## Summary\n")
    lines.append(f"| Metric | Value |")
    lines.append(f"|--------|-------|")
    lines.append(f"| Nodes | {metrics['nodes']} |")
    lines.append(f"| Edges | {metrics['edges']} |")
    lines.append(f"| Density | {metrics['density']:.4f} |")
    lines.append(f"| Avg Clustering | {metrics['avg_clustering']:.4f} |")
    lines.append(f"| Weakly Connected Components | {metrics['weakly_connected_components']} |")
    lines.append(f"| Strongly Connected Components | {metrics['strongly_connected_components']} |")
    lines.append(f"| Non-trivial SCCs (mutual refs) | {len(metrics['scc_nontrivial'])} |")
    lines.append(f"| Isolated nodes | {metrics['isolated_count']} |")
    lines.append(f"| Bridges | {metrics['bridges_count']} |")
    lines.append("")

    # Layer distribution
    lines.append("## Layer Distribution\n")
    lines.append("| Layer | Files |")
    lines.append("|-------|-------|")
    for layer, count in sorted(metrics["layer_distribution"].items(), key=lambda x: -x[1]):
        lines.append(f"| {layer} | {count} |")
    lines.append("")

    # Edge type distribution
    lines.append("## Edge Type Distribution\n")
    lines.append("| Type | Count |")
    lines.append("|------|-------|")
    for etype, count in sorted(metrics["edge_type_distribution"].items(), key=lambda x: -x[1]):
        lines.append(f"| {etype} | {count} |")
    lines.append("")

    # Top PageRank
    lines.append("## Top 20 Files by PageRank (most important)\n")
    lines.append("| Rank | File | PageRank |")
    lines.append("|------|------|----------|")
    for i, (node, score) in enumerate(top_n(metrics["pagerank"], 20)):
        lines.append(f"| {i+1} | `{node}` | {score:.6f} |")
    lines.append("")

    # Top in-degree (most referenced)
    lines.append("## Top 20 Files by In-Degree (most referenced)\n")
    lines.append("| Rank | File | In-Degree |")
    lines.append("|------|------|-----------|")
    for i, (node, deg) in enumerate(top_n(metrics["in_degree"], 20)):
        lines.append(f"| {i+1} | `{node}` | {deg} |")
    lines.append("")

    # Top out-degree (most references to others)
    lines.append("## Top 20 Files by Out-Degree (most outgoing references)\n")
    lines.append("| Rank | File | Out-Degree |")
    lines.append("|------|------|------------|")
    for i, (node, deg) in enumerate(top_n(metrics["out_degree"], 20)):
        lines.append(f"| {i+1} | `{node}` | {deg} |")
    lines.append("")

    # Betweenness centrality (bridge files)
    lines.append("## Top 20 Files by Betweenness Centrality (bridge/bottleneck files)\n")
    lines.append("| Rank | File | Betweenness |")
    lines.append("|------|------|-------------|")
    for i, (node, score) in enumerate(top_n(metrics["betweenness"], 20)):
        lines.append(f"| {i+1} | `{node}` | {score:.6f} |")
    lines.append("")

    # Hub scores (files that link to many important files)
    lines.append("## Top 20 Hub Files (link to many important files)\n")
    lines.append("| Rank | File | Hub Score |")
    lines.append("|------|------|-----------|")
    for i, (node, score) in enumerate(top_n(metrics["hub_scores"], 20)):
        lines.append(f"| {i+1} | `{node}` | {score:.6f} |")
    lines.append("")

    # Authority scores (files referenced by many important files)
    lines.append("## Top 20 Authority Files (referenced by many important files)\n")
    lines.append("| Rank | File | Authority Score |")
    lines.append("|------|------|-----------------|")
    for i, (node, score) in enumerate(top_n(metrics["authority_scores"], 20)):
        lines.append(f"| {i+1} | `{node}` | {score:.6f} |")
    lines.append("")

    # Weakly connected component sizes
    lines.append("## Weakly Connected Components\n")
    lines.append(f"Total: {metrics['weakly_connected_components']} components\n")
    lines.append("| Component | Size | Sample Members |")
    lines.append("|-----------|------|----------------|")
    for i, (cid, members) in enumerate(sorted(metrics["wcc_members"].items(), key=lambda x: -len(x[1]))):
        sample = ', '.join(f'`{m}`' for m in members[:3])
        suffix = f"... +{len(members)-3}" if len(members) > 3 else ""
        lines.append(f"| {cid} | {len(members)} | {sample} {suffix} |")
        if i >= 10:
            lines.append(f"| ... | ... | {metrics['weakly_connected_components'] - 11} more components |")
            break
    lines.append("")

    # Non-trivial SCCs (mutual reference clusters)
    lines.append("## Strongly Connected Components (Mutual Reference Clusters)\n")
    lines.append(f"Total non-trivial SCCs: {len(metrics['scc_nontrivial'])}\n")
    for cid, members in sorted(metrics["scc_nontrivial"].items(), key=lambda x: -len(x[1])):
        lines.append(f"### {cid} ({len(members)} files)\n")
        for m in members[:10]:
            lines.append(f"- `{m}`")
        if len(members) > 10:
            lines.append(f"- ... +{len(members)-10} more")
        lines.append("")

    # Isolated nodes
    if metrics["isolated_nodes"]:
        lines.append("## Isolated Nodes (no edges)\n")
        for node in metrics["isolated_nodes"]:
            lines.append(f"- `{node}`")
        lines.append("")

    return '\n'.join(lines)


def main():
    print(f"Loading graph from {GRAPH_FILE}")
    G, data = load_graph()
    print(f"Graph loaded: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges")
    print()

    metrics = compute_metrics(G)

    # Generate report
    print("\nGenerating report...")
    report = generate_report(G, metrics)

    with open(OUTPUT_MD, 'w') as f:
        f.write(report)
    print(f"Report written: {OUTPUT_MD}")

    # Write analysis JSON (store top-N for each metric, not full dicts)
    compact = {
        "summary": {
            "nodes": metrics["nodes"],
            "edges": metrics["edges"],
            "density": metrics["density"],
            "avg_clustering": metrics["avg_clustering"],
            "weakly_connected_components": metrics["weakly_connected_components"],
            "strongly_connected_components": metrics["strongly_connected_components"],
            "nontrivial_scc_count": len(metrics["scc_nontrivial"]),
            "isolated_count": metrics["isolated_count"],
            "bridges_count": metrics["bridges_count"],
        },
        "layer_distribution": metrics["layer_distribution"],
        "edge_type_distribution": metrics["edge_type_distribution"],
        "top_pagerank": top_n(metrics["pagerank"], 30),
        "top_in_degree": top_n(metrics["in_degree"], 30),
        "top_out_degree": top_n(metrics["out_degree"], 30),
        "top_betweenness": top_n(metrics["betweenness"], 30),
        "top_hub_scores": top_n(metrics["hub_scores"], 30),
        "top_authority_scores": top_n(metrics["authority_scores"], 30),
        "wcc_sizes": metrics["wcc_sizes"],
        "scc_sizes": metrics["scc_sizes"],
        "scc_nontrivial": metrics["scc_nontrivial"],
        "isolated_nodes": metrics["isolated_nodes"],
        "bridges_sample": [list(b) for b in metrics["bridges"][:30]],
    }

    with open(OUTPUT_JSON, 'w') as f:
        json.dump(compact, f, indent=2)
    print(f"Analysis JSON written: {OUTPUT_JSON}")


if __name__ == "__main__":
    main()

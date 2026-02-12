#!/usr/bin/env python3
"""
graph-export.py — Export Jarvis filespace graph to multiple visualization formats.

Reads: .claude/context/filespace-graph.json
       .claude/context/filespace-analysis.json

Exports:
  .claude/context/exports/filespace.graphml   — GraphML (Gephi, yEd, Cytoscape)
  .claude/context/exports/filespace.gexf      — GEXF (Gephi native)
  .claude/context/exports/filespace.dot        — DOT (Graphviz)
  .claude/context/exports/filespace-edges.csv  — CSV edge list (any tool)
  .claude/context/exports/filespace-nodes.csv  — CSV node list with metrics
  .claude/context/exports/filespace-d3.json    — D3.js force-directed JSON
  .claude/context/exports/filespace-sigma.json — Sigma.js JSON

Usage: python3 graph-export.py [--project-dir DIR]
"""

import os
import json
import csv
import sys
import math
import xml.etree.ElementTree as ET
from xml.dom import minidom
from collections import defaultdict

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.path.expanduser("~/Claude/Jarvis"))
GRAPH_FILE = os.path.join(PROJECT_DIR, ".claude/context/filespace-graph.json")
ANALYSIS_FILE = os.path.join(PROJECT_DIR, ".claude/context/filespace-analysis.json")
EXPORT_DIR = os.path.join(PROJECT_DIR, ".claude/context/exports")

# Color palette by layer (hex)
LAYER_COLORS = {
    "nous": "#4A90D9",       # Blue — knowledge layer
    "pneuma": "#7B68EE",     # Purple — capability layer
    "soma-projects": "#50C878",  # Green — infrastructure
    "root": "#FF6347",       # Red-orange — root files
}

EDGE_COLORS = {
    "doc_reference": "#888888",
    "config_reference": "#D4A574",
    "reference": "#AAAAAA",
    "references_code": "#66CDAA",
    "reads_from": "#FFD700",
    "code_dependency": "#FF6B6B",
}


def load_data():
    """Load graph and analysis data."""
    with open(GRAPH_FILE) as f:
        graph = json.load(f)

    analysis = {}
    if os.path.exists(ANALYSIS_FILE):
        with open(ANALYSIS_FILE) as f:
            analysis = json.load(f)

    return graph, analysis


def get_node_layer(node):
    """Determine layer for a node."""
    if node.startswith('.claude/context/'):
        return "nous"
    elif node.startswith('.claude/'):
        return "pneuma"
    elif node.startswith('projects/'):
        return "soma-projects"
    return "root"


def get_node_sublayer(node):
    """Get finer sublayer grouping."""
    parts = node.split('/')
    if len(parts) >= 3:
        return '/'.join(parts[:3])
    elif len(parts) >= 2:
        return '/'.join(parts[:2])
    return parts[0]


def build_metric_lookups(analysis):
    """Build fast lookup dicts from analysis data."""
    lookups = {
        "pagerank": {},
        "in_degree": {},
        "out_degree": {},
        "betweenness": {},
    }
    for key in lookups:
        top_key = f"top_{key}"
        if top_key in analysis:
            for node, score in analysis[top_key]:
                lookups[key][node] = score
    return lookups


def export_graphml(graph, metrics, output_path):
    """Export to GraphML format (Gephi, yEd, Cytoscape)."""
    # GraphML namespace
    ns = "http://graphml.graphstruct.org/xmlns"
    ET.register_namespace('', ns)

    root = ET.Element("graphml", xmlns=ns)

    # Define attribute keys
    keys = [
        ("layer", "node", "string"),
        ("sublayer", "node", "string"),
        ("pagerank", "node", "double"),
        ("in_degree", "node", "int"),
        ("out_degree", "node", "int"),
        ("betweenness", "node", "double"),
        ("color", "node", "string"),
        ("size", "node", "double"),
        ("edge_type", "edge", "string"),
        ("edge_color", "edge", "string"),
        ("raw_ref", "edge", "string"),
    ]
    for kid, kfor, ktype in keys:
        key_el = ET.SubElement(root, "key", id=kid, attrib={
            "for": kfor, "attr.name": kid, "attr.type": ktype
        })

    g = ET.SubElement(root, "graph", id="jarvis-filespace",
                      edgedefault="directed")

    # Add nodes
    for node in graph["nodes"]:
        n_el = ET.SubElement(g, "node", id=node)
        layer = get_node_layer(node)
        sublayer = get_node_sublayer(node)

        _add_data(n_el, "layer", layer)
        _add_data(n_el, "sublayer", sublayer)
        _add_data(n_el, "color", LAYER_COLORS.get(layer, "#CCCCCC"))
        _add_data(n_el, "pagerank", str(metrics["pagerank"].get(node, 0.0)))
        _add_data(n_el, "in_degree", str(metrics["in_degree"].get(node, 0)))
        _add_data(n_el, "out_degree", str(metrics["out_degree"].get(node, 0)))
        _add_data(n_el, "betweenness", str(metrics["betweenness"].get(node, 0.0)))

        # Size based on PageRank (scaled)
        pr = metrics["pagerank"].get(node, 0.001)
        size = max(5, min(50, pr * 2000))
        _add_data(n_el, "size", f"{size:.1f}")

    # Add edges
    for i, edge in enumerate(graph["edges"]):
        e_el = ET.SubElement(g, "edge", id=f"e{i}",
                             source=edge["source"], target=edge["target"])
        etype = edge.get("type", "reference")
        _add_data(e_el, "edge_type", etype)
        _add_data(e_el, "edge_color", EDGE_COLORS.get(etype, "#CCCCCC"))
        _add_data(e_el, "raw_ref", edge.get("raw_ref", ""))

    # Write
    tree = ET.ElementTree(root)
    tree.write(output_path, xml_declaration=True, encoding="UTF-8")
    print(f"  GraphML: {output_path}")


def _add_data(parent, key, value):
    """Add a data element to GraphML node/edge."""
    d = ET.SubElement(parent, "data", key=key)
    d.text = value


def export_gexf(graph, metrics, output_path):
    """Export to GEXF format (Gephi native)."""
    root = ET.Element("gexf", xmlns="http://gexf.net/1.3",
                      version="1.3")

    meta = ET.SubElement(root, "meta")
    ET.SubElement(meta, "creator").text = "Jarvis graph-export.py"
    ET.SubElement(meta, "description").text = "Jarvis filespace reference graph"

    g = ET.SubElement(root, "graph", defaultedgetype="directed", mode="static")

    # Node attributes
    attrs_node = ET.SubElement(g, "attributes", attrib={"class": "node", "mode": "static"})
    for aid, atype in [("layer", "string"), ("sublayer", "string"),
                       ("pagerank", "float"), ("betweenness", "float"),
                       ("in_degree", "integer"), ("out_degree", "integer")]:
        ET.SubElement(attrs_node, "attribute", id=aid, title=aid, type=atype)

    # Edge attributes
    attrs_edge = ET.SubElement(g, "attributes", attrib={"class": "edge", "mode": "static"})
    ET.SubElement(attrs_edge, "attribute", id="edge_type", title="edge_type", type="string")

    # Nodes
    nodes_el = ET.SubElement(g, "nodes")
    for node in graph["nodes"]:
        layer = get_node_layer(node)
        n_el = ET.SubElement(nodes_el, "node", id=node, label=os.path.basename(node))

        # Color
        color = LAYER_COLORS.get(layer, "#CCCCCC")
        r, gg, b = int(color[1:3], 16), int(color[3:5], 16), int(color[5:7], 16)

        viz_ns = "http://gexf.net/1.3/viz"
        color_el = ET.SubElement(n_el, f"{{{viz_ns}}}color", r=str(r), g=str(gg), b=str(b))

        pr = metrics["pagerank"].get(node, 0.001)
        size = max(3, min(30, pr * 1500))
        ET.SubElement(n_el, f"{{{viz_ns}}}size", value=f"{size:.1f}")

        attvals = ET.SubElement(n_el, "attvalues")
        ET.SubElement(attvals, "attvalue", attrib={"for": "layer", "value": layer})
        ET.SubElement(attvals, "attvalue", attrib={"for": "sublayer", "value": get_node_sublayer(node)})
        ET.SubElement(attvals, "attvalue", attrib={"for": "pagerank", "value": str(metrics["pagerank"].get(node, 0))})
        ET.SubElement(attvals, "attvalue", attrib={"for": "betweenness", "value": str(metrics["betweenness"].get(node, 0))})
        ET.SubElement(attvals, "attvalue", attrib={"for": "in_degree", "value": str(metrics["in_degree"].get(node, 0))})
        ET.SubElement(attvals, "attvalue", attrib={"for": "out_degree", "value": str(metrics["out_degree"].get(node, 0))})

    # Edges
    edges_el = ET.SubElement(g, "edges")
    for i, edge in enumerate(graph["edges"]):
        e_el = ET.SubElement(edges_el, "edge", id=str(i),
                             source=edge["source"], target=edge["target"])
        attvals = ET.SubElement(e_el, "attvalues")
        ET.SubElement(attvals, "attvalue", attrib={"for": "edge_type", "value": edge.get("type", "reference")})

    tree = ET.ElementTree(root)
    tree.write(output_path, xml_declaration=True, encoding="UTF-8")
    print(f"  GEXF:    {output_path}")


def export_dot(graph, metrics, output_path):
    """Export to DOT format (Graphviz)."""
    lines = ['digraph JarvisFilespace {']
    lines.append('  rankdir=LR;')
    lines.append('  node [shape=box, style=filled, fontsize=8];')
    lines.append('  edge [fontsize=6];')
    lines.append('')

    # Group by sublayer
    sublayers = defaultdict(list)
    for node in graph["nodes"]:
        sublayers[get_node_sublayer(node)].append(node)

    # Create subgraphs for clusters
    for i, (sublayer, members) in enumerate(sorted(sublayers.items())):
        layer = get_node_layer(members[0])
        color = LAYER_COLORS.get(layer, "#CCCCCC")

        lines.append(f'  subgraph cluster_{i} {{')
        lines.append(f'    label="{sublayer}";')
        lines.append(f'    style=filled;')
        lines.append(f'    color="{color}20";')
        for node in members:
            safe_id = f'"{node}"'
            label = os.path.basename(node)
            pr = metrics["pagerank"].get(node, 0.001)
            width = max(0.5, min(3.0, pr * 150))
            lines.append(f'    {safe_id} [label="{label}", fillcolor="{color}", width={width:.2f}];')
        lines.append('  }')
        lines.append('')

    # Edges
    for edge in graph["edges"]:
        src = f'"{edge["source"]}"'
        tgt = f'"{edge["target"]}"'
        etype = edge.get("type", "reference")
        ecolor = EDGE_COLORS.get(etype, "#CCCCCC")
        lines.append(f'  {src} -> {tgt} [color="{ecolor}"];')

    lines.append('}')

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines))
    print(f"  DOT:     {output_path}")


def export_csv(graph, metrics, edges_path, nodes_path):
    """Export CSV edge list and node list."""
    # Edge list
    with open(edges_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["source", "target", "edge_type", "raw_ref"])
        for edge in graph["edges"]:
            writer.writerow([
                edge["source"], edge["target"],
                edge.get("type", "reference"),
                edge.get("raw_ref", ""),
            ])
    print(f"  CSV edges: {edges_path}")

    # Node list with metrics
    with open(nodes_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["id", "label", "layer", "sublayer", "pagerank",
                         "in_degree", "out_degree", "betweenness"])
        for node in graph["nodes"]:
            writer.writerow([
                node,
                os.path.basename(node),
                get_node_layer(node),
                get_node_sublayer(node),
                f"{metrics['pagerank'].get(node, 0):.8f}",
                metrics["in_degree"].get(node, 0),
                metrics["out_degree"].get(node, 0),
                f"{metrics['betweenness'].get(node, 0):.8f}",
            ])
    print(f"  CSV nodes: {nodes_path}")


def export_d3_json(graph, metrics, output_path):
    """Export D3.js force-directed graph JSON."""
    nodes = []
    node_index = {}

    for i, node in enumerate(graph["nodes"]):
        node_index[node] = i
        layer = get_node_layer(node)
        pr = metrics["pagerank"].get(node, 0.001)

        nodes.append({
            "id": node,
            "label": os.path.basename(node),
            "group": layer,
            "sublayer": get_node_sublayer(node),
            "pagerank": round(pr, 8),
            "in_degree": metrics["in_degree"].get(node, 0),
            "out_degree": metrics["out_degree"].get(node, 0),
            "betweenness": round(metrics["betweenness"].get(node, 0), 8),
            "radius": max(3, min(25, pr * 1200)),
            "color": LAYER_COLORS.get(layer, "#CCCCCC"),
        })

    links = []
    for edge in graph["edges"]:
        if edge["source"] in node_index and edge["target"] in node_index:
            links.append({
                "source": edge["source"],
                "target": edge["target"],
                "type": edge.get("type", "reference"),
                "color": EDGE_COLORS.get(edge.get("type", "reference"), "#CCCCCC"),
            })

    d3_data = {
        "nodes": nodes,
        "links": links,
        "metadata": {
            "total_nodes": len(nodes),
            "total_links": len(links),
            "layer_colors": LAYER_COLORS,
            "edge_colors": EDGE_COLORS,
        }
    }

    with open(output_path, 'w') as f:
        json.dump(d3_data, f, indent=2)
    print(f"  D3.js:   {output_path}")


def export_sigma_json(graph, metrics, output_path):
    """Export Sigma.js compatible JSON."""
    nodes = []
    for i, node in enumerate(graph["nodes"]):
        layer = get_node_layer(node)
        pr = metrics["pagerank"].get(node, 0.001)

        # Arrange in a circle by sublayer for initial layout
        sublayer = get_node_sublayer(node)
        angle = hash(sublayer) % 360 * math.pi / 180
        radius = 100 + (hash(node) % 200)

        nodes.append({
            "id": node,
            "label": os.path.basename(node),
            "x": radius * math.cos(angle) + (hash(node) % 50),
            "y": radius * math.sin(angle) + (hash(node) % 50),
            "size": max(2, min(20, pr * 1000)),
            "color": LAYER_COLORS.get(layer, "#CCCCCC"),
            "attributes": {
                "layer": layer,
                "sublayer": sublayer,
                "pagerank": round(pr, 8),
                "in_degree": metrics["in_degree"].get(node, 0),
                "out_degree": metrics["out_degree"].get(node, 0),
            }
        })

    edges = []
    for i, edge in enumerate(graph["edges"]):
        edges.append({
            "id": f"e{i}",
            "source": edge["source"],
            "target": edge["target"],
            "color": EDGE_COLORS.get(edge.get("type", "reference"), "#CCCCCC"),
            "type": edge.get("type", "reference"),
        })

    sigma_data = {"nodes": nodes, "edges": edges}

    with open(output_path, 'w') as f:
        json.dump(sigma_data, f, indent=2)
    print(f"  Sigma:   {output_path}")


def main():
    print("Loading graph and analysis data...")
    graph, analysis = load_data()
    metrics = build_metric_lookups(analysis)

    os.makedirs(EXPORT_DIR, exist_ok=True)
    print(f"Exporting to {EXPORT_DIR}/\n")

    export_graphml(graph, metrics,
                   os.path.join(EXPORT_DIR, "filespace.graphml"))
    export_gexf(graph, metrics,
                os.path.join(EXPORT_DIR, "filespace.gexf"))
    export_dot(graph, metrics,
               os.path.join(EXPORT_DIR, "filespace.dot"))
    export_csv(graph, metrics,
               os.path.join(EXPORT_DIR, "filespace-edges.csv"),
               os.path.join(EXPORT_DIR, "filespace-nodes.csv"))
    export_d3_json(graph, metrics,
                   os.path.join(EXPORT_DIR, "filespace-d3.json"))
    export_sigma_json(graph, metrics,
                      os.path.join(EXPORT_DIR, "filespace-sigma.json"))

    print(f"\nAll exports complete. {len(graph['nodes'])} nodes, {len(graph['edges'])} edges.")
    print("\nImport guides:")
    print("  Gephi:     File > Open > filespace.gexf (or .graphml)")
    print("  yEd:       File > Open > filespace.graphml")
    print("  Cytoscape: File > Import > Network > filespace.graphml")
    print("  Graphviz:  dot -Tsvg filespace.dot -o filespace.svg")
    print("  D3.js:     Load filespace-d3.json in force-directed layout")
    print("  Sigma.js:  Load filespace-sigma.json")
    print("  Generic:   filespace-edges.csv + filespace-nodes.csv")


if __name__ == "__main__":
    main()

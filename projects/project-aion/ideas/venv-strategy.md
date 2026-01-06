# Brainstorm: Virtual Environment Strategy

*Created: 2026-01-05*
*Status: Brainstorm / Architecture Question*
*Triggered by: User question about venv for Jarvis and created projects*

---

## Problem Statement

Python virtual environments (venvs) provide dependency isolation. Two questions arise:

1. **Should Jarvis itself have a venv?**
2. **Should projects that Jarvis creates/manages have venvs?**

---

## Current State

### Jarvis Environment

- Jarvis is primarily a **documentation and orchestration hub**
- Most tooling uses:
  - **Node.js** (v24 LTS) for hooks
  - **Bash** for scripts
  - **Claude Code** built-in tools
- Python is used for:
  - Some MCP servers (if installed)
  - Potential future agents
  - Scripts that need Python libraries

Currently no venv exists:
```bash
ls /Users/aircannon/Claude/Jarvis/ | grep -E "venv|.venv"
# (none found)
```

System Python: `3.9.6` (macOS default)

### Project Creation

The `/create-project` command currently:
- Creates directory structure
- Initializes git
- Creates README and CLAUDE.md
- Does NOT create venv

---

## Analysis: Jarvis venv

### Arguments FOR a Jarvis venv

1. **Dependency Isolation**
   - Jarvis-specific Python tools won't pollute system
   - Version pinning for reproducibility
   - Can upgrade packages without system impact

2. **MCP Server Requirements**
   - Some MCP servers require specific Python packages
   - Graphiti, Cognee, and others have dependencies
   - venv keeps these isolated

3. **Reproducibility**
   - `requirements.txt` in repo
   - Fresh clone can recreate exact environment
   - Important for PR-10 (Setup Upgrade) goal: "bring a new machine to baseline-ready"

4. **Best Practice**
   - Standard Python development practice
   - Aligns with professional workflows

### Arguments AGAINST a Jarvis venv

1. **Jarvis is Primarily JavaScript/Documentation**
   - Most hooks are JavaScript
   - Python usage is currently minimal
   - Adding venv overhead for little benefit

2. **Claude Code Handles Tools**
   - Claude Code's built-in tools don't need venv
   - MCP servers are containerized (Docker) or use their own isolation

3. **Complexity**
   - Another thing to maintain
   - Activation needed before Python commands
   - Could confuse the setup process

4. **Current State Works**
   - No Python dependency issues reported
   - System Python + pip --user is working

### Recommendation: Jarvis venv

**Create a venv when needed, not preemptively.**

- Don't create venv during initial `/setup`
- Create when PR-8 (MCP Expansion) requires Python packages
- Add to `00-prerequisites.md` as optional step:

```markdown
### Optional: Python Virtual Environment

If you plan to use Python-based MCP servers or agents:

```bash
cd /Users/aircannon/Claude/Jarvis
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt  # When requirements.txt exists
```
```

---

## Analysis: Project venvs

### Question: Should Jarvis Auto-Create venvs for Projects?

When `/create-project` runs, should it automatically create a venv for Python projects?

### Arguments FOR Auto-Creating Project venvs

1. **Best Practice Enforcement**
   - Every Python project should have a venv
   - Jarvis enforcing this teaches good habits

2. **Isolation by Default**
   - Projects can't interfere with each other
   - No "works on my machine" issues

3. **Reproducibility**
   - Each project has explicit dependencies
   - Fresh checkout + venv = working state

4. **Template Completeness**
   - Project templates should be "ready to use"
   - venv is part of a ready-to-use Python project

### Arguments AGAINST Auto-Creating Project venvs

1. **Not All Projects Need Python**
   - JavaScript/TypeScript projects don't need venv
   - Go, Rust, etc. have their own tooling
   - Over-engineering for non-Python projects

2. **User Preference**
   - Some users prefer Poetry, Conda, or other tools
   - Auto-creating venv may conflict with their workflow

3. **Activation Friction**
   - User must remember to activate
   - Or Jarvis must auto-activate (complex)

4. **Disk Space**
   - venvs can be large
   - Many projects = many venvs

### Recommendation: Project venvs

**Conditional creation based on project type:**

```markdown
## /create-project Behavior

| Project Type | venv Created? | Notes |
|--------------|---------------|-------|
| `--type python-*` | Yes | Create .venv, requirements.txt |
| `--type api` with `--language python` | Yes | |
| `--type web-app` with Python backend | Ask | Some web apps use Node only |
| Non-Python projects | No | Use appropriate tooling |
```

**Implementation in `/create-project`:**

```bash
if [[ "$LANGUAGE" == "python" || "$TYPE" == "python-*" ]]; then
  echo "Creating Python virtual environment..."
  python3 -m venv .venv
  echo "# Project dependencies" > requirements.txt
  echo "Created .venv/ and requirements.txt"
  echo "Activate with: source .venv/bin/activate"
fi
```

---

## Integration with Setup

### `/setup` Phase 0B (Prerequisites)

Add optional venv creation:

```markdown
### Python Environment (Optional)

If you'll use Python-based tools:

1. Verify Python version:
   ```bash
   python3 --version  # Recommend 3.10+
   ```

2. (Optional) Create Jarvis venv:
   ```bash
   python3 -m venv .venv
   ```

3. (If venv created) Add to shell profile:
   ```bash
   alias jarvis-env="source /Users/aircannon/Claude/Jarvis/.venv/bin/activate"
   ```
```

### `/setup-readiness` Check

Add optional venv check (Low priority):

```bash
# Check if venv exists (optional)
if [ -d "$JARVIS_PATH/.venv" ]; then
  echo "║  ✅ Python venv exists                              ║"
else
  echo "║  ⚠️  Python venv not configured (optional)          ║"
fi
```

---

## MCP Server Considerations

### PR-8 MCP Expansion

When installing Python-based MCPs:

1. **Containerized MCPs** (preferred)
   - Run in Docker
   - No venv needed on host
   - Examples: Memory MCP in Docker

2. **Local Python MCPs**
   - Require venv or system packages
   - Should use Jarvis venv if exists
   - Or create MCP-specific venv

**Decision Point for PR-8:**
- Prefer containerized MCPs
- If local Python MCP needed, create venv at that time
- Document in MCP installation procedure

---

## Proposed Strategy Summary

### Jarvis venv

| When | Action |
|------|--------|
| Initial `/setup` | Don't create (not needed yet) |
| PR-8 MCP Expansion | Create if Python MCP needed |
| User requests Python tools | Create on demand |
| `/setup-readiness` | Check as optional (Low) |

### Project venvs

| Project Type | Action |
|--------------|--------|
| Python projects | Auto-create `.venv/` |
| Mixed (Python + JS) | Create if Python detected |
| Non-Python | Don't create |
| User override | `--no-venv` flag to skip |

---

## Implementation Checklist

### For Jarvis venv (PR-8 or later)

- [ ] Add venv creation to prerequisites (optional)
- [ ] Create `requirements.txt` when first Python dependency needed
- [ ] Document activation in CLAUDE.md
- [ ] Add venv check to `/setup-readiness` (optional/Low)

### For Project venvs (PR-2 enhancement or later)

- [ ] Update `/create-project` to detect Python
- [ ] Auto-create venv for Python projects
- [ ] Add `--no-venv` flag option
- [ ] Include `.venv/` in `.gitignore` template
- [ ] Document in project-summary template

---

## Questions for User

1. **Jarvis venv: When to create?**
   - Now: Create during current session
   - PR-8: Create when MCP expansion needs it
   - Never: Rely on system Python

2. **Project venvs: How aggressive?**
   - Always: Create for all projects
   - Smart: Create for Python projects only
   - Never: Let user manage their own

3. **Preferred Python version?**
   - System (3.9.6): Use what's available
   - Specific (3.11+): Enforce modern version
   - pyenv managed: Install multiple versions

4. **venv alternatives?**
   - venv only: Standard library, no extra tools
   - Poetry: Modern dependency management
   - Conda: If data science focus
   - None: Let each project decide

---

## Related Patterns

- **workspace-path-policy.md**: Where projects live
- **mcp-loading-strategy.md**: MCP installation approach
- **setup-validation.md**: Readiness checks

---

*Brainstorm: Virtual Environment Strategy — Jarvis and Projects*

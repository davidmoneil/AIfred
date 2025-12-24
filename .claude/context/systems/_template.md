# [Service Name]

**Purpose**: [One-line description]
**Status**: [Active/Stopped/Degraded]
**Discovered**: [YYYY-MM-DD]

---

## Quick Reference

| Property | Value |
|----------|-------|
| Container | [container-name] |
| Image | [image:tag] |
| Ports | [host:container] |
| URL | [http://...] |

---

## Paths

| Type | Path |
|------|------|
| Config | [path] |
| Data | [path] |
| Logs | [path] |
| Compose | [path] |

---

## Common Commands

```bash
# View logs
docker logs -f [container-name]

# Restart service
docker restart [container-name]

# Check status
docker ps | grep [container-name]
```

---

## Configuration

### Environment Variables
| Variable | Purpose |
|----------|---------|
| VAR_NAME | Description |

### Dependencies
- [Other services this depends on]

---

## Troubleshooting

### [Issue Name]
**Symptom**: What you see
**Fix**: How to resolve

---

## Notes

[Additional context, history, decisions]

---

## Related

- @.claude/context/systems/[related-service].md
- @paths-registry.yaml

---

*Created by AIfred /discover command*

# Authentik Automation Access Pattern

**Purpose**: Allow automation tools (Playwright, scripts, Claude) to access Authentik-protected services without interactive login.

## Quick Reference

| Item | Value |
|------|-------|
| Header Name | `X-Automation-Token` |
| Token Location | `~/.config/automation/authentik-token` |
| Automation User | `automation@theklyx.space` |
| Protected Services | `home.theklyx.space` (more can be added) |

## How It Works

```
┌─────────────────┐     ┌─────────┐     ┌──────────────┐
│ Playwright/Curl │────▶│  Caddy  │────▶│   Service    │
│ + X-Automation- │     │         │     │  (Homepage)  │
│   Token header  │     │ bypass  │     └──────────────┘
└─────────────────┘     │ auth    │
                        └─────────┘

┌─────────────────┐     ┌─────────┐     ┌──────────────┐     ┌──────────────┐
│    Browser      │────▶│  Caddy  │────▶│  Authentik   │────▶│   Service    │
│  (no token)     │     │ forward │     │  (login)     │     │  (Homepage)  │
└─────────────────┘     │ auth    │     └──────────────┘     └──────────────┘
```

## Usage Examples

### curl
```bash
source ~/.config/automation/authentik-token
curl -H "X-Automation-Token: $AUTHENTIK_AUTOMATION_TOKEN" https://home.theklyx.space/
```

### Playwright MCP
When using the Playwright MCP tools, pass the header:
```javascript
// In browser automation prompts, instruct to set header:
"Set extra HTTP header X-Automation-Token with value from ~/.config/automation/authentik-token"
```

### Shell Scripts
```bash
#!/bin/bash
source ~/.config/automation/authentik-token
HEADERS="-H \"X-Automation-Token: $AUTHENTIK_AUTOMATION_TOKEN\""
curl $HEADERS https://home.theklyx.space/api/something
```

## Adding New Protected Services

To protect additional services with automation access:

1. Update the service's Caddyfile block to use the snippet:
   ```caddyfile
   myservice.theklyx.space {
       import security_filters
       import authentik_forward_auth

       reverse_proxy myservice:port
   }
   ```

2. Ensure the service has an Application in Authentik with Proxy Provider

3. Test both paths:
   ```bash
   # Should redirect to login
   curl -I https://myservice.theklyx.space/

   # Should return 200
   curl -H "X-Automation-Token: $TOKEN" https://myservice.theklyx.space/
   ```

## Token Management

### Regenerate Token (if compromised)

```bash
docker exec authentik_server ak shell -c "
from authentik.core.models import Token
token = Token.objects.get(identifier='playwright-automation')
import secrets
token.key = secrets.token_urlsafe(32)
token.save()
print(f'NEW_TOKEN: {token.key}')
"
# Update ~/.config/automation/authentik-token with new value
# Update Caddyfile snippet with new value
# Restart Caddy
```

### Revoke Access

```bash
docker exec authentik_server ak shell -c "
from authentik.core.models import Token
Token.objects.filter(identifier='playwright-automation').delete()
"
```

## Security Considerations

- Token grants full access to protected services as `automation` user
- All requests logged in Caddy access logs (`/var/log/caddy/access.log`)
- Token stored with 600 permissions in `~/.config/automation/`
- Token does not expire (for automation reliability)
- Consider rotating token periodically

## Related Files

- Caddyfile snippet: `/home/davidmoneil/Docker/mydocker/caddy/Caddyfile` (line ~165)
- Token storage: `~/.config/automation/authentik-token`
- Integration plan: `~/.claude/context/projects/authentik-integration-plan.md`

---
argument-hint: <system>
description: Connect to remote system and run health check
skill: infrastructure-ops
note: Requires SSH configured. Add hosts via /setup Phase 8 (Optional Integrations).
allowed-tools:
  - Bash(ssh:*)
  - Read
---

Connect to remote system $ARGUMENTS via SSH and perform health diagnostics.

## Supported Systems

Configure your remote systems in `~/.ssh/config`. Common examples:
- Development servers
- Network equipment (routers, switches)
- Storage systems (NAS)
- Media servers

## Workflow Phases

### Phase 1: Connection Setup
1. Verify system exists in `~/.ssh/config`
2. Test connectivity via SSH
3. Confirm authentication

### Phase 2: System Health Check (OS-appropriate)

**For Linux/Unix**:
```bash
uptime
df -h
free -m
docker ps (if Docker host)
```

**For Windows**:
```powershell
Get-ComputerInfo | Select-Object OsUptime
Get-PSDrive | Where-Object {$_.Provider -like "*FileSystem*"}
```

### Phase 3: Analysis and Reporting
- System uptime, disk space, memory usage
- Key services status
- Flag any issues found

## Usage Examples

```bash
/ssh-connect my-server
/ssh-connect router
/ssh-connect nas
```

## Error Handling

If connection fails:
1. Check system is online (ping test)
2. Verify SSH service running
3. Check firewall rules
4. Confirm credentials in `~/.ssh/config`

## Related

- `/check-service <service>` - Docker service health check
- `/check-health` - Infrastructure health check

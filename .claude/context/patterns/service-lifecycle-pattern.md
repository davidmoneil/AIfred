# Service Lifecycle Management Pattern

**Version**: 1.0.0
**Created**: 2026-01-18
**Source**: Demo A self-assessment (evo-2026-01-029)

---

## Purpose

Standardizes management of ephemeral services (development servers, test databases, etc.) during autonomous work to prevent:
- "Connection refused" errors from stopped services
- Orphan processes consuming resources
- Unclear service state for users

---

## Problem Statement

During autonomous development (e.g., Demo A benchmark), services started for testing don't persist between iterations:
1. Server started for API testing
2. Tests pass, work continues
3. User tries to access server later — "connection refused"

**Root Cause**: No explicit lifecycle management for ephemeral services.

---

## Pattern Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SERVICE LIFECYCLE                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. START                                                            │
│     └── Document startup command                                    │
│     └── Start service (foreground or background)                    │
│     └── Verify service is running                                   │
│                                                                      │
│  2. VERIFY                                                           │
│     └── Health check endpoint or port check                         │
│     └── Log service PID for tracking                                │
│                                                                      │
│  3. PERSIST (choose one)                                             │
│     └── Option A: Background with nohup + log file                  │
│     └── Option B: Document startup command prominently              │
│     └── Option C: Create launchd/systemd service                    │
│                                                                      │
│  4. CLEANUP                                                          │
│     └── Document shutdown command                                   │
│     └── Kill process when work is complete                          │
│     └── Verify port is released                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Implementation Options

### Option A: Background with Logging (Recommended for Dev)

```bash
# Start
cd /path/to/project
nohup npm start > /tmp/project-server.log 2>&1 &
echo $! > /tmp/project-server.pid

# Verify
sleep 2
curl -s http://localhost:3000/health || echo "Server failed to start"

# Check status
if [ -f /tmp/project-server.pid ]; then
    ps -p $(cat /tmp/project-server.pid) > /dev/null && echo "Running" || echo "Stopped"
fi

# Stop
if [ -f /tmp/project-server.pid ]; then
    kill $(cat /tmp/project-server.pid) 2>/dev/null
    rm /tmp/project-server.pid
fi
```

**Pros**: Simple, works everywhere
**Cons**: Doesn't survive system restart

### Option B: Document Prominently

When persistence isn't needed, clearly document how to start the server:

```markdown
## Running the Application

The server is NOT running by default. Start it with:

```bash
cd /path/to/project
npm start
```

Server will be available at http://localhost:3000
```

**Pros**: No orphan processes
**Cons**: Requires manual intervention

### Option C: System Service (Production-like)

For macOS (launchd):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.jarvis.project-server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/node</string>
        <string>/path/to/project/src/index.js</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

**Pros**: Survives restarts, auto-restart on crash
**Cons**: More complex setup

---

## Quick Reference Commands

### Check if port is in use
```bash
lsof -i :PORT
```

### Find process by port
```bash
lsof -t -i :PORT
```

### Kill process on port
```bash
kill $(lsof -t -i :PORT)
```

### Start with nohup
```bash
nohup COMMAND > /tmp/output.log 2>&1 &
```

### Check if process is running
```bash
ps -p PID > /dev/null && echo "Running" || echo "Stopped"
```

---

## Integration with Autonomous Work

### During Wiggum Loop

1. **Before starting service**:
   ```
   Check: lsof -i :PORT
   If busy: Document existing service or choose different port
   ```

2. **After starting service**:
   ```
   Verify: curl health endpoint
   Document: PID and startup command
   ```

3. **At phase completion**:
   ```
   Decide: Persist or document startup
   If persist: nohup + log file
   If document: Add to README or output
   ```

### In Run Reports

Always include service status section:
```markdown
## Services

| Service | Port | Status | Startup Command |
|---------|------|--------|-----------------|
| API Server | 3000 | Stopped | `npm start` |
```

---

## Anti-Patterns

### Don't
- Start server and forget about it
- Assume server persists between sessions
- Leave orphan processes running
- Embed service startup in test scripts without cleanup

### Do
- Document every service started
- Verify service is running before using
- Clean up or explicitly persist
- Include service status in reports

---

## Example: Demo A Application

```bash
# Start (Option A - Background)
cd /Users/aircannon/Claude/aion-hello-console-2026-01-18
nohup npm start > /tmp/aion-hello-console.log 2>&1 &
echo $! > /tmp/aion-hello-console.pid
sleep 2 && curl -s http://localhost:3000/health

# Check
lsof -i :3000

# Stop
kill $(cat /tmp/aion-hello-console.pid)
rm /tmp/aion-hello-console.pid
```

---

## Future Enhancement

Consider creating `/service` command for service management:
```
/service start aion-hello-console
/service stop aion-hello-console
/service status
```

This is tracked as evo-2026-01-029 enhancement.

---

*Service Lifecycle Management Pattern — Jarvis*
*Source: Demo A Self-Assessment 2026-01-18*

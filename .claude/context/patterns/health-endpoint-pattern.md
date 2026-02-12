# Health Endpoint Pattern

Standard contract for service health endpoints in hub infrastructure.

## Overview

All services created through your hub should implement a health endpoint following this pattern. This enables:
- Automated monitoring via `detect-service-issues.sh`
- Integration with Uptime Kuma
- Grafana dashboard compatibility
- Issue escalation to Claude's priority system

## Standard Health Endpoint

### Path
```
GET /api/health
```

### Response Format (Healthy)
```json
{
  "status": "healthy",
  "timestamp": "2026-01-19T12:00:00.000Z",
  "version": "1.0.0",
  "database": {
    "connected": true,
    "details": {}
  }
}
```

### Response Format (Unhealthy)
```json
{
  "status": "unhealthy",
  "timestamp": "2026-01-19T12:00:00.000Z",
  "error": "Database connection failed"
}
```

### Status Values
| Status | HTTP Code | Meaning |
|--------|-----------|---------|
| `healthy` | 200 | All systems operational |
| `degraded` | 200 | Core functionality works, some dependencies down |
| `unhealthy` | 503 | Service cannot function properly |

## Extended Status Endpoint

For detailed diagnostics, implement a full status endpoint:

### Path
```
GET /api/status
```

### Response Format
```json
{
  "status": "healthy",
  "timestamp": "2026-01-19T12:00:00.000Z",
  "version": "1.0.0",
  "api": {
    "healthy": true,
    "port": 8200
  },
  "database": {
    "healthy": true,
    "type": "sqlite",
    "record_count": 42
  },
  "services": {
    "dependency_a": {
      "name": "Dependency A",
      "url": "http://localhost:9000",
      "healthy": true,
      "details": {}
    },
    "dependency_b": {
      "name": "Dependency B",
      "url": "http://external.api.com",
      "healthy": false,
      "error": "Connection timeout"
    }
  }
}
```

## Implementation Examples

### TypeScript/Express
```typescript
router.get('/health', async (req, res) => {
  try {
    // Check database
    const dbOk = await checkDatabase();

    // Check critical dependencies
    const [depA, depB] = await Promise.all([
      checkDependency('http://localhost:9000/health'),
      checkDependency('http://external.api.com/health')
    ]);

    const allHealthy = dbOk && (depA.healthy || depB.healthy);

    res.status(allHealthy ? 200 : 503).json({
      status: allHealthy ? 'healthy' : 'unhealthy',
      timestamp: new Date().toISOString(),
      version: process.env.VERSION || '1.0.0',
      database: { connected: dbOk },
      dependency_a: { healthy: depA.healthy },
      dependency_b: { healthy: depB.healthy }
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});
```

### Python/FastAPI
```python
@app.get("/api/health")
async def health_check():
    try:
        db_ok = await check_database()
        dep_healthy = await check_dependency("http://localhost:9000/health")

        status = "healthy" if db_ok and dep_healthy else "unhealthy"

        return JSONResponse(
            status_code=200 if status == "healthy" else 503,
            content={
                "status": status,
                "timestamp": datetime.utcnow().isoformat(),
                "version": "1.0.0",
                "database": {"connected": db_ok},
                "dependency": {"healthy": dep_healthy}
            }
        )
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "timestamp": datetime.utcnow().isoformat(),
                "error": str(e)
            }
        )
```

## Integration with Service Registry

When implementing a health endpoint, register the service in:
```
.claude/context/registries/service-registry.yaml
```

Example entry:
```yaml
services:
  my-new-service:
    name: "My New Service"
    type: application

    health_endpoint:
      url: http://localhost:8300/api/health
      method: GET
      expected_status: 200
      response_checks:
        - path: $.status
          expected: healthy

    status_endpoint:
      url: http://localhost:8300/api/status

    dependencies:
      required:
        - some-dependency
      optional:
        - another-dependency
```

## Monitoring Integration

### Uptime Kuma
1. Add monitor with URL: `http://localhost:PORT/api/health`
2. Set expected status code: 200
3. Set check interval: 300 seconds (5 minutes)
4. Configure alerts as needed

### Prometheus (if exposing metrics)
Add endpoint:
```
GET /metrics
```

Recommended metrics:
- `service_up` (gauge, 1 = healthy)
- `request_duration_seconds` (histogram)
- `request_total` (counter)

### Grafana
Use Loki logs or Prometheus metrics to create service health dashboard.

## Issue Detection

The `Scripts/detect-service-issues.sh` script:
1. Reads services from `service-registry.yaml`
2. Calls health endpoints
3. Parses responses for nested `healthy: false`
4. Writes issues to `detected-issues.yaml`
5. Claude surfaces these on session start

### Priority Mapping
| Condition | Severity | Claude Priority |
|-----------|----------|-----------------|
| Critical service down | critical | `[X] CRITICAL` |
| Non-critical service down | high | `[!] HIGH` |
| Dependency unhealthy | medium | `[~] MEDIUM` |
| Warning condition | low | `[-] LOW` |

## Best Practices

1. **Fast response**: Health checks should complete in < 5 seconds
2. **No side effects**: Health checks should be read-only
3. **Meaningful errors**: Include actionable error messages
4. **Version info**: Include version for debugging
5. **Dependency status**: Show which dependencies are healthy/unhealthy
6. **Graceful degradation**: Return `degraded` when non-critical deps fail

## Related Files

- `.claude/context/registries/service-registry.yaml` - Service registry
- `.claude/context/registries/detected-issues.yaml` - Detected issues
- `Scripts/detect-service-issues.sh` - Issue detection script
- `Scripts/weekly-health-check.sh` - Weekly infrastructure health check

---

*Created: 2026-01-19*
*Pattern Version: 1.0*

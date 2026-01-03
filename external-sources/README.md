# External Sources

Symlinks to external data. Never store actual data here.

## Structure

- `docker/` - Links to docker-compose files
- `logs/` - Links to important log directories
- `configs/` - Links to external configuration files

## Adding Links

Use the `/link-external` command or manually:

```bash
ln -s /actual/path external-sources/category/link-name
```

Then update `paths-registry.yaml` with the new path.

## Current Links

None configured yet. Links will be added as you:
- Deploy Docker services
- Connect to external systems
- Register configuration files

## Best Practices

1. Always use absolute paths for symlink targets
2. Document the purpose in paths-registry.yaml
3. Test links work before committing
4. Use descriptive names that indicate the source

#!/usr/bin/env node

/**
 * AIfred Profile Loader
 *
 * Reads profile YAML files, merges layers, and generates:
 *   - .claude/settings.json (hook registrations + permissions)
 *   - .claude/config/profile-config.json (runtime config for hooks)
 *
 * Usage:
 *   node scripts/profile-loader.js                           # Load from active-profile.yaml
 *   node scripts/profile-loader.js --layers general,homelab   # Override layers
 *   node scripts/profile-loader.js --add development          # Add a layer
 *   node scripts/profile-loader.js --remove homelab           # Remove a layer
 *   node scripts/profile-loader.js --list                     # Show available profiles
 *   node scripts/profile-loader.js --current                  # Show active layers
 *   node scripts/profile-loader.js --dry-run                  # Preview changes
 */

const fs = require('fs');
const path = require('path');

// ============================================================================
// Minimal YAML Parser (no external dependencies)
// ============================================================================
// Handles the subset of YAML used in profile files: mappings, sequences,
// scalars, comments. Does NOT handle anchors, tags, or multi-line strings.

function parseYaml(text) {
  const lines = text.split('\n');
  return parseMapping(lines, 0, 0).value;
}

function parseMapping(lines, startIdx, baseIndent) {
  const result = {};
  let i = startIdx;

  while (i < lines.length) {
    const line = lines[i];
    const stripped = line.replace(/#.*$/, '').trimEnd();

    if (stripped === '' || stripped.trim() === '') { i++; continue; }

    const indent = line.search(/\S/);
    if (indent < baseIndent) break;
    if (indent > baseIndent && i > startIdx) break;

    const keyMatch = stripped.match(/^(\s*)([^:]+?):\s*(.*)$/);
    if (!keyMatch) { i++; continue; }

    const key = keyMatch[2].trim();
    const inlineValue = keyMatch[3].trim();

    if (inlineValue === '' || inlineValue === '|' || inlineValue === '>') {
      // Check next line for sequence or nested mapping
      const nextNonEmpty = findNextNonEmpty(lines, i + 1);
      if (nextNonEmpty < lines.length) {
        const nextIndent = lines[nextNonEmpty].search(/\S/);
        const nextLine = lines[nextNonEmpty].trim();

        if (nextIndent > indent && nextLine.startsWith('- ')) {
          const seq = parseSequence(lines, nextNonEmpty, nextIndent);
          result[key] = seq.value;
          i = seq.nextIdx;
          continue;
        } else if (nextIndent > indent) {
          const nested = parseMapping(lines, nextNonEmpty, nextIndent);
          result[key] = nested.value;
          i = nested.nextIdx;
          continue;
        }
      }
      result[key] = inlineValue === '' ? null : inlineValue;
      i++;
    } else if (inlineValue.startsWith('[') && inlineValue.endsWith(']')) {
      // Inline array
      const inner = inlineValue.slice(1, -1).trim();
      if (inner === '') {
        result[key] = [];
      } else {
        result[key] = inner.split(',').map(s => parseScalar(s.trim()));
      }
      i++;
    } else if (inlineValue.startsWith('{') && inlineValue.endsWith('}')) {
      // Inline object
      const inner = inlineValue.slice(1, -1).trim();
      if (inner === '') {
        result[key] = {};
      } else {
        result[key] = {};
        inner.split(',').forEach(pair => {
          const [k, v] = pair.split(':').map(s => s.trim());
          if (k) result[key][k] = parseScalar(v || '');
        });
      }
      i++;
    } else {
      result[key] = parseScalar(inlineValue);
      i++;
    }
  }

  return { value: result, nextIdx: i };
}

function parseSequence(lines, startIdx, baseIndent) {
  const result = [];
  let i = startIdx;

  while (i < lines.length) {
    const line = lines[i];
    const stripped = line.replace(/#.*$/, '').trimEnd();

    if (stripped === '' || stripped.trim() === '') { i++; continue; }

    const indent = line.search(/\S/);
    if (indent < baseIndent) break;

    const itemMatch = stripped.match(/^(\s*)-\s*(.*)$/);
    if (!itemMatch || itemMatch[1].length !== baseIndent) break;

    const value = itemMatch[2].trim();

    // Check if value is a quoted string (don't parse colons inside quotes)
    const isQuoted = (value.startsWith('"') && value.endsWith('"')) ||
                     (value.startsWith("'") && value.endsWith("'"));

    if (value === '') {
      result.push(null);
      i++;
    } else if (isQuoted) {
      // Quoted string - treat as scalar even if it contains colons
      result.push(parseScalar(value));
      i++;
    } else if (value.includes(':') && !isQuoted) {
      // Unquoted value with colon - mapping item in sequence
      const obj = {};
      const kvMatch = value.match(/^([^:]+?):\s*(.*)$/);
      if (kvMatch) {
        obj[kvMatch[1].trim()] = parseScalar(kvMatch[2].trim());

        // Check for continuation lines
        const nextNonEmpty = findNextNonEmpty(lines, i + 1);
        if (nextNonEmpty < lines.length) {
          const nextIndent = lines[nextNonEmpty].search(/\S/);
          if (nextIndent > indent + 2 && !lines[nextNonEmpty].trim().startsWith('-')) {
            const nested = parseMapping(lines, nextNonEmpty, nextIndent);
            Object.assign(obj, nested.value);
            i = nested.nextIdx;
            result.push(obj);
            continue;
          }
        }
      }
      result.push(obj);
      i++;
    } else {
      result.push(parseScalar(value));
      i++;
    }
  }

  return { value: result, nextIdx: i };
}

function parseScalar(s) {
  if (s === '' || s === 'null' || s === '~') return null;
  if (s === 'true') return true;
  if (s === 'false') return false;
  if (/^-?\d+$/.test(s)) return parseInt(s, 10);
  if (/^-?\d+\.\d+$/.test(s)) return parseFloat(s);
  // Strip quotes
  if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
    return s.slice(1, -1);
  }
  // Handle string|null pattern from schema
  if (s.includes('|')) return s;
  return s;
}

function findNextNonEmpty(lines, startIdx) {
  let i = startIdx;
  while (i < lines.length) {
    const stripped = lines[i].replace(/#.*$/, '').trim();
    if (stripped !== '') return i;
    i++;
  }
  return i;
}

// ============================================================================
// Paths
// ============================================================================

const ROOT = path.resolve(__dirname, '..');
const PROFILES_DIR = path.join(ROOT, 'profiles');
const ACTIVE_PROFILE_PATH = path.join(ROOT, '.claude', 'config', 'active-profile.yaml');
const SETTINGS_PATH = path.join(ROOT, '.claude', 'settings.json');
const PROFILE_CONFIG_PATH = path.join(ROOT, '.claude', 'config', 'profile-config.json');
const HOOKS_DIR = path.join(ROOT, '.claude', 'hooks');

// ============================================================================
// Profile Loading
// ============================================================================

function loadProfile(name) {
  const filePath = path.join(PROFILES_DIR, `${name}.yaml`);
  if (!fs.existsSync(filePath)) {
    console.error(`Error: Profile "${name}" not found at ${filePath}`);
    process.exit(1);
  }
  const content = fs.readFileSync(filePath, 'utf8');
  return parseYaml(content);
}

function getAvailableProfiles() {
  return fs.readdirSync(PROFILES_DIR)
    .filter(f => f.endsWith('.yaml') && !f.startsWith('_') && f !== 'schema.yaml')
    .map(f => f.replace('.yaml', ''));
}

function loadActiveProfile() {
  if (!fs.existsSync(ACTIVE_PROFILE_PATH)) {
    return null;
  }
  const content = fs.readFileSync(ACTIVE_PROFILE_PATH, 'utf8');
  return parseYaml(content);
}

function saveActiveProfile(layers, config) {
  const dir = path.dirname(ACTIVE_PROFILE_PATH);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  const yamlLines = [
    '# AIfred Active Profile Configuration',
    `# Generated: ${new Date().toISOString()}`,
    '',
    'layers:'
  ];

  layers.forEach(l => yamlLines.push(`  - ${l}`));

  if (config && Object.keys(config).length > 0) {
    yamlLines.push('', 'config:');
    writeYamlObject(config, yamlLines, 2);
  } else {
    yamlLines.push('', 'config: {}');
  }

  fs.writeFileSync(ACTIVE_PROFILE_PATH, yamlLines.join('\n') + '\n');
}

function writeYamlObject(obj, lines, indent) {
  const prefix = ' '.repeat(indent);
  for (const [key, value] of Object.entries(obj)) {
    if (value === null || value === undefined) {
      lines.push(`${prefix}${key}: null`);
    } else if (typeof value === 'object' && !Array.isArray(value)) {
      lines.push(`${prefix}${key}:`);
      writeYamlObject(value, lines, indent + 2);
    } else if (Array.isArray(value)) {
      if (value.length === 0) {
        lines.push(`${prefix}${key}: []`);
      } else {
        lines.push(`${prefix}${key}:`);
        value.forEach(v => lines.push(`${prefix}  - ${JSON.stringify(v)}`));
      }
    } else {
      lines.push(`${prefix}${key}: ${JSON.stringify(value)}`);
    }
  }
}

// ============================================================================
// Merge Logic
// ============================================================================

function mergeProfiles(layers) {
  const merged = {
    hooks: {},
    patterns: { recommended: [], optional: [] },
    skills: { enabled: [] },
    agents: { deploy: [], optional: [] },
    permissions: { allow: [], deny: [] },
    setup_questions: [],
    scripts: { cron: [] }
  };

  const seenQuestionIds = new Set();
  const seenScripts = new Set();

  for (const layerName of layers) {
    const profile = loadProfile(layerName);

    // Hooks: last-write-wins for same hook name
    if (profile.hooks) {
      for (const [hookName, hookConfig] of Object.entries(profile.hooks)) {
        if (hookConfig && hookConfig.enabled !== false) {
          merged.hooks[hookName] = { ...hookConfig, _layer: layerName };
        } else if (hookConfig && hookConfig.enabled === false) {
          delete merged.hooks[hookName];
        }
      }
    }

    // Patterns: union with dedup
    if (profile.patterns) {
      if (profile.patterns.recommended) {
        profile.patterns.recommended.forEach(p => {
          if (!merged.patterns.recommended.includes(p)) merged.patterns.recommended.push(p);
        });
      }
      if (profile.patterns.optional) {
        profile.patterns.optional.forEach(p => {
          if (!merged.patterns.optional.includes(p)) merged.patterns.optional.push(p);
        });
      }
    }

    // Skills: union with dedup
    if (profile.skills && profile.skills.enabled) {
      profile.skills.enabled.forEach(s => {
        if (!merged.skills.enabled.includes(s)) merged.skills.enabled.push(s);
      });
    }

    // Agents: union with dedup
    if (profile.agents) {
      if (profile.agents.deploy) {
        profile.agents.deploy.forEach(a => {
          if (!merged.agents.deploy.includes(a)) merged.agents.deploy.push(a);
        });
      }
      if (profile.agents.optional) {
        profile.agents.optional.forEach(a => {
          if (!merged.agents.optional.includes(a)) merged.agents.optional.push(a);
        });
      }
    }

    // Permissions: union (deny always wins)
    if (profile.permissions) {
      if (profile.permissions.allow) {
        profile.permissions.allow.forEach(p => {
          if (!merged.permissions.allow.includes(p)) merged.permissions.allow.push(p);
        });
      }
      if (profile.permissions.deny) {
        profile.permissions.deny.forEach(p => {
          if (!merged.permissions.deny.includes(p)) merged.permissions.deny.push(p);
        });
      }
    }

    // Setup questions: append, skip dupes
    if (profile.setup_questions) {
      profile.setup_questions.forEach(q => {
        if (q && q.id && !seenQuestionIds.has(q.id)) {
          seenQuestionIds.add(q.id);
          merged.setup_questions.push({ ...q, _layer: layerName });
        }
      });
    }

    // Scripts: append, skip dupes
    if (profile.scripts && profile.scripts.cron) {
      profile.scripts.cron.forEach(s => {
        if (s && s.script && !seenScripts.has(s.script)) {
          seenScripts.add(s.script);
          merged.scripts.cron.push(s);
        }
      });
    }
  }

  return merged;
}

// ============================================================================
// Settings Generation
// ============================================================================

function generateSettings(merged) {
  // Group hooks by event+matcher
  const hookGroups = {};

  for (const [hookName, config] of Object.entries(merged.hooks)) {
    if (!config.event) continue;

    const event = config.event;
    const matcher = config.matcher || null;
    const key = `${event}:${matcher || '__none__'}`;

    if (!hookGroups[key]) {
      hookGroups[key] = { event, matcher, hooks: [] };
    }

    // Verify hook file exists
    const hookFile = path.join(HOOKS_DIR, `${hookName}.js`);
    if (!fs.existsSync(hookFile)) {
      console.warn(`  Warning: Hook file not found: .claude/hooks/${hookName}.js (from profile)`);
    }

    hookGroups[key].hooks.push({
      type: 'command',
      command: `node "$CLAUDE_PROJECT_DIR/.claude/hooks/${hookName}.js"`
    });
  }

  // Build settings.json structure
  const settings = {
    $schema: 'https://json.schemastore.org/claude-code-settings.json',
    description: 'AIfred permissions - generated by profile-loader.js',
    version: '2.2',
    hooks: {},
    permissions: {
      allow: merged.permissions.allow,
      deny: merged.permissions.deny
    }
  };

  // Organize hooks by event
  const eventOrder = [
    'SessionStart', 'PreCompact', 'PreToolUse', 'PostToolUse',
    'UserPromptSubmit', 'Stop', 'SubagentStop', 'Notification'
  ];

  for (const event of eventOrder) {
    const eventGroups = Object.values(hookGroups)
      .filter(g => g.event === event)
      .sort((a, b) => {
        // null matcher first, then alphabetical
        if (!a.matcher && b.matcher) return -1;
        if (a.matcher && !b.matcher) return 1;
        return (a.matcher || '').localeCompare(b.matcher || '');
      });

    if (eventGroups.length === 0) continue;

    settings.hooks[event] = eventGroups.map(group => {
      const entry = { hooks: group.hooks };
      if (group.matcher && group.matcher !== '__none__') {
        entry.matcher = group.matcher;
      }
      return entry;
    });
  }

  return settings;
}

function generateProfileConfig(merged, layers, userConfig) {
  return {
    generated: new Date().toISOString(),
    active_layers: layers,
    hook_config: Object.fromEntries(
      Object.entries(merged.hooks).map(([name, config]) => [
        name,
        { event: config.event, matcher: config.matcher, layer: config._layer }
      ])
    ),
    features: {
      parallel_dev: merged.skills.enabled.includes('parallel-dev'),
      orchestration: merged.skills.enabled.includes('orchestration'),
      infrastructure_ops: merged.skills.enabled.includes('infrastructure-ops'),
      memory_mcp: true // Default, can be overridden by user config
    },
    user_config: userConfig || {}
  };
}

// ============================================================================
// Validation
// ============================================================================

function validateMerged(merged) {
  const issues = [];

  // Check all hooks have files
  for (const hookName of Object.keys(merged.hooks)) {
    const hookFile = path.join(HOOKS_DIR, `${hookName}.js`);
    if (!fs.existsSync(hookFile)) {
      issues.push(`Missing hook: .claude/hooks/${hookName}.js`);
    }
  }

  return issues;
}

// ============================================================================
// CLI
// ============================================================================

function printUsage() {
  console.log(`
AIfred Profile Loader

Usage:
  node scripts/profile-loader.js                           Load from active-profile.yaml
  node scripts/profile-loader.js --layers general,homelab   Override layers
  node scripts/profile-loader.js --add development          Add a layer
  node scripts/profile-loader.js --remove homelab           Remove a layer
  node scripts/profile-loader.js --list                     Show available profiles
  node scripts/profile-loader.js --current                  Show active layers
  node scripts/profile-loader.js --dry-run                  Preview changes
  node scripts/profile-loader.js --help                     Show this help
`);
}

function printList() {
  const available = getAvailableProfiles();
  const active = loadActiveProfile();
  const activeLayers = active ? (active.layers || []) : [];

  console.log('\nAvailable Profiles:');
  console.log('─'.repeat(60));

  for (const name of available) {
    const profile = loadProfile(name);
    const isActive = activeLayers.includes(name);
    const marker = isActive ? ' [active]' : '';
    const hookCount = profile.hooks ? Object.keys(profile.hooks).length : 0;

    console.log(`  ${name}${marker}`);
    console.log(`    ${profile.description || 'No description'}`);
    console.log(`    Hooks: ${hookCount} | Extends: ${profile.extends || 'none'}`);
    console.log('');
  }
}

function printCurrent() {
  const active = loadActiveProfile();
  if (!active) {
    console.log('\nNo active profile. Using default settings.json.');
    console.log('Run: node scripts/profile-loader.js --layers general,homelab');
    return;
  }

  console.log('\nActive Layers:');
  (active.layers || []).forEach((l, i) => {
    console.log(`  ${i + 1}. ${l}`);
  });
}

function printDiff(newSettings) {
  let oldSettings = {};
  if (fs.existsSync(SETTINGS_PATH)) {
    oldSettings = JSON.parse(fs.readFileSync(SETTINGS_PATH, 'utf8'));
  }

  const oldHookCount = countHooks(oldSettings);
  const newHookCount = countHooks(newSettings);
  const oldAllowCount = (oldSettings.permissions?.allow || []).length;
  const newAllowCount = (newSettings.permissions?.allow || []).length;
  const oldDenyCount = (oldSettings.permissions?.deny || []).length;
  const newDenyCount = (newSettings.permissions?.deny || []).length;

  console.log('\nChanges:');
  console.log('─'.repeat(40));
  console.log(`  Hooks:       ${oldHookCount} -> ${newHookCount} (${sign(newHookCount - oldHookCount)})`);
  console.log(`  Allow rules: ${oldAllowCount} -> ${newAllowCount} (${sign(newAllowCount - oldAllowCount)})`);
  console.log(`  Deny rules:  ${oldDenyCount} -> ${newDenyCount} (${sign(newDenyCount - oldDenyCount)})`);
}

function countHooks(settings) {
  let count = 0;
  if (settings.hooks) {
    for (const event of Object.values(settings.hooks)) {
      if (Array.isArray(event)) {
        event.forEach(group => {
          count += (group.hooks || []).length;
        });
      }
    }
  }
  return count;
}

function sign(n) {
  if (n > 0) return `+${n}`;
  if (n < 0) return `${n}`;
  return '0';
}

// ============================================================================
// Main
// ============================================================================

function main() {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    printUsage();
    return;
  }

  if (args.includes('--list')) {
    printList();
    return;
  }

  if (args.includes('--current')) {
    printCurrent();
    return;
  }

  // Determine layers
  let layers = null;
  let userConfig = {};
  const dryRun = args.includes('--dry-run');

  const layersIdx = args.indexOf('--layers');
  if (layersIdx !== -1 && args[layersIdx + 1]) {
    layers = args[layersIdx + 1].split(',').map(s => s.trim());
  }

  const addIdx = args.indexOf('--add');
  if (addIdx !== -1 && args[addIdx + 1]) {
    const active = loadActiveProfile();
    layers = active ? [...(active.layers || ['general'])] : ['general'];
    userConfig = active?.config || {};
    const toAdd = args[addIdx + 1];
    if (!layers.includes(toAdd)) {
      layers.push(toAdd);
    }
  }

  const removeIdx = args.indexOf('--remove');
  if (removeIdx !== -1 && args[removeIdx + 1]) {
    const active = loadActiveProfile();
    layers = active ? [...(active.layers || ['general'])] : ['general'];
    userConfig = active?.config || {};
    const toRemove = args[removeIdx + 1];
    layers = layers.filter(l => l !== toRemove);
    if (layers.length === 0) layers = ['general'];
  }

  if (!layers) {
    const active = loadActiveProfile();
    if (!active) {
      console.log('No active profile found.');
      console.log('Create one with: node scripts/profile-loader.js --layers general,homelab');
      console.log('Or run /setup to configure interactively.');
      return;
    }
    layers = active.layers || ['general'];
    userConfig = active.config || {};
  }

  // Ensure general is first
  if (!layers.includes('general')) {
    layers.unshift('general');
  }

  // Validate profiles exist
  const available = getAvailableProfiles();
  for (const layer of layers) {
    if (!available.includes(layer)) {
      console.error(`Error: Profile "${layer}" not found in profiles/`);
      console.error(`Available: ${available.join(', ')}`);
      process.exit(1);
    }
  }

  console.log(`\nProfile Loader`);
  console.log('─'.repeat(40));
  console.log(`Layers: ${layers.join(' + ')}`);

  // Merge
  const merged = mergeProfiles(layers);

  // Validate
  const issues = validateMerged(merged);
  if (issues.length > 0) {
    console.log('\nValidation warnings:');
    issues.forEach(i => console.log(`  ! ${i}`));
  }

  // Generate
  const settings = generateSettings(merged);
  const profileConfig = generateProfileConfig(merged, layers, userConfig);

  // Summary
  const hookCount = countHooks(settings);
  console.log(`\nGenerated:`);
  console.log(`  Hooks:       ${hookCount} across ${Object.keys(settings.hooks).length} events`);
  console.log(`  Allow rules: ${settings.permissions.allow.length}`);
  console.log(`  Deny rules:  ${settings.permissions.deny.length}`);
  console.log(`  Skills:      ${merged.skills.enabled.join(', ') || 'none'}`);
  console.log(`  Agents:      ${merged.agents.deploy.join(', ') || 'none'}`);

  printDiff(settings);

  if (dryRun) {
    console.log('\n[DRY RUN] Would write:');
    console.log(`  ${SETTINGS_PATH}`);
    console.log(`  ${PROFILE_CONFIG_PATH}`);
    console.log(`  ${ACTIVE_PROFILE_PATH}`);
    console.log('\nGenerated settings.json:');
    console.log(JSON.stringify(settings, null, 2));
    return;
  }

  // Write files
  fs.writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2) + '\n');
  console.log(`\nWrote: .claude/settings.json`);

  const configDir = path.dirname(PROFILE_CONFIG_PATH);
  if (!fs.existsSync(configDir)) {
    fs.mkdirSync(configDir, { recursive: true });
  }
  fs.writeFileSync(PROFILE_CONFIG_PATH, JSON.stringify(profileConfig, null, 2) + '\n');
  console.log(`Wrote: .claude/config/profile-config.json`);

  saveActiveProfile(layers, userConfig);
  console.log(`Wrote: .claude/config/active-profile.yaml`);

  console.log('\nDone. Restart Claude Code for changes to take effect.');
}

main();

#!/usr/bin/env node
/**
 * Document Guard Hook (PreToolUse)
 *
 * Validates file edits against protection policies before allowing changes.
 * Blocks unauthorized modifications to critical infrastructure files.
 *
 * Covers: Edit, Write, mcp__filesystem__edit_file, mcp__filesystem__write_file
 *
 * Config:    .claude/hooks/document-guard.config.js
 * Overrides: .claude/logs/.document-guard-overrides.json
 * Audit:     .claude/logs/document-guard.jsonl
 *
 * Created: 2026-02-08
 * Version: 2.0.0
 */

const fs = require('fs').promises;
const path = require('path');

// --- Constants ---

const PROJECT_DIR = path.resolve(__dirname, '..', '..');
const LOG_DIR = path.join(PROJECT_DIR, '.claude', 'logs');
const OVERRIDE_FILE = path.join(LOG_DIR, '.document-guard-overrides.json');
const AUDIT_FILE = path.join(LOG_DIR, 'document-guard.jsonl');

const EDIT_TOOLS = new Set([
  'Edit', 'Write',
  'mcp__filesystem__edit_file', 'mcp__filesystem__write_file',
]);

// --- Config Cache ---

let configCache = null;
let configMtime = 0;

async function loadConfig() {
  const configPath = path.join(__dirname, 'document-guard.config.js');
  try {
    const stat = await fs.stat(configPath);
    if (stat.mtimeMs !== configMtime) {
      delete require.cache[require.resolve(configPath)];
      configCache = require(configPath);
      configMtime = stat.mtimeMs;
    }
    return configCache;
  } catch (err) {
    console.error('[document-guard] Config load error: ' + err.message);
    return null;
  }
}

// --- Toggle Resolver ---

function resolveToggles(config) {
  var s = config.settings || {};

  // Environment variable override (emergency kill switch)
  var envVal = process.env.DOCUMENT_GUARD_ENABLED;
  if (envVal !== undefined) {
    var envEnabled = envVal !== 'false' && envVal !== '0' && envVal !== '';
    if (!envEnabled) {
      return { masterEnabled: false, v1Enabled: false, credentialScan: false, structuralChecks: false, v2Enabled: false, v2Settings: {} };
    }
  }

  var masterEnabled = s.enabled !== false;
  var v1 = s.v1 || {};
  var v2 = s.v2 || {};

  return {
    masterEnabled: masterEnabled,
    v1Enabled: masterEnabled && v1.enabled !== false,
    credentialScan: masterEnabled && v1.enabled !== false && v1.credentialScan !== false,
    structuralChecks: masterEnabled && v1.enabled !== false && v1.structuralChecks !== false,
    v2Enabled: masterEnabled && v2.enabled === true,
    v2Settings: {
      ollamaUrl: v2.ollamaUrl || 'http://localhost:11434',
      model: v2.model || 'qwen2.5:7b-instruct',
      timeout: v2.timeout || 5000,
      minContentLength: v2.minContentLength || 50,
    },
  };
}

// --- Path Helpers ---

function extractFilePath(toolName, toolInput) {
  if (toolName === 'Edit' || toolName === 'Write') return toolInput?.file_path;
  if (toolName === 'mcp__filesystem__edit_file' || toolName === 'mcp__filesystem__write_file') return toolInput?.path;
  return null;
}

function toRelativePath(absolutePath) {
  if (absolutePath.startsWith(PROJECT_DIR)) {
    return absolutePath.slice(PROJECT_DIR.length).replace(/^\//, '');
  }
  return absolutePath;
}

function toAbsolutePath(filePath) {
  if (path.isAbsolute(filePath)) return filePath;
  return path.join(PROJECT_DIR, filePath);
}

// --- Glob Matching ---

function matchGlob(pattern, filePath) {
  let regex = pattern
    .replace(/[.+^${}()|[\]\\]/g, '\\$&')
    .replace(/\*\*/g, '<<<GLOBSTAR>>>')
    .replace(/\*/g, '[^/]*')
    .replace(/<<<GLOBSTAR>>>/g, '.*')
    .replace(/\?/g, '[^/]');

  if (!pattern.startsWith('.') && !pattern.startsWith('/')) {
    regex = '(?:^|/)' + regex;
  }

  return new RegExp(regex + '$').test(filePath);
}

function patternSpecificity(pattern) {
  return pattern.split('/').filter(function(s) { return !s.includes('*'); }).length;
}

// --- Rule Matching ---

function findMatchingRules(config, relativePath) {
  var matched = [];
  for (var i = 0; i < config.rules.length; i++) {
    if (matchGlob(config.rules[i].pattern, relativePath)) {
      matched.push(config.rules[i]);
    }
  }
  matched.sort(function(a, b) { return patternSpecificity(b.pattern) - patternSpecificity(a.pattern); });
  return matched;
}

// --- Edit Content Extraction ---

function getEditInfo(toolName, toolInput) {
  if (toolName === 'Edit') {
    return {
      edits: [{ oldText: toolInput.old_string || '', newText: toolInput.new_string || '' }],
      isFullWrite: false,
    };
  }
  if (toolName === 'Write') {
    return { fullContent: toolInput.content || '', isFullWrite: true };
  }
  if (toolName === 'mcp__filesystem__edit_file') {
    var edits = (toolInput.edits || []).map(function(e) {
      return { oldText: e.oldText || '', newText: e.newText || '' };
    });
    return { edits: edits, isFullWrite: false };
  }
  if (toolName === 'mcp__filesystem__write_file') {
    return { fullContent: toolInput.content || '', isFullWrite: true };
  }
  return null;
}

// ============================================================
// CHECK IMPLEMENTATIONS
// ============================================================

function checkNoWriteAllowed(rule, editInfo, relativePath) {
  return [{
    check: 'no_write_allowed',
    tier: rule.tier,
    message: rule.message || 'File is write-protected: ' + relativePath,
  }];
}

function checkCredentialScan(config, editInfo) {
  var violations = [];
  var patterns = config.credentialPatterns || [];
  var placeholders = config.placeholderPatterns || [];
  var textsToScan = [];

  if (editInfo.isFullWrite) {
    textsToScan.push(editInfo.fullContent);
  } else if (editInfo.edits) {
    for (var i = 0; i < editInfo.edits.length; i++) {
      textsToScan.push(editInfo.edits[i].newText);
    }
  }

  for (var t = 0; t < textsToScan.length; t++) {
    var text = textsToScan[t];
    for (var p = 0; p < patterns.length; p++) {
      var match = text.match(patterns[p].regex);
      if (match) {
        var matchedText = match[0];
        var isPlaceholder = false;
        for (var pl = 0; pl < placeholders.length; pl++) {
          if (placeholders[pl].test(matchedText)) { isPlaceholder = true; break; }
        }
        if (!isPlaceholder) {
          violations.push({
            check: 'credential_scan',
            tier: 'critical',
            message: 'Potential ' + patterns[p].name + ' detected in edit content',
          });
        }
      }
    }
  }
  return violations;
}

function findRemovedKeys(oldText, newText) {
  var keyRegex = /^([a-zA-Z_][\w_-]*)\s*:/gm;
  var oldKeys = {};
  var newKeys = {};
  var m;
  while ((m = keyRegex.exec(oldText)) !== null) oldKeys[m[1]] = true;
  keyRegex.lastIndex = 0;
  while ((m = keyRegex.exec(newText)) !== null) newKeys[m[1]] = true;
  var removed = [];
  for (var k in oldKeys) { if (!newKeys[k]) removed.push(k); }
  return removed;
}

async function checkKeyDeletion(editInfo, absolutePath) {
  var violations = [];
  if (editInfo.isFullWrite) {
    try {
      var current = await fs.readFile(absolutePath, 'utf8');
      var removed = findRemovedKeys(current, editInfo.fullContent);
      for (var i = 0; i < removed.length; i++) {
        violations.push({
          check: 'key_deletion_protection',
          tier: 'critical',
          message: "Top-level key '" + removed[i] + "' would be removed",
        });
      }
    } catch (e) { /* New file */ }
  } else if (editInfo.edits) {
    for (var j = 0; j < editInfo.edits.length; j++) {
      var removed2 = findRemovedKeys(editInfo.edits[j].oldText, editInfo.edits[j].newText);
      for (var k = 0; k < removed2.length; k++) {
        violations.push({
          check: 'key_deletion_protection',
          tier: 'critical',
          message: "Top-level key '" + removed2[k] + "' would be removed",
        });
      }
    }
  }
  return violations;
}

function findRemovedSections(oldText, newText) {
  var headingRegex = /^##\s+(.+)$/gm;
  var oldHeadings = [];
  var newHeadings = [];
  var m;
  while ((m = headingRegex.exec(oldText)) !== null) oldHeadings.push(m[1].trim());
  headingRegex.lastIndex = 0;
  while ((m = headingRegex.exec(newText)) !== null) newHeadings.push(m[1].trim());
  return oldHeadings.filter(function(h) { return newHeadings.indexOf(h) === -1; });
}

async function checkSectionPreservation(rule, editInfo, absolutePath) {
  var violations = [];
  var protectedSections = rule.protectedSections || null;

  if (editInfo.isFullWrite) {
    try {
      var current = await fs.readFile(absolutePath, 'utf8');
      var removed = findRemovedSections(current, editInfo.fullContent);
      for (var i = 0; i < removed.length; i++) {
        if (!protectedSections || protectedSections.indexOf(removed[i]) !== -1) {
          violations.push({
            check: 'section_preservation',
            tier: rule.tier,
            message: 'Section "## ' + removed[i] + '" would be removed',
          });
        }
      }
    } catch (e) { /* New file */ }
  } else if (editInfo.edits) {
    for (var j = 0; j < editInfo.edits.length; j++) {
      var removed2 = findRemovedSections(editInfo.edits[j].oldText, editInfo.edits[j].newText);
      for (var k = 0; k < removed2.length; k++) {
        if (!protectedSections || protectedSections.indexOf(removed2[k]) !== -1) {
          violations.push({
            check: 'section_preservation',
            tier: rule.tier,
            message: 'Section "## ' + removed2[k] + '" would be removed',
          });
        }
      }
    }
  }
  return violations;
}

async function checkHeadingStructure(rule, editInfo, absolutePath) {
  if (!editInfo.isFullWrite) return [];
  var violations = [];
  try {
    var current = await fs.readFile(absolutePath, 'utf8');
    var headingRegex = /^(#{1,6})\s+(.+)$/gm;
    var oldHeadings = [];
    var newHeadings = [];
    var m;
    while ((m = headingRegex.exec(current)) !== null) {
      oldHeadings.push({ level: m[1].length, text: m[2].trim() });
    }
    headingRegex.lastIndex = 0;
    while ((m = headingRegex.exec(editInfo.fullContent)) !== null) {
      newHeadings.push({ level: m[1].length, text: m[2].trim() });
    }
    for (var i = 0; i < oldHeadings.length; i++) {
      var exists = false;
      for (var j = 0; j < newHeadings.length; j++) {
        if (newHeadings[j].text === oldHeadings[i].text && newHeadings[j].level === oldHeadings[i].level) {
          exists = true; break;
        }
      }
      if (!exists) {
        var hashes = '';
        for (var h = 0; h < oldHeadings[i].level; h++) hashes += '#';
        violations.push({
          check: 'heading_structure',
          tier: rule.tier,
          message: 'Heading "' + hashes + ' ' + oldHeadings[i].text + '" would be removed',
        });
      }
    }
  } catch (e) { /* New file */ }
  return violations;
}

function parseSimpleFrontmatter(text) {
  var fmMatch = text.match(/^---\n([\s\S]*?)\n---/);
  if (!fmMatch) return null;
  var fields = {};
  var lines = fmMatch[1].split('\n');
  for (var i = 0; i < lines.length; i++) {
    var kv = lines[i].match(/^(\w[\w-]*)\s*:\s*(.+)/);
    if (kv) fields[kv[1]] = kv[2].trim();
  }
  return fields;
}

async function checkFrontmatterPreservation(rule, editInfo, absolutePath) {
  var lockedFields = rule.lockedFields || [];
  if (lockedFields.length === 0) return [];
  var violations = [];

  if (editInfo.isFullWrite) {
    try {
      var current = await fs.readFile(absolutePath, 'utf8');
      var oldFm = parseSimpleFrontmatter(current);
      var newFm = parseSimpleFrontmatter(editInfo.fullContent);
      if (oldFm && !newFm) {
        violations.push({ check: 'frontmatter_preservation', tier: rule.tier, message: 'YAML frontmatter was removed entirely' });
      } else if (oldFm && newFm) {
        for (var i = 0; i < lockedFields.length; i++) {
          var field = lockedFields[i];
          if (oldFm[field] && oldFm[field] !== newFm[field]) {
            violations.push({
              check: 'frontmatter_preservation', tier: rule.tier,
              message: "Locked field '" + field + "' changed: \"" + oldFm[field] + '" -> "' + (newFm[field] || '(removed)') + '"',
            });
          }
        }
      }
    } catch (e) { /* New file */ }
  } else if (editInfo.edits) {
    for (var j = 0; j < editInfo.edits.length; j++) {
      var oldFm2 = parseSimpleFrontmatter(editInfo.edits[j].oldText);
      var newFm2 = parseSimpleFrontmatter(editInfo.edits[j].newText);
      if (oldFm2) {
        if (!newFm2) {
          violations.push({ check: 'frontmatter_preservation', tier: rule.tier, message: 'YAML frontmatter was removed in edit' });
        } else {
          for (var k = 0; k < lockedFields.length; k++) {
            var f = lockedFields[k];
            if (oldFm2[f] && oldFm2[f] !== newFm2[f]) {
              violations.push({
                check: 'frontmatter_preservation', tier: rule.tier,
                message: "Locked field '" + f + "' changed: \"" + oldFm2[f] + '" -> "' + (newFm2[f] || '(removed)') + '"',
              });
            }
          }
        }
      }
    }
  }
  return violations;
}

async function checkShebangPreservation(rule, editInfo, absolutePath) {
  var violations = [];
  if (editInfo.isFullWrite) {
    try {
      var current = await fs.readFile(absolutePath, 'utf8');
      var oldFirst = current.split('\n')[0];
      var newFirst = (editInfo.fullContent || '').split('\n')[0];
      if (oldFirst.startsWith('#!') && !newFirst.startsWith('#!')) {
        violations.push({ check: 'shebang_preservation', tier: rule.tier, message: 'Shebang line removed: "' + oldFirst + '"' });
      }
    } catch (e) { /* New file */ }
  } else if (editInfo.edits) {
    for (var i = 0; i < editInfo.edits.length; i++) {
      var oldF = editInfo.edits[i].oldText.split('\n')[0];
      var newF = editInfo.edits[i].newText.split('\n')[0];
      if (oldF.startsWith('#!') && !newF.startsWith('#!')) {
        violations.push({ check: 'shebang_preservation', tier: rule.tier, message: 'Shebang line removed: "' + oldF + '"' });
      }
    }
  }
  return violations;
}

// ============================================================
// V2: SEMANTIC RELEVANCE (Ollama)
// ============================================================

async function queryOllama(content, purpose, v2Settings) {
  try {
    // Phase 1: Health check (1s timeout)
    var healthCtrl = new AbortController();
    var healthTimer = setTimeout(function() { healthCtrl.abort(); }, 1000);
    try {
      var healthRes = await fetch(v2Settings.ollamaUrl + '/api/tags', { signal: healthCtrl.signal });
      clearTimeout(healthTimer);
      if (!healthRes.ok) return null;
    } catch (e) {
      clearTimeout(healthTimer);
      return null;
    }

    // Phase 2: Generation with configured timeout
    var genCtrl = new AbortController();
    var genTimer = setTimeout(function() { genCtrl.abort(); }, v2Settings.timeout);

    var truncated = content.length > 2000 ? content.slice(0, 2000) : content;
    var prompt = 'You are a file content validator. A file has this purpose: "' + purpose + '"\n\n' +
      'The following content is being written to this file:\n```\n' + truncated + '\n```\n\n' +
      'Is this content relevant to the file\'s purpose? Respond with ONLY valid JSON:\n' +
      '{"relevant": true} or {"relevant": false, "reason": "brief explanation"}\n' +
      'JSON response:';

    try {
      var genRes = await fetch(v2Settings.ollamaUrl + '/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: v2Settings.model,
          prompt: prompt,
          stream: false,
          options: { temperature: 0.1, num_predict: 100 },
        }),
        signal: genCtrl.signal,
      });
      clearTimeout(genTimer);

      if (!genRes.ok) return null;
      var genData = await genRes.json();
      var response = (genData.response || '').trim();

      // Extract JSON from response (handle markdown code blocks)
      var jsonMatch = response.match(/\{[\s\S]*?\}/);
      if (!jsonMatch) return null;
      return JSON.parse(jsonMatch[0]);
    } catch (e) {
      clearTimeout(genTimer);
      return null;
    }
  } catch (e) {
    return null;
  }
}

async function checkSemanticRelevance(rule, editInfo, v2Settings) {
  // Skip if rule has no purpose field
  if (!rule.purpose) return [];

  // Collect content to check
  var content = '';
  if (editInfo.isFullWrite) {
    content = editInfo.fullContent || '';
  } else if (editInfo.edits) {
    var parts = [];
    for (var i = 0; i < editInfo.edits.length; i++) {
      parts.push(editInfo.edits[i].newText);
    }
    content = parts.join('\n');
  }

  // Skip if content is too short
  if (content.length < v2Settings.minContentLength) return [];

  // Query Ollama
  var result = await queryOllama(content, rule.purpose, v2Settings);

  // Fail open: null means Ollama error
  if (!result) return [];

  // If content is relevant, no violation
  if (result.relevant) return [];

  // Irrelevant content: always medium tier (warn, never block)
  return [{
    check: 'semantic_relevance',
    tier: 'medium',
    message: 'Content may not match file purpose (' + rule.purpose + ')' + (result.reason ? ': ' + result.reason : ''),
  }];
}

// ============================================================
// CHECK DISPATCHER
// ============================================================

async function runChecks(config, rules, editInfo, absolutePath, relativePath, toggles) {
  var allViolations = [];

  // General rules (credential scan gated by toggle)
  if (toggles.credentialScan) {
    for (var g = 0; g < config.general.length; g++) {
      if (config.general[g].check === 'credential_scan') {
        var cv = checkCredentialScan(config, editInfo);
        for (var c = 0; c < cv.length; c++) allViolations.push(cv[c]);
      }
    }
  }

  // Path-specific rules
  for (var r = 0; r < rules.length; r++) {
    var rule = rules[r];
    var checks = rule.checks || [];
    for (var ch = 0; ch < checks.length; ch++) {
      var results = [];
      switch (checks[ch]) {
        // V1 structural checks (gated by structuralChecks toggle)
        case 'no_write_allowed':
          // no_write_allowed always runs if V1 is enabled (it's a hard block, not structural)
          if (toggles.v1Enabled) results = checkNoWriteAllowed(rule, editInfo, relativePath);
          break;
        case 'key_deletion_protection':
          if (toggles.structuralChecks) results = await checkKeyDeletion(editInfo, absolutePath);
          break;
        case 'section_preservation':
          if (toggles.structuralChecks) results = await checkSectionPreservation(rule, editInfo, absolutePath);
          break;
        case 'heading_structure':
          if (toggles.structuralChecks) results = await checkHeadingStructure(rule, editInfo, absolutePath);
          break;
        case 'frontmatter_preservation':
          if (toggles.structuralChecks) results = await checkFrontmatterPreservation(rule, editInfo, absolutePath);
          break;
        case 'shebang_preservation':
          if (toggles.structuralChecks) results = await checkShebangPreservation(rule, editInfo, absolutePath);
          break;

        // V2 semantic check (gated by v2Enabled toggle)
        case 'semantic_relevance':
          if (toggles.v2Enabled) results = await checkSemanticRelevance(rule, editInfo, toggles.v2Settings);
          break;

        default:
          console.error('[document-guard] Unknown check: ' + checks[ch]);
      }
      for (var v = 0; v < results.length; v++) allViolations.push(results[v]);
    }
  }

  // Deduplicate
  var seen = {};
  return allViolations.filter(function(v) {
    if (seen[v.message]) return false;
    seen[v.message] = true;
    return true;
  });
}

// ============================================================
// OVERRIDE MECHANISM
// ============================================================

async function checkOverride(relativePath) {
  try {
    var data = await fs.readFile(OVERRIDE_FILE, 'utf8');
    var parsed = JSON.parse(data);
    var now = Date.now();
    var overrides = parsed.overrides || [];
    for (var i = 0; i < overrides.length; i++) {
      var o = overrides[i];
      var matchesFile = relativePath === o.file || relativePath.endsWith(o.file) || relativePath.includes(o.file);
      var notExpired = !o.expires || o.expires > now;
      if (matchesFile && notExpired) return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

async function consumeOverride(relativePath) {
  try {
    var data = await fs.readFile(OVERRIDE_FILE, 'utf8');
    var parsed = JSON.parse(data);
    parsed.overrides = (parsed.overrides || []).filter(function(o) {
      var matchesFile = relativePath === o.file || relativePath.endsWith(o.file) || relativePath.includes(o.file);
      return !matchesFile;
    });
    if (parsed.overrides.length === 0) {
      await fs.unlink(OVERRIDE_FILE).catch(function() {});
    } else {
      await fs.writeFile(OVERRIDE_FILE, JSON.stringify(parsed, null, 2));
    }
  } catch (e) { /* fine */ }
}

// ============================================================
// AUDIT LOGGING
// ============================================================

async function auditLog(action, relativePath, violations, rules) {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    var entry = {
      timestamp: new Date().toISOString(),
      hook: 'document-guard',
      version: 2,
      action: action,
      file: relativePath,
      violations: violations.map(function(v) { return { check: v.check, tier: v.tier, message: v.message }; }),
      rules: (rules || []).map(function(r) { return r.name; }),
    };
    await fs.appendFile(AUDIT_FILE, JSON.stringify(entry) + '\n');
  } catch (err) {
    console.error('[document-guard] Audit log error: ' + err.message);
  }
}

// ============================================================
// BLOCK MESSAGE FORMATTING
// ============================================================

function formatBlockMessage(relativePath, violations, rules, config) {
  var maxShow = config.settings.maxViolationsShown || 5;
  var ttl = config.settings.overrideTTL || 120;
  var tier = violations[0]?.tier || 'high';

  var msg = 'DOCUMENT GUARD [' + tier.toUpperCase() + ']: Edit blocked on ' + relativePath + '\n\n';
  msg += 'Violations:\n';

  var shown = violations.slice(0, maxShow);
  for (var i = 0; i < shown.length; i++) {
    msg += '  - [' + shown[i].check + '] ' + shown[i].message + '\n';
  }
  if (violations.length > maxShow) {
    msg += '  ... and ' + (violations.length - maxShow) + ' more\n';
  }

  msg += '\nMatched rules: ' + rules.map(function(r) { return r.name; }).join(', ') + '\n';
  msg += '\nTo override: Ask the user for explicit approval, then write this file:\n';
  msg += '  Path: ' + OVERRIDE_FILE + '\n';
  msg += '  Content: {"overrides":[{"file":"' + relativePath + '","reason":"User approved","expires":' + (Date.now() + ttl * 1000) + '}]}\n';
  msg += 'Then retry the edit. The override expires in ' + ttl + ' seconds and is single-use.';

  return msg;
}

// ============================================================
// MAIN
// ============================================================

async function main() {
  var chunks = [];
  for await (var chunk of process.stdin) {
    chunks.push(chunk);
  }
  var input = Buffer.concat(chunks).toString('utf8');

  var context;
  try {
    context = JSON.parse(input);
  } catch (e) {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  var tool_name = context.tool_name;
  var tool_input = context.tool_input;

  // Fast path: not an edit tool
  if (!EDIT_TOOLS.has(tool_name)) {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  // Extract file path
  var filePath = extractFilePath(tool_name, tool_input);
  if (!filePath) {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  var absolutePath = toAbsolutePath(filePath);
  var relativePath = toRelativePath(absolutePath);

  // Skip override file itself
  if (absolutePath === OVERRIDE_FILE || relativePath.endsWith('.document-guard-overrides.json')) {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  // Skip files outside project
  if (!absolutePath.startsWith(PROJECT_DIR)) {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  // Load config
  var config = await loadConfig();
  if (!config) {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  // Resolve toggles - check if guard is enabled
  var toggles = resolveToggles(config);
  if (!toggles.masterEnabled || (!toggles.v1Enabled && !toggles.v2Enabled)) {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  // Find matching rules
  var rules = findMatchingRules(config, relativePath);

  // Get edit content info
  var editInfo = getEditInfo(tool_name, tool_input);
  if (!editInfo) {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  // Run checks
  var violations = await runChecks(config, rules, editInfo, absolutePath, relativePath, toggles);

  // No violations - allow
  if (violations.length === 0) {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  // Determine highest tier
  var tierPriority = { critical: 4, high: 3, medium: 2, low: 1 };
  var highestTier = 'low';
  for (var i = 0; i < violations.length; i++) {
    var vTier = violations[i].tier || 'low';
    if ((tierPriority[vTier] || 0) > (tierPriority[highestTier] || 0)) {
      highestTier = vTier;
    }
  }

  // Critical/High: check for override, then block
  if (highestTier === 'critical' || highestTier === 'high') {
    var hasOverride = await checkOverride(relativePath);
    if (hasOverride) {
      await consumeOverride(relativePath);
      await auditLog('override_used', relativePath, violations, rules);
      var overrideMsg = violations.map(function(v) { return v.message; }).join('; ');
      console.log(JSON.stringify({
        proceed: true,
        hookSpecificOutput: {
          additionalContext: 'DOCUMENT GUARD OVERRIDE USED on ' + path.basename(relativePath) + ': ' + overrideMsg + '. This override was approved by the user.',
        },
      }));
      return;
    }

    await auditLog('blocked', relativePath, violations, rules);
    var message = formatBlockMessage(relativePath, violations, rules, config);
    console.log(JSON.stringify({ proceed: false, message: message }));
    return;
  }

  // Medium: warn but allow
  if (highestTier === 'medium') {
    await auditLog('warned', relativePath, violations, rules);
    var warnMsg = violations.map(function(v) { return '[' + v.check + '] ' + v.message; }).join('; ');
    console.log(JSON.stringify({
      proceed: true,
      hookSpecificOutput: {
        additionalContext: 'Document Guard warning on ' + path.basename(relativePath) + ': ' + warnMsg,
      },
    }));
    return;
  }

  // Low: log only
  await auditLog('logged', relativePath, violations, rules);
  console.log(JSON.stringify({ proceed: true }));
}

main().catch(function(err) {
  console.error('[document-guard] Fatal error: ' + err.message);
  console.log(JSON.stringify({ proceed: true }));
});

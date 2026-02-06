#!/usr/bin/env node
/**
 * Docker Validator Hook (Consolidated)
 *
 * Combines validation for Docker deployments:
 * - Compose file syntax and security
 * - Network configuration
 * - Environment variables
 *
 * Profile: homelab
 * Event: PreToolUse (Bash)
 * Priority: RECOMMENDED
 * Created: 2025-12-24
 * Adapted for AIfred: 2026-02-05
 *
 * Note: Uses child_process.execFile for safety. exec used only for
 * docker-compose config which requires shell piping.
 */

const { execFile } = require('child_process');
const util = require('util');
const execFileAsync = util.promisify(execFile);
const fs = require('fs').promises;
const path = require('path');

// Dangerous patterns in compose files
const DANGEROUS_PATTERNS = [
  { pattern: /privileged:\s*true/i, message: 'Privileged mode enabled - security risk' },
  { pattern: /network_mode:\s*host/i, message: 'Host network mode - security risk' },
  { pattern: /pid:\s*host/i, message: 'Host PID namespace - security risk' },
  { pattern: /:\/:/g, message: 'Root filesystem mount detected' },
  { pattern: /\/var\/run\/docker\.sock:/i, message: 'Docker socket mount - high security risk' }
];

// Sensitive variable patterns
const SENSITIVE_PATTERNS = [
  /password/i, /secret/i, /api[_-]?key/i, /token/i,
  /private[_-]?key/i, /encryption[_-]?key/i
];

async function validateComposeSyntax(filePath) {
  try {
    await execFileAsync('docker-compose', ['-f', filePath, 'config', '--quiet']);
    return { valid: true, errors: [] };
  } catch (err) {
    const errors = (err.stderr || '').split('\n').filter(line => line.trim());
    return { valid: false, errors };
  }
}

function checkDangerousPatterns(content) {
  const warnings = [];
  DANGEROUS_PATTERNS.forEach(({ pattern, message }) => {
    if (pattern.test(content)) warnings.push(message);
  });
  return warnings;
}

function checkCommonIssues(content) {
  const issues = [];
  if (/password:\s*["']?[^${\s]+["']?$/mi.test(content)) {
    issues.push('Hardcoded password detected - use environment variables');
  }
  if (!content.includes('restart:')) {
    issues.push('No restart policy defined - containers may not restart on failure');
  }
  return issues;
}

async function getExistingNetworks() {
  try {
    const { stdout } = await execFileAsync('docker', ['network', 'ls', '--format', '{{.Name}}']);
    return stdout.trim().split('\n').filter(n => n);
  } catch { return []; }
}

async function extractNetworksFromCompose(content) {
  const networks = { defined: [], referenced: [] };
  const networksMatch = content.match(/^networks:\s*\n((?:[ \t]+\S[^\n]*\n?)+)/m);
  if (networksMatch) {
    networksMatch[1].split('\n').forEach(line => {
      const match = line.match(/^\s{2}(\S+):/);
      if (match) networks.defined.push(match[1]);
    });
  }
  const serviceNetworksPattern = /networks:\s*\n((?:\s+-\s*\S+\n?)+)/g;
  let match;
  while ((match = serviceNetworksPattern.exec(content)) !== null) {
    match[1].split('\n').forEach(line => {
      const netMatch = line.match(/^\s+-\s*(\S+)/);
      if (netMatch) networks.referenced.push(netMatch[1]);
    });
  }
  return { defined: [...new Set(networks.defined)], referenced: [...new Set(networks.referenced)] };
}

async function validateNetworks(content, existingNetworks) {
  const composeNetworks = await extractNetworksFromCompose(content);
  const issues = [];
  const warnings = [];
  for (const network of composeNetworks.referenced) {
    if (['bridge', 'host', 'none', 'default'].includes(network)) continue;
    const isDefinedInCompose = composeNetworks.defined.includes(network);
    const existsExternally = existingNetworks.includes(network);
    if (!isDefinedInCompose && !existsExternally) {
      issues.push(`Network "${network}" does not exist and is not defined in compose`);
    } else if (existsExternally && !isDefinedInCompose) {
      warnings.push(`Network "${network}" is external - ensure it's marked with "external: true"`);
    }
  }
  return { issues, warnings };
}

async function main() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;
  const context = JSON.parse(input);

  const { tool_name, tool_input } = context;
  if (tool_name !== 'Bash') {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const command = tool_input?.command || '';

  // Check for docker-compose up/start/restart
  const composeMatch = command.match(/docker(?:-compose| compose)\s+(?:-f\s+["']?([^"'\s]+)["']?\s+)?(?:up|start|restart)/i);

  if (!composeMatch) {
    // Check for docker network connect
    if (command.includes('docker network connect')) {
      const match = command.match(/docker network connect\s+(\S+)\s+(\S+)/);
      if (match) {
        const [, networkName] = match;
        const existingNetworks = await getExistingNetworks();
        if (!existingNetworks.includes(networkName)) {
          console.error(`\n[docker-validator] Network "${networkName}" does not exist`);
          console.error(`Create it with: docker network create ${networkName}\n`);
          console.log(JSON.stringify({ proceed: false, reason: `Network "${networkName}" does not exist` }));
          return;
        }
      }
    }
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const composePath = composeMatch[1] || 'docker-compose.yml';
  console.error(`\n[docker-validator] Validating Docker deployment: ${composePath}`);

  try {
    const syntaxResult = await validateComposeSyntax(composePath);
    if (!syntaxResult.valid) {
      console.error('  SYNTAX ERRORS:');
      syntaxResult.errors.forEach(err => console.error(`    ${err}`));
      console.log(JSON.stringify({ proceed: false, reason: `Compose file has syntax errors: ${syntaxResult.errors[0]}` }));
      return;
    }
    console.error('  Syntax: OK');

    let content;
    try { content = await fs.readFile(composePath, 'utf-8'); }
    catch { console.log(JSON.stringify({ proceed: true })); return; }

    const allIssues = [];
    const allWarnings = [];

    allWarnings.push(...checkDangerousPatterns(content).map(w => `[security] ${w}`));
    allWarnings.push(...checkCommonIssues(content).map(i => `[compose] ${i}`));

    const existingNetworks = await getExistingNetworks();
    const networkResult = await validateNetworks(content, existingNetworks);
    allIssues.push(...networkResult.issues.map(i => `[network] ${i}`));
    allWarnings.push(...networkResult.warnings.map(w => `[network] ${w}`));

    if (allIssues.length > 0) {
      console.error('  BLOCKING ISSUES:');
      allIssues.forEach(i => console.error(`    ${i}`));
      console.log(JSON.stringify({ proceed: false, reason: allIssues[0] }));
      return;
    }

    if (allWarnings.length > 0) {
      console.error('  Warnings:');
      allWarnings.forEach(w => console.error(`    ${w}`));
    } else {
      console.error('  All validations passed');
    }
  } catch (err) {
    console.error(`[docker-validator] Warning: ${err.message}`);
  }

  console.log(JSON.stringify({ proceed: true }));
}

main().catch(err => {
  console.error(`[docker-validator] Fatal: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});

#!/usr/bin/env npx tsx
/**
 * Skill Tools - Deterministic Operations
 *
 * This is the template for skill tools following the "Code Before Prompts" pattern.
 * Copy this entire _template directory when creating a new skill with tools.
 *
 * Usage: npx tsx tools/index.ts <command> [args]
 *
 * Commands:
 *   create <template-id> <name>  - Create new file from template
 *   validate <path>              - Validate file against schema
 *   list                         - List available templates
 *   help                         - Show this help message
 *
 * Pattern: Code Before Prompts
 * See: .claude/context/patterns/code-before-prompts-pattern.md
 */

import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

// ESM compatibility
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Types
interface SkillConfig {
  name: string;
  version: string;
  description: string;
  templates: TemplateDefinition[];
  validation: ValidationConfig;
}

interface TemplateDefinition {
  id: string;
  name: string;
  description: string;
  outputPath: string;
}

interface ValidationConfig {
  requiredSections: string[];
  maxSizeBytes: number;
}

interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
}

// Paths
const SKILL_ROOT = path.join(__dirname, '..');
const CONFIG_PATH = path.join(SKILL_ROOT, 'config.json');
const TEMPLATES_DIR = path.join(SKILL_ROOT, 'templates');

// Find project root (git root or 4 levels up from tools/)
function findProjectRoot(): string {
  let dir = SKILL_ROOT;
  // Go up until we find .git or reach a reasonable limit
  for (let i = 0; i < 10; i++) {
    if (fs.existsSync(path.join(dir, '.git'))) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) break; // Reached filesystem root
    dir = parent;
  }
  // Fallback: assume standard skill location (.claude/skills/<name>)
  return path.join(SKILL_ROOT, '..', '..', '..');
}

const PROJECT_ROOT = findProjectRoot();

// ============================================================
// CORE FUNCTIONS - These handle deterministic operations
// ============================================================

/**
 * Load skill configuration from config.json
 */
function loadConfig(): SkillConfig {
  if (!fs.existsSync(CONFIG_PATH)) {
    throw new Error(`Config not found: ${CONFIG_PATH}`);
  }
  const raw = fs.readFileSync(CONFIG_PATH, 'utf8');
  return JSON.parse(raw);
}

/**
 * Create a new file from a template
 * This is a DETERMINISTIC operation - same inputs always produce same outputs
 */
function createFromTemplate(templateId: string, name: string): string {
  const config = loadConfig();
  const template = config.templates.find(t => t.id === templateId);

  if (!template) {
    console.error(`Template not found: ${templateId}`);
    console.log('\nAvailable templates:');
    config.templates.forEach(t => console.log(`  - ${t.id}: ${t.description}`));
    process.exit(1);
  }

  const templatePath = path.join(TEMPLATES_DIR, `${templateId}.md`);

  if (!fs.existsSync(templatePath)) {
    throw new Error(`Template file not found: ${templatePath}`);
  }

  const content = fs.readFileSync(templatePath, 'utf8');
  const date = new Date().toISOString().split('T')[0];

  // Replace placeholders deterministically
  const output = content
    .replace(/\{\{NAME\}\}/g, name)
    .replace(/\{\{DATE\}\}/g, date)
    .replace(/\{\{TIMESTAMP\}\}/g, new Date().toISOString())
    .replace(/\{\{SLUG\}\}/g, name.toLowerCase().replace(/\s+/g, '-'));

  // Resolve output path (relative to project root)
  const slug = name.toLowerCase().replace(/\s+/g, '-');
  const relativePath = template.outputPath
    .replace('{{NAME}}', slug)
    .replace('{{DATE}}', date);
  const outputPath = path.join(PROJECT_ROOT, relativePath);

  // Ensure directory exists
  const outputDir = path.dirname(outputPath);
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  fs.writeFileSync(outputPath, output);
  console.log(`✓ Created: ${relativePath}`);

  return outputPath;
}

/**
 * Validate a file against the skill's schema
 * This is a DETERMINISTIC operation - same file always produces same validation result
 */
function validate(filePath: string): ValidationResult {
  const config = loadConfig();
  const result: ValidationResult = {
    valid: true,
    errors: [],
    warnings: []
  };

  // Check file exists
  if (!fs.existsSync(filePath)) {
    result.valid = false;
    result.errors.push(`File not found: ${filePath}`);
    return result;
  }

  const stats = fs.statSync(filePath);
  const content = fs.readFileSync(filePath, 'utf8');

  // Check file size
  if (stats.size > config.validation.maxSizeBytes) {
    result.warnings.push(
      `File size (${stats.size} bytes) exceeds recommended max (${config.validation.maxSizeBytes} bytes)`
    );
  }

  // Check required sections
  for (const section of config.validation.requiredSections) {
    if (!content.includes(section)) {
      result.warnings.push(`Missing recommended section: ${section}`);
    }
  }

  // Check for empty placeholders
  const placeholderMatch = content.match(/\{\{[A-Z_]+\}\}/g);
  if (placeholderMatch) {
    result.errors.push(`Unfilled placeholders: ${placeholderMatch.join(', ')}`);
    result.valid = false;
  }

  return result;
}

/**
 * List all available templates
 */
function listTemplates(): void {
  const config = loadConfig();
  console.log(`\n${config.name} v${config.version}`);
  console.log(`${config.description}`);
  console.log('='.repeat(50));
  console.log('\nAvailable Templates:');
  for (const t of config.templates) {
    console.log(`\n  ${t.id}`);
    console.log(`    Name: ${t.name}`);
    console.log(`    ${t.description}`);
    console.log(`    Output: ${t.outputPath}`);
  }
  console.log('');
}

/**
 * Show help message
 */
function showHelp(): void {
  const config = loadConfig();
  console.log(`
${config.name} - Deterministic Tools
${'='.repeat(50)}

Usage: npx tsx tools/index.ts <command> [args]

Commands:
  create <template-id> <name>  Create new file from template
  validate <path>              Validate file against schema
  list                         List available templates
  help                         Show this help message

Examples:
  npx tsx tools/index.ts list
  npx tsx tools/index.ts create default "My New Item"
  npx tsx tools/index.ts validate ./output/my-new-item.md

Pattern: Code Before Prompts
  - Use CODE for deterministic operations (file I/O, validation, templates)
  - Use AI for intelligence tasks (analysis, decisions, content generation)

See: .claude/context/patterns/code-before-prompts-pattern.md
`);
}

// ============================================================
// CLI ENTRY POINT
// ============================================================

const args = process.argv.slice(2);
const command = args[0];
const cmdArgs = args.slice(1);

try {
  switch (command) {
    case 'create':
      if (cmdArgs.length < 2) {
        console.error('Usage: create <template-id> <name>');
        process.exit(1);
      }
      createFromTemplate(cmdArgs[0], cmdArgs[1]);
      break;

    case 'validate':
      if (cmdArgs.length < 1) {
        console.error('Usage: validate <path>');
        process.exit(1);
      }
      const result = validate(cmdArgs[0]);
      console.log('\nValidation Result:');
      console.log(`  Valid: ${result.valid ? '✓' : '✗'}`);
      if (result.errors.length > 0) {
        console.log('  Errors:');
        result.errors.forEach(e => console.log(`    ✗ ${e}`));
      }
      if (result.warnings.length > 0) {
        console.log('  Warnings:');
        result.warnings.forEach(w => console.log(`    ⚠ ${w}`));
      }
      process.exit(result.valid ? 0 : 1);
      break;

    case 'list':
      listTemplates();
      break;

    case 'help':
    case '--help':
    case '-h':
    case undefined:
      showHelp();
      break;

    default:
      console.error(`Unknown command: ${command}`);
      showHelp();
      process.exit(1);
  }
} catch (error) {
  console.error(`Error: ${error instanceof Error ? error.message : error}`);
  process.exit(1);
}

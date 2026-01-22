#!/usr/bin/env npx tsx
/**
 * Structured Planning - Deterministic Tools
 *
 * Usage: npx tsx tools/index.ts <command> [args]
 *
 * Commands:
 *   create <mode> <name>   - Create new spec from template
 *   list [mode]            - List existing specs
 *   validate <path>        - Validate spec completeness
 *   archive <path>         - Move spec to archive
 *   status                 - Show planning status
 *   help                   - Show this help
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
  version: string;
  paths: {
    specsPath: string;
    reviewsPath: string;
    archivePath: string;
    questionBankPath: string;
    orchestrationPath: string;
  };
  naming: {
    specPrefix: string;
    dateFormat: string;
    slugify: boolean;
  };
}

interface ValidationResult {
  valid: boolean;
  errors: string[];
  warnings: string[];
  sections: { name: string; found: boolean }[];
}

interface SpecInfo {
  path: string;
  name: string;
  date: string;
  mode: string;
  status: string;
}

// Paths
const SKILL_ROOT = path.join(__dirname, '..');
const CONFIG_PATH = path.join(SKILL_ROOT, 'config.json');
const TEMPLATES_DIR = path.join(SKILL_ROOT, 'templates');

// Find project root
function findProjectRoot(): string {
  let dir = SKILL_ROOT;
  for (let i = 0; i < 10; i++) {
    if (fs.existsSync(path.join(dir, '.git'))) {
      return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return path.join(SKILL_ROOT, '..', '..', '..');
}

const PROJECT_ROOT = findProjectRoot();

// ============================================================
// CORE FUNCTIONS
// ============================================================

function loadConfig(): SkillConfig {
  if (!fs.existsSync(CONFIG_PATH)) {
    throw new Error(`Config not found: ${CONFIG_PATH}`);
  }
  const raw = fs.readFileSync(CONFIG_PATH, 'utf8');
  return JSON.parse(raw);
}

function getDate(): string {
  return new Date().toISOString().split('T')[0];
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
}

/**
 * Create a new spec file from template
 */
function createSpec(mode: string, name: string): string {
  const config = loadConfig();
  const date = getDate();
  const slug = slugify(name);

  // Map mode to template
  const templateMap: Record<string, string> = {
    'new': 'new-design-spec.md',
    'new-design': 'new-design-spec.md',
    'review': 'system-review-spec.md',
    'system-review': 'system-review-spec.md',
    'feature': 'feature-plan-spec.md',
    'feature-plan': 'feature-plan-spec.md'
  };

  const templateFile = templateMap[mode];
  if (!templateFile) {
    console.error(`Unknown mode: ${mode}`);
    console.log('\nAvailable modes:');
    console.log('  new, new-design    - Full design specification');
    console.log('  review, system-review - System review findings');
    console.log('  feature, feature-plan - Feature specification');
    process.exit(1);
  }

  const templatePath = path.join(TEMPLATES_DIR, templateFile);
  if (!fs.existsSync(templatePath)) {
    throw new Error(`Template not found: ${templatePath}`);
  }

  const content = fs.readFileSync(templatePath, 'utf8');

  // Replace placeholders
  const output = content
    .replace(/\{\{NAME\}\}/g, name)
    .replace(/\{\{DATE\}\}/g, date)
    .replace(/\{\{SLUG\}\}/g, slug)
    .replace(/\{\{MODE\}\}/g, mode);

  // Determine output path based on mode
  let outputDir = config.paths.specsPath;
  if (mode === 'review' || mode === 'system-review') {
    outputDir = config.paths.reviewsPath;
  }

  const outputPath = path.join(PROJECT_ROOT, outputDir, `${date}-${slug}.md`);

  // Ensure directory exists
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  fs.writeFileSync(outputPath, output);
  console.log(`✓ Created: ${outputDir}/${date}-${slug}.md`);

  return outputPath;
}

/**
 * List existing specs
 */
function listSpecs(mode?: string): SpecInfo[] {
  const config = loadConfig();
  const specs: SpecInfo[] = [];

  // Directories to scan
  const dirs = [
    { path: config.paths.specsPath, mode: 'spec' },
    { path: config.paths.reviewsPath, mode: 'review' }
  ];

  for (const dir of dirs) {
    if (mode && dir.mode !== mode) continue;

    const fullPath = path.join(PROJECT_ROOT, dir.path);
    if (!fs.existsSync(fullPath)) continue;

    const files = fs.readdirSync(fullPath).filter(f => f.endsWith('.md'));

    for (const file of files) {
      const match = file.match(/^(\d{4}-\d{2}-\d{2})-(.+)\.md$/);
      if (match) {
        const filePath = path.join(fullPath, file);
        const content = fs.readFileSync(filePath, 'utf8');

        // Determine status from content
        let status = 'draft';
        if (content.includes('Status: Approved') || content.includes('Status: approved')) {
          status = 'approved';
        } else if (content.includes('Status: Complete') || content.includes('Status: complete')) {
          status = 'complete';
        }

        specs.push({
          path: `${dir.path}/${file}`,
          name: match[2].replace(/-/g, ' '),
          date: match[1],
          mode: dir.mode,
          status
        });
      }
    }
  }

  // Sort by date descending
  specs.sort((a, b) => b.date.localeCompare(a.date));

  return specs;
}

/**
 * Validate a spec file
 */
function validateSpec(filePath: string): ValidationResult {
  const result: ValidationResult = {
    valid: true,
    errors: [],
    warnings: [],
    sections: []
  };

  // Resolve path
  const fullPath = filePath.startsWith('/')
    ? filePath
    : path.join(PROJECT_ROOT, filePath);

  if (!fs.existsSync(fullPath)) {
    result.valid = false;
    result.errors.push(`File not found: ${filePath}`);
    return result;
  }

  const content = fs.readFileSync(fullPath, 'utf8');

  // Required sections for different spec types
  const requiredSections = [
    { name: 'Overview', pattern: /^##\s+Overview/m },
    { name: 'Scope', pattern: /^##\s+(Scope|Features)/m },
    { name: 'Success Criteria', pattern: /^##\s+Success\s+Criteria/m }
  ];

  // Check required sections
  for (const section of requiredSections) {
    const found = section.pattern.test(content);
    result.sections.push({ name: section.name, found });
    if (!found) {
      result.warnings.push(`Missing section: ${section.name}`);
    }
  }

  // Check for unfilled placeholders
  const placeholders = content.match(/\{\{[A-Z_]+\}\}/g);
  if (placeholders) {
    result.errors.push(`Unfilled placeholders: ${placeholders.join(', ')}`);
    result.valid = false;
  }

  // Check for empty required fields
  if (content.includes('[TODO]') || content.includes('TBD')) {
    result.warnings.push('Contains TODO or TBD markers');
  }

  // Check acceptance criteria has items
  const acMatch = content.match(/##\s+Success\s+Criteria[\s\S]*?(?=##|$)/);
  if (acMatch && !acMatch[0].includes('- [')) {
    result.warnings.push('Success Criteria section has no checkbox items');
  }

  return result;
}

/**
 * Archive a spec
 */
function archiveSpec(filePath: string): string {
  const config = loadConfig();

  // Resolve path
  const fullPath = filePath.startsWith('/')
    ? filePath
    : path.join(PROJECT_ROOT, filePath);

  if (!fs.existsSync(fullPath)) {
    throw new Error(`File not found: ${filePath}`);
  }

  const fileName = path.basename(fullPath);
  const archivePath = path.join(PROJECT_ROOT, config.paths.archivePath, fileName);

  // Ensure archive directory exists
  const archiveDir = path.dirname(archivePath);
  if (!fs.existsSync(archiveDir)) {
    fs.mkdirSync(archiveDir, { recursive: true });
  }

  // Move file
  fs.renameSync(fullPath, archivePath);
  console.log(`✓ Archived: ${filePath} → ${config.paths.archivePath}/${fileName}`);

  return archivePath;
}

/**
 * Show planning status
 */
function showStatus(): void {
  const config = loadConfig();
  const specs = listSpecs();

  console.log('\n=== Planning Status ===\n');

  // Count by status
  const byStatus = {
    draft: specs.filter(s => s.status === 'draft').length,
    approved: specs.filter(s => s.status === 'approved').length,
    complete: specs.filter(s => s.status === 'complete').length
  };

  console.log('Specs by Status:');
  console.log(`  Draft:    ${byStatus.draft}`);
  console.log(`  Approved: ${byStatus.approved}`);
  console.log(`  Complete: ${byStatus.complete}`);

  // Recent specs
  console.log('\nRecent Specs (last 5):');
  const recent = specs.slice(0, 5);
  if (recent.length === 0) {
    console.log('  No specs found');
  } else {
    for (const spec of recent) {
      const statusIcon = spec.status === 'complete' ? '✓' :
                        spec.status === 'approved' ? '◐' : '○';
      console.log(`  ${statusIcon} [${spec.date}] ${spec.name} (${spec.mode})`);
    }
  }

  // Paths
  console.log('\nPaths:');
  console.log(`  Specs:   ${config.paths.specsPath}`);
  console.log(`  Reviews: ${config.paths.reviewsPath}`);
  console.log(`  Archive: ${config.paths.archivePath}`);

  console.log('');
}

/**
 * Show help
 */
function showHelp(): void {
  console.log(`
Structured Planning - Deterministic Tools
=========================================

Usage: npx tsx tools/index.ts <command> [args]

Commands:
  create <mode> <name>   Create new spec from template
                         Modes: new, review, feature
                         Example: create new "Habit Tracker App"

  list [mode]            List existing specs
                         Optional mode filter: spec, review
                         Example: list spec

  validate <path>        Validate spec completeness
                         Example: validate .claude/planning/specs/2026-01-21-habit-tracker.md

  archive <path>         Move spec to archive
                         Example: archive .claude/planning/specs/2026-01-21-habit-tracker.md

  status                 Show planning status overview

  help                   Show this help message

Examples:
  npx tsx tools/index.ts create new "User Authentication System"
  npx tsx tools/index.ts create review "Voice System"
  npx tsx tools/index.ts create feature "Dark Mode"
  npx tsx tools/index.ts list
  npx tsx tools/index.ts validate .claude/planning/specs/2026-01-21-auth.md
  npx tsx tools/index.ts status
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
        console.error('Usage: create <mode> <name>');
        console.error('Modes: new, review, feature');
        process.exit(1);
      }
      createSpec(cmdArgs[0], cmdArgs.slice(1).join(' '));
      break;

    case 'list':
      const specs = listSpecs(cmdArgs[0]);
      console.log('\nExisting Specs:');
      if (specs.length === 0) {
        console.log('  No specs found');
      } else {
        for (const spec of specs) {
          const statusIcon = spec.status === 'complete' ? '✓' :
                            spec.status === 'approved' ? '◐' : '○';
          console.log(`  ${statusIcon} [${spec.date}] ${spec.name}`);
          console.log(`    Path: ${spec.path}`);
        }
      }
      console.log('');
      break;

    case 'validate':
      if (cmdArgs.length < 1) {
        console.error('Usage: validate <path>');
        process.exit(1);
      }
      const result = validateSpec(cmdArgs[0]);
      console.log('\nValidation Result:');
      console.log(`  Valid: ${result.valid ? '✓' : '✗'}`);

      if (result.sections.length > 0) {
        console.log('  Sections:');
        for (const section of result.sections) {
          console.log(`    ${section.found ? '✓' : '✗'} ${section.name}`);
        }
      }

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

    case 'archive':
      if (cmdArgs.length < 1) {
        console.error('Usage: archive <path>');
        process.exit(1);
      }
      archiveSpec(cmdArgs[0]);
      break;

    case 'status':
      showStatus();
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

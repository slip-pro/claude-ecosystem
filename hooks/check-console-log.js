#!/usr/bin/env node

/**
 * Stop hook: checks git diff for console.log in modified source files.
 * Outputs warning to stdout (Claude sees it), does not block.
 * Universal: supports .ts, .tsx, .js, .jsx
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const EXTENSIONS = '"*.ts" "*.tsx" "*.js" "*.jsx"';

function getModifiedFiles() {
  try {
    const output = execSync(
      `git diff HEAD --name-only --diff-filter=ACM -- ${EXTENSIONS}`,
      { encoding: 'utf-8', timeout: 5000 }
    ).trim();
    if (!output) return [];
    return output.split('\n').filter(Boolean);
  } catch {
    return [];
  }
}

function countConsoleLog(filePath) {
  try {
    const absPath = path.resolve(filePath);
    if (!fs.existsSync(absPath)) return 0;
    const content = fs.readFileSync(absPath, 'utf-8');
    const matches = content.match(/console\.log\s*\(/g);
    return matches ? matches.length : 0;
  } catch {
    return 0;
  }
}

function main() {
  const files = getModifiedFiles();
  if (files.length === 0) return;

  const warnings = [];
  for (const file of files) {
    const count = countConsoleLog(file);
    if (count > 0) {
      warnings.push(`  ${file}: ${count} console.log(s)`);
    }
  }

  if (warnings.length > 0) {
    process.stdout.write(
      `\nConsole.log detected in modified files:\n${warnings.join('\n')}\nConsider removing before commit.\n`
    );
  }
}

main();

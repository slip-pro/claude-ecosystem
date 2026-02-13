#!/usr/bin/env node

/**
 * PreCompact hook: saves current working state before context compaction.
 * Writes .claude/compact-state.json so Claude can restore context after compaction.
 * Universal: works in any git project.
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function run(cmd) {
  try {
    return execSync(cmd, { encoding: 'utf-8', timeout: 5000 }).trim();
  } catch {
    return '';
  }
}

function main() {
  const state = {
    timestamp: new Date().toISOString(),
    branch: run('git branch --show-current'),
    status: run('git status --short'),
    lastCommit: run('git log -1 --oneline'),
    modifiedFiles: run('git diff --name-only').split('\n').filter(Boolean),
  };

  // Write to project's .claude/ directory
  const claudeDir = path.join(process.cwd(), '.claude');
  if (!fs.existsSync(claudeDir)) {
    fs.mkdirSync(claudeDir, { recursive: true });
  }

  const outPath = path.join(claudeDir, 'compact-state.json');
  fs.writeFileSync(outPath, JSON.stringify(state, null, 2), 'utf-8');

  process.stdout.write(
    [
      'Git state saved to .claude/compact-state.json.',
      '',
      'BEFORE compaction, write a structured handoff to .claude/handoff.md:',
      '',
      '## Current State',
      '[What task/feature are you working on? What phase?]',
      '',
      '## Completed Work',
      '[What got done in this session — bullet list]',
      '',
      '## Remaining Work',
      '[What is left to do — bullet list]',
      '',
      '## Decisions Made',
      '[Key decisions and WHY — so next context does not re-debate]',
      '',
      '## Next Action',
      '[The SPECIFIC first step to take after compaction]',
      '',
      'After compaction, read .claude/compact-state.json and .claude/handoff.md to restore context.',
    ].join('\n')
  );
}

main();

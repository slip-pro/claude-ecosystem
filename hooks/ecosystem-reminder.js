#!/usr/bin/env node

/**
 * PostToolUse hook: reminds to commit ecosystem changes.
 * Triggers when Edit/Write modifies files in ~/.claude/{agents,rules,skills,hooks}/
 */

const os = require('os');
const path = require('path');

function main() {
  let inputData = '';

  process.stdin.setEncoding('utf-8');
  process.stdin.on('data', (chunk) => {
    inputData += chunk;
  });

  process.stdin.on('end', () => {
    try {
      const data = JSON.parse(inputData);
      const filePath = data?.tool_input?.file_path;

      if (!filePath) return;

      const homeDir = os.homedir();
      const claudeGlobal = path.join(homeDir, '.claude');
      const normalizedFile = path.resolve(filePath);

      // Check if the file is in global .claude/ ecosystem directories
      const ecosystemDirs = ['agents', 'rules', 'skills', 'hooks'].map(
        d => path.join(claudeGlobal, d)
      );

      const isEcosystemFile = ecosystemDirs.some(dir =>
        normalizedFile.startsWith(dir)
      );

      if (isEcosystemFile) {
        process.stdout.write(
          `\nEcosystem file modified: ${path.relative(claudeGlobal, normalizedFile)}\n` +
          `Remember to commit changes in your ecosystem repo.\n`
        );
      }
    } catch {
      // Silently ignore parse errors
    }
  });
}

main();

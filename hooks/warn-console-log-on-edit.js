#!/usr/bin/env node

/**
 * PostToolUse hook: after Edit/Write on source files,
 * checks the file for console.log statements and warns.
 * Universal: supports .ts, .tsx, .js, .jsx
 */

const fs = require('fs');
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
      if (!/\.(ts|tsx|js|jsx)$/.test(filePath)) return;

      const absPath = path.resolve(filePath);
      if (!fs.existsSync(absPath)) return;

      const content = fs.readFileSync(absPath, 'utf-8');
      const matches = content.match(/console\.log\s*\(/g);

      if (matches && matches.length > 0) {
        process.stdout.write(
          `File contains ${matches.length} console.log statement(s). Consider removing.`
        );
      }
    } catch {
      // Silently ignore parse errors
    }
  });
}

main();

#!/usr/bin/env node

const { execSync } = require('child_process');

const args = process.argv.slice(2);
const command = args[0] || 'sync';
const platform = args[1] ? args[1].toLowerCase() : '';

let capCommand = `npx cap ${command}`;

if (platform === 'android' || platform === 'ios') {
  capCommand += ` ${platform}`;
}

console.log(`\n⚡ Running: ${capCommand}\n`);

try {
  execSync(capCommand, { stdio: 'inherit' });
} catch (error) {
  process.exit(error.status || 1);
}

#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');
const activeEnvPath = path.join(rootDir, '.active-env');

const args = process.argv.slice(2);
const command = args[0] || 'sync';
const platform = args[1] ? args[1].toLowerCase() : '';

// Read the active environment (local | dev | prod)
let activeEnv = 'prod';
if (fs.existsSync(activeEnvPath)) {
  activeEnv = fs.readFileSync(activeEnvPath, 'utf8').trim();
}

let capCommand = `npx cap ${command}`;
if (platform === 'android' || platform === 'ios') {
  capCommand += ` ${platform}`;
}

console.log(`\n⚡ Active Environment: [ ${activeEnv.toUpperCase()} ]`);
console.log(`🚀 Running: ${capCommand}\n`);

try {
  execSync(capCommand, { stdio: 'inherit' });
} catch (error) {
  process.exit(error.status || 1);
}

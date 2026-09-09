#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const rootDir = path.resolve(__dirname, '..');
const configPath = path.join(rootDir, 'capacitor.config.json');

const envUrls = {
  local: {
    name: 'Local',
    url: 'https://pants-unshaken-stony.ngrok-free.dev/login'
  },
  dev: {
    name: 'Development',
    url: 'https://dev.setli.com.au/login'
  },
  prod: {
    name: 'Production',
    url: 'https://setli.com.au/login'
  },
  production: {
    name: 'Production',
    url: 'https://setli.com.au/login'
  }
};

const args = process.argv.slice(2);
const requestedEnv = (args[0] || 'prod').toLowerCase();
const shouldSync = args.includes('--sync') || args.includes('-s');

const targetEnv = envUrls[requestedEnv];

if (!targetEnv) {
  console.error(`❌ Unknown environment "${requestedEnv}". Available options: local, dev, prod (or production)`);
  process.exit(1);
}

if (!fs.existsSync(configPath)) {
  console.error(`❌ Config file "${configPath}" does not exist.`);
  process.exit(1);
}

try {
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

  if (!config.server) {
    config.server = {};
  }
  config.server.url = targetEnv.url;

  fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n', 'utf8');

  console.log(`\n======================================================`);
  console.log(`🚀 Switched Setli App Environment to: [ ${targetEnv.name.toUpperCase()} ]`);
  console.log(`🌐 Active URL: ${targetEnv.url}`);
  console.log(`📁 Updated: capacitor.config.json -> server.url`);
  console.log(`======================================================\n`);

  if (shouldSync) {
    console.log(`🔄 Syncing with iOS and Android native projects via Capacitor...\n`);
    execSync('npx cap sync', { stdio: 'inherit', cwd: rootDir });
    console.log(`\n✅ Successfully synced ${targetEnv.name} environment to iOS and Android!`);
  } else {
    console.log(`ℹ️  Run "npm run sync" to apply changes to native projects.`);
  }
} catch (error) {
  console.error(`❌ Failed to update capacitor.config.json:`, error.message);
  process.exit(1);
}

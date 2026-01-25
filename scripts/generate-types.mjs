#!/usr/bin/env node
/**
 * Generate TypeScript types from Supabase
 * Run: node scripts/generate-types.mjs
 */

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const PROJECT_ID = 'ykbpznoqebhopyqpoqaf';
const API_URL = `https://api.supabase.com/v1/projects/${PROJECT_ID}/types/typescript`;

// You need a Supabase access token
// Get it from: https://supabase.com/dashboard/account/tokens
const ACCESS_TOKEN = process.env.SUPABASE_ACCESS_TOKEN;

if (!ACCESS_TOKEN) {
  console.error('❌ Error: SUPABASE_ACCESS_TOKEN environment variable is required');
  console.error('');
  console.error('Get your access token from:');
  console.error('https://supabase.com/dashboard/account/tokens');
  console.error('');
  console.error('Then run:');
  console.error('SUPABASE_ACCESS_TOKEN=your_token node scripts/generate-types.mjs');
  process.exit(1);
}

console.log('🔄 Fetching types from Supabase...');

fetch(API_URL, {
  headers: {
    'Authorization': `Bearer ${ACCESS_TOKEN}`,
  },
})
  .then(res => {
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}: ${res.statusText}`);
    }
    return res.text();
  })
  .then(types => {
    const outputPath = join(__dirname, '..', 'types', 'database.types.ts');
    writeFileSync(outputPath, types, 'utf-8');
    console.log('✅ Types generated successfully!');
    console.log(`📁 Written to: ${outputPath}`);

    // Count how many tables
    const tableCount = (types.match(/Tables: \{/g) || []).length;
    const enumCount = (types.match(/Enums: \{/g) || []).length;

    console.log(`📊 Found: ~${tableCount} table definitions`);
    console.log(`📊 Found: ~${enumCount} enum definitions`);
  })
  .catch(err => {
    console.error('❌ Error generating types:', err.message);
    process.exit(1);
  });

#!/usr/bin/env node

// Wiki Semantic Search — searches markdown files in ~/wiki/
// Usage: node wiki-search.js <query> [--path <dir>] [--max <n>]

import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { argv, exit, stderr, stdout } from 'node:process';

const WIKI_DIR = resolve(process.env.WIKI_DIR || join(process.env.HOME, 'wiki'));
const QUERY = argv[2];
const MAX_RESULTS = argv.includes('--max')
  ? parseInt(argv[argv.indexOf('--max') + 1], 10) || 10
  : 10;

if (!QUERY || QUERY.startsWith('--')) {
  const name = argv[1].split('/').pop();
  console.error(`Usage: ${name} "search query" [--path <dir>] [--max <n>]`);
  exit(1);
}

if (!existsSync(WIKI_DIR)) {
  stderr.write(`Wiki directory not found: ${WIKI_DIR}\n`);
  exit(1);
}

const queryTokens = QUERY.toLowerCase()
  .replace(/[^a-z0-9\s-]/g, '').split(/\s+/).filter(Boolean);

if (queryTokens.length === 0) { stderr.write('No searchable terms.\n'); exit(0); }

function walkDir(dir) {
  const entries = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      if (!entry.name.startsWith('.') && entry.name !== 'node_modules')
        entries.push(...walkDir(full));
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      entries.push(full);
    }
  }
  return entries;
}

function scoreFile(filePath) {
  try {
    const content = readFileSync(filePath, 'utf-8');
    const lower = content.toLowerCase();
    let score = 0;
    const matched = [];
    for (const token of queryTokens) {
      let count = 0, pos = -1;
      while ((pos = lower.indexOf(token, pos + 1)) !== -1) {
        count++;
        if (count === 1) matched.push(token);
      }
      const hr = new RegExp(`^#{1,6}\\s.*${token}`, 'gm');
      const hm = lower.match(hr);
      if (hm) count += 3 * hm.length;
      if (lower.startsWith(`# ${token}`) || lower.startsWith(`#${token}`)) count += 5;
      score += count;
    }
    return { score, matched, path: filePath };
  } catch {
    return { score: 0, matched: [], path: filePath };
  }
}

const results = walkDir(WIKI_DIR)
  .map(scoreFile).filter(r => r.score > 0)
  .sort((a, b) => b.score - a.score)
  .slice(0, MAX_RESULTS);

if (results.length === 0) { stdout.write(`No results for "${QUERY}"\n`); exit(0); }

stdout.write(`Search: "${QUERY}" — ${results.length} result(s)\n\n`);
for (const r of results) {
  const relative = r.path.startsWith(WIKI_DIR + '/') ? r.path.slice(WIKI_DIR.length + 1) : r.path;
  stdout.write(`${relative}  (score: ${r.score})\n`);
  try {
    const lines = readFileSync(r.path, 'utf-8').split('\n');
    const cs = lines[0]?.startsWith('---')
      ? lines.slice(1).findIndex(l => l.startsWith('---')) + 2 : 0;
    const snippet = lines.slice(cs, cs + 3)
      .filter(l => l.trim()).map(l => l.replace(/^#{1,6}\s/, '').trim())
      .filter(Boolean).slice(0, 2);
    if (snippet.length) stdout.write(`  > ${snippet[0]}\n`);
  } catch {}
  stdout.write('\n');
}

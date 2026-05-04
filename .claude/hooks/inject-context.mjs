#!/usr/bin/env node
// PreToolUse hook : matche le file_path contre des globs et injecte la règle
// correspondante depuis .claude/rules/*.md via additionalContext.
// Reproduit la sémantique des règles glob-attached de Cursor.

import { readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const RULES = join(HERE, '..', 'rules');

const PATTERNS = [
  // BLoC standards
  { re: /\/lib\/(features|core)\/.*?bloc\/.+\.dart$/i, file: 'flutter-bloc.md' },
  // Widget standards (views, widgets, components)
  { re: /\/lib\/(features\/.+\/(views|widgets)|core\/components)\/.+\.dart$/i, file: 'flutter-widgets.md' },
  // Service standards
  { re: /\/lib\/(features\/.+\/services|core\/services|core\/service_locator)\/.+\.dart$/i, file: 'flutter-services.md' },
  // i18n standards (any .dart in lib/ or any .arb)
  { re: /\/lib\/.+\.dart$|\/lib\/l10n\/.+\.arb$/i, file: 'flutter-i18n.md' },
  // Pubspec — vérification compat plateformes
  { re: /\/pubspec\.yaml$/i, file: 'flutter-pubspec.md' },
  // Platform-specific config
  { re: /\/(android|ios|web)\/.+/i, file: 'flutter-platform-config.md' },
];

let raw = '';
try {
  raw = readFileSync(0, 'utf8');
} catch {
  process.exit(0);
}
if (!raw) process.exit(0);

let input;
try {
  input = JSON.parse(raw);
} catch {
  process.exit(0);
}

// Normaliser : convertir les backslashes Windows et garantir un / initial
// pour que les regex `/lib/...` matchent en relatif comme en absolu.
let fp = (input.tool_input?.file_path ?? '').replace(/\\/g, '/');
if (!fp) process.exit(0);
if (!fp.startsWith('/') && !/^[a-zA-Z]:\//.test(fp)) fp = '/' + fp;

const hits = PATTERNS.filter((p) => p.re.test(fp));
if (hits.length === 0) process.exit(0);

const sections = [];
const seen = new Set();
for (const h of hits) {
  if (seen.has(h.file)) continue;
  seen.add(h.file);
  const path = join(RULES, h.file);
  if (existsSync(path)) {
    sections.push(`<!-- rule: ${h.file} -->\n${readFileSync(path, 'utf8')}`);
  }
}
if (sections.length === 0) process.exit(0);

process.stdout.write(
  JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      additionalContext: sections.join('\n\n---\n\n'),
    },
  }),
);

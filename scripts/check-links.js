#!/usr/bin/env node

/**
 * Dead link checker for markdown cross-references and docs-site routes.
 *
 * Usage:
 *   node scripts/check-links.js [--mode markdown|site] [--verbose]
 *
 * Modes:
 *   markdown (default) — validates relative links in *.md files resolve to real files
 *   site               — validates every docs-site nav slug resolves via getDocPage()
 */

import { readFileSync, existsSync, readdirSync, statSync } from 'fs';
import { join, dirname, resolve, relative } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = resolve(__dirname, '..');

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);
const mode = args.includes('--mode')
	? args[args.indexOf('--mode') + 1] || 'markdown'
	: 'markdown';
const verbose = args.includes('--verbose') || args.includes('-v');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Recursively collect files matching a predicate. */
function walk(dir, predicate, results = []) {
	let entries;
	try {
		entries = readdirSync(dir);
	} catch {
		return results;
	}
	for (const entry of entries) {
		// Skip hidden dirs, node_modules, build artifacts, .svelte-kit
		if (entry.startsWith('.') || entry === 'node_modules' || entry === 'build') continue;
		const full = join(dir, entry);
		let s;
		try {
			s = statSync(full);
		} catch {
			continue;
		}
		if (s.isDirectory()) {
			walk(full, predicate, results);
		} else if (predicate(entry, full)) {
			results.push(full);
		}
	}
	return results;
}

/** Extract markdown links from content, returning [{line, target, text}]. */
function extractLinks(content) {
	const links = [];
	const lines = content.split('\n');
	let inCodeBlock = false;
	for (let i = 0; i < lines.length; i++) {
		// Track fenced code blocks (``` or ~~~)
		if (/^(`{3,}|~{3,})/.test(lines[i].trim())) {
			inCodeBlock = !inCodeBlock;
			continue;
		}
		if (inCodeBlock) continue;

		// Skip inline code spans before matching links
		const line = lines[i].replace(/`[^`]+`/g, '');

		// Match [text](target) but not ![alt](image)
		const re = /(?<!!)\[([^\]]*)\]\(([^)]+)\)/g;
		let m;
		while ((m = re.exec(line)) !== null) {
			links.push({ line: i + 1, text: m[1], target: m[2] });
		}
	}
	return links;
}

/** Check if a relative markdown target resolves to a real file. */
function resolveTarget(target, fromDir) {
	// Strip fragment
	const [pathPart] = target.split('#');
	if (!pathPart) return true; // pure #anchor — skip for now

	const resolved = resolve(fromDir, pathPart);

	// Direct file match
	if (existsSync(resolved)) return true;

	// If target has no extension, try common markdown index files
	if (!pathPart.endsWith('.md')) {
		if (existsSync(join(resolved, 'index.md'))) return true;
		if (existsSync(join(resolved, 'README.md'))) return true;
		// Try appending .md
		if (existsSync(resolved + '.md')) return true;
	}

	return false;
}

// ---------------------------------------------------------------------------
// Mode: markdown
// ---------------------------------------------------------------------------

async function checkMarkdown() {
	const files = walk(ROOT, (name) => name.endsWith('.md'));
	let broken = 0;
	let checked = 0;

	for (const file of files) {
		const content = readFileSync(file, 'utf-8');
		const links = extractLinks(content);
		const fileDir = dirname(file);
		const relFile = relative(ROOT, file);

		for (const link of links) {
			// Skip external URLs, mailto, anchors-only
			if (/^https?:\/\//.test(link.target)) continue;
			if (link.target.startsWith('mailto:')) continue;
			if (link.target.startsWith('#')) continue;

			checked++;

			if (!resolveTarget(link.target, fileDir)) {
				console.error(`  BROKEN  ${relFile}:${link.line}  →  ${link.target}`);
				broken++;
			} else if (verbose) {
				console.log(`  ok      ${relFile}:${link.line}  →  ${link.target}`);
			}
		}
	}

	console.log(`\nChecked ${checked} links across ${files.length} markdown files.`);
	if (broken > 0) {
		console.error(`\n${broken} broken link(s) found.`);
		process.exit(1);
	}
	console.log('All links OK.');
}

// ---------------------------------------------------------------------------
// Mode: site
// ---------------------------------------------------------------------------

async function checkSite() {
	const docsTs = join(ROOT, 'docs-site', 'src', 'lib', 'server', 'docs.ts');
	if (!existsSync(docsTs)) {
		console.error('docs-site/src/lib/server/docs.ts not found — skipping site mode.');
		process.exit(1);
	}

	// Dynamic import — requires ts-node or running after build
	// For simplicity, we re-implement the slug resolution inline
	const DOCS_DIR = join(ROOT, 'docs');

	/** Collect all .md files under docs/ and derive their slugs. */
	const mdFiles = walk(DOCS_DIR, (name) => name.endsWith('.md'));

	// Build set of valid slugs (mirroring docs.ts resolution)
	const validSlugs = new Set();
	for (const file of mdFiles) {
		let slug = relative(DOCS_DIR, file)
			.replace(/\.md$/, '')
			.replace(/\/index$/, '')
			.replace(/\/README$/i, '');
		validSlugs.add(slug);
	}

	// Now walk the nav tree to find all slugs the site would generate
	// (Re-implementing walkDir from docs.ts to avoid TypeScript import issues)
	function buildNavSlugs(dir, base, results = []) {
		let entries;
		try {
			entries = readdirSync(dir).sort();
		} catch {
			return results;
		}
		for (const entry of entries) {
			if (entry.startsWith('.')) continue;
			const full = join(dir, entry);
			let s;
			try {
				s = statSync(full);
			} catch {
				continue;
			}
			if (s.isDirectory()) {
				buildNavSlugs(full, base, results);
			} else if (
				entry.endsWith('.md') &&
				entry !== 'index.md' &&
				entry.toUpperCase() !== 'README.MD'
			) {
				const slug = relative(base, full)
					.replace(/\.md$/, '')
					.replace(/\/index$/, '')
					.replace(/\/README$/i, '');
				results.push(slug);
			}
		}
		return results;
	}

	const navSlugs = buildNavSlugs(DOCS_DIR, DOCS_DIR);
	let broken = 0;

	for (const slug of navSlugs) {
		// Check if the slug resolves (same logic as getDocPage)
		const candidates = [
			join(DOCS_DIR, `${slug}.md`),
			join(DOCS_DIR, slug, 'index.md'),
			join(DOCS_DIR, slug, 'README.md')
		];
		const found = candidates.some((c) => existsSync(c));
		if (!found) {
			console.error(`  BROKEN  docs route: /docs/${slug}  →  no matching file`);
			broken++;
		} else if (verbose) {
			console.log(`  ok      /docs/${slug}`);
		}
	}

	console.log(`\nChecked ${navSlugs.length} docs-site routes.`);
	if (broken > 0) {
		console.error(`\n${broken} broken route(s) found.`);
		process.exit(1);
	}
	console.log('All routes OK.');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

console.log(`check-links: mode=${mode}\n`);

if (mode === 'markdown') {
	await checkMarkdown();
} else if (mode === 'site') {
	await checkSite();
} else {
	console.error(`Unknown mode: ${mode}. Use --mode markdown or --mode site.`);
	process.exit(1);
}

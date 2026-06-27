#!/usr/bin/env bun
/**
 * skill init — create a new skill from template.
 *
 * Usage: bun scripts/init.ts <skill-name>
 *
 * Creates: ./<skill-name>/SKILL.md  (standard Agent Skills directory structure)
 *
 * This is a reference implementation. Adapt to your project's conventions:
 * - Change the output path if you use a different layout
 * - Add auto-registration if you maintain a skill registry
 * - Remove Bun dependency by rewriting in Python/Bash if needed
 */

import { writeFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";

const cwd = process.cwd();

// --- helpers ---

function kebabCase(s: string): string {
  return s
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function titleCase(s: string): string {
  return s
    .split("-")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

// --- template ---

function template(name: string): string {
  const title = titleCase(name);
  return [
    "---",
    `name: ${name}`,
    "description: >",
    "  [TODO: When should this skill trigger? What does it do?",
    "   Include specific keywords, file types, user phrases.",
    "   Use pushy language: 'Make sure to use this skill whenever...'",
    "   Example: 'Review TypeScript code for bugs and style.",
    "   Use when user says review, code check, audit, or mentions PR diff.']",
    "# triggers:         # optional — uncomment to add trigger test cases",
    "#   - query: 'review this PR'",
    "#     expect: match",
    "#   - query: '今天天气怎么样'",
    "#     expect: no_match",
    "# assertions:       # optional — uncomment to add output checks",
    "#   - '输出包含 severity 字段'",
    "#   - '每个问题都有修复建议'",
    "---",
    "",
    `# ${title}`,
    "",
    "<!--",
    "  STRUCTURE: pick one pattern and delete the others.",
    "",
    "  1. Workflow-based (sequential processes):",
    "     ## Overview → ## Workflow → ## Step 1 → ## Step 2 ...",
    "     Best for: deployment, publishing, debugging procedures.",
    "",
    "  2. Task-based (tool collections):",
    "     ## Overview → ## Quick Start → ## Task A → ## Task B ...",
    "     Best for: CLI references, tool collections, API guides.",
    "",
    "  3. Reference-based (standards, schemas, policies):",
    "     ## Overview → ## Rules → ## Examples → ## Boundaries",
    "     Best for: code review guidelines, brand standards.",
    "-->",
    "",
    "## Overview",
    "",
    "[TODO: 1-2 sentences on what this skill enables.]",
    "",
    "## [TODO: first real section]",
    "",
    "[TODO: content.]",
    "",
    "## Boundaries",
    "",
    "- [TODO: what this skill intentionally does NOT do]",
    "- [TODO: nearby requests that should NOT trigger this skill]",
    "",
  ].join("\n");
}

// --- main ---

async function main() {
  const rawName = process.argv[2];
  if (!rawName) {
    console.error("Usage: bun scripts/init.ts <skill-name>");
    process.exit(1);
  }

  const name = kebabCase(rawName);
  if (!name || name.length > 64) {
    console.error(`Invalid skill name: "${rawName}" → "${name}". Must be 1-64 chars.`);
    process.exit(1);
  }

  const skillDir = join(cwd, name);
  const exists = await Bun.file(join(skillDir, "SKILL.md")).exists();
  if (exists) {
    console.error(`Skill already exists: ${name}/SKILL.md`);
    process.exit(1);
  }

  mkdirSync(skillDir, { recursive: true });
  writeFileSync(join(skillDir, "SKILL.md"), template(name));
  console.log(`Created ${name}/SKILL.md`);
  console.log(`\nNext: edit ${name}/SKILL.md to fill TODOs.`);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});

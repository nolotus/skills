#!/usr/bin/env bun
/**
 * skill validate — check a SKILL.md file for format correctness.
 *
 * Usage: bun scripts/validate.ts <path-to-skill-directory>
 *        bun scripts/validate.ts .   (current directory)
 *
 * Checks:
 * - SKILL.md exists
 * - YAML frontmatter is valid
 * - name is kebab-case, ≤64 chars
 * - description exists, no angle brackets, ≤1024 chars
 *
 * This is a reference implementation. Adapt to your project's conventions.
 */

import { readFileSync } from "node:fs";
import { join } from "node:path";

// --- helpers ---

function parseFrontmatter(md: string) {
  const m = md.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return null;
  const lines = m[1].split("\n");
  const fm: Record<string, string> = {};
  let key = "";
  for (const line of lines) {
    const kv = line.match(/^(\w[\w-]*)\s*:\s*(.*)/);
    if (kv) {
      key = kv[1];
      let val = kv[2].trim();
      val = val.replace(/^[>|][-+]?\s*/, "");
      fm[key] = val;
    } else if (key && line.startsWith("  ")) {
      fm[key] += " " + line.trim();
    }
  }
  return fm;
}

function kebabCheck(name: string) {
  return /^[a-z][a-z0-9-]*$/.test(name) && !name.includes("--") && !name.endsWith("-");
}

// --- validate ---

interface Issue {
  severity: "error" | "warn";
  message: string;
}

function validate(dir: string): Issue[] {
  const issues: Issue[] = [];
  const skillPath = join(dir, "SKILL.md");

  let md: string;
  try { md = readFileSync(skillPath, "utf-8"); } catch {
    issues.push({ severity: "error", message: "SKILL.md not found" });
    return issues;
  }

  if (!md.startsWith("---")) {
    issues.push({ severity: "error", message: "No YAML frontmatter (must start with ---)" });
    return issues;
  }

  const fm = parseFrontmatter(md);
  if (!fm) {
    issues.push({ severity: "error", message: "Invalid YAML frontmatter" });
    return issues;
  }

  // name
  if (!fm.name) {
    issues.push({ severity: "error", message: "Missing 'name' in frontmatter" });
  } else if (!kebabCheck(fm.name)) {
    issues.push({ severity: "error", message: `name "${fm.name}" must be kebab-case` });
  } else if (fm.name.length > 64) {
    issues.push({ severity: "error", message: `name too long (${fm.name.length} > 64)` });
  }

  // description
  if (!fm.description) {
    issues.push({ severity: "error", message: "Missing 'description' in frontmatter" });
  } else if (fm.description.includes("<") || fm.description.includes(">")) {
    issues.push({ severity: "error", message: "description must not contain angle brackets" });
  } else if (fm.description.length > 1024) {
    issues.push({ severity: "warn", message: `description too long (${fm.description.length} > 1024)` });
  } else if (fm.description.includes("[TODO")) {
    issues.push({ severity: "warn", message: "description still contains [TODO]" });
  }

  return issues;
}

// --- main ---

async function main() {
  const dir = process.argv[2] || ".";
  const resolved = join(process.cwd(), dir);

  const issues = validate(resolved);
  const errors = issues.filter((i) => i.severity === "error");
  const warns = issues.filter((i) => i.severity === "warn");

  if (errors.length || warns.length) {
    for (const e of errors) console.log(`✗ ${e.message}`);
    for (const w of warns) console.log(`⚠ ${w.message}`);
  } else {
    console.log("✓ All checks passed.");
  }

  process.exit(errors.length > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});

# AGENTS.md

Scope: entire `jc_overlay` repository.

## Gentoo Overlay Rules

- Treat this repo as a Gentoo overlay; keep changes small and package-scoped.
- Before editing an ebuild, inspect its package directory, `metadata.xml`, and `Manifest`.
- For version bumps, prefer carrying forward the existing ebuild with `git mv`/copy, then regenerate the package manifest with:
  - `pkgdev manifest <category/package>`
- Keep only the current ebuild for locally maintained packages unless the user asks to retain old versions.
- Do not commit, push, install, or run full builds unless explicitly requested.
- Use `pkgcheck scan <category/package>` when available after ebuild changes. If build/install verification is needed, ask first.
- Keep `SRC_URI`, `S`, `KEYWORDS`, `RESTRICT`, `QA_*`, and dependency changes justified by upstream or Gentoo policy.

## Subagents

- Main agent owns decomposition, file writes, merge/conflict control, final verification, and final answer.
- Subagents are read-only by default.
- Use subagents for parallel checks when useful: latest upstream version, ebuild QA, dependency/build risk, or review of changed package dirs.
- Assign one package or logical area per subagent. Do not let multiple subagents edit the same ebuild/package concurrently.
- If a subagent may edit, grant exact file scope and required verification commands.
- Subagent reports must include files read/changed, commands run, concrete evidence, risks, and suggested next step.
- Re-read source or rerun verification for any critical subagent claim before acting on it.

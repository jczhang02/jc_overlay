# Gentoo Overlay Package Skill

Use when user asks to add, update, bump, modify, or maintain software packages in this Gentoo overlay.

Triggers:
- 添加包 / 增加软件包
- 更新 ebuild / bump version
- 修改包 / 调整依赖 / 改 USE flag
- regenerate Manifest
- run pkgcheck
- Gentoo overlay package work

## Scope

Package-scoped Gentoo overlay maintenance:

- add new `category/package`
- bump existing ebuild to new upstream version
- rev-bump existing ebuild for Gentoo-side changes
- modify `DEPEND`, `RDEPEND`, `BDEPEND`, `IUSE`, `REQUIRED_USE`
- update `SRC_URI`, `S`, `KEYWORDS`, `RESTRICT`, `QA_*`
- create/update `metadata.xml`
- regenerate `Manifest`
- run package QA
- commit and push immediately after verification

## Sources To Prefer

Use upstream/Gentoo docs when unsure:

- Gentoo Devmanual: ebuild writing
- Gentoo Devmanual: Manifest
- Gentoo Devmanual: metadata.xml
- Gentoo Devmanual: ebuild revisions
- Gentoo Policy Guide: ebuild format
- pkgdev docs: `pkgdev manifest`
- pkgcheck docs: `pkgcheck scan`

## Repo Rules

- Keep changes small and package-scoped.
- Inspect before editing:
  - `git status --short`
  - package dir
  - current ebuilds
  - `metadata.xml`
  - `Manifest`
- Preserve existing overlay style.
- Do not change unrelated packages.
- Do not install or run full builds unless user explicitly asks.
- After any repo modification:
  - run smallest relevant verification
  - commit immediately
  - push immediately

## New Package Workflow

1. Identify category/package name.
2. Search existing references:
   - current overlay
   - Gentoo repo if available
   - upstream release/source
3. Create:
   - `<category>/<package>/<package>-<version>.ebuild`
   - `<category>/<package>/metadata.xml`
   - optional `files/` for small patches/config only
4. Validate ebuild basics:
   - `EAPI`
   - `DESCRIPTION`
   - `HOMEPAGE`
   - `SRC_URI`
   - `LICENSE`
   - `SLOT`
   - `KEYWORDS`
   - deps
   - install logic
5. Generate Manifest:
   - `pkgdev manifest <category/package>`
6. QA:
   - `pkgcheck scan <category/package>`
7. Commit + push.

## Version Bump Workflow

1. Find latest upstream version/tag/release.
2. Read changelog/release notes.
3. Compare package metadata:
   - required node/python/go/rust/etc version
   - build system changes
   - dependency changes
   - source archive changes
   - license changes
4. Carry forward current ebuild:
   - `git mv old.ebuild new.ebuild`
   - or copy if retaining old version is needed
5. Keep only current ebuild for locally maintained packages unless user asks otherwise.
6. Adjust ebuild only with evidence.
7. Regenerate Manifest:
   - `pkgdev manifest <category/package>`
8. Run QA:
   - `pkgcheck scan <category/package>`
9. Commit + push.

## Rev-Bump Workflow

Use `-rX` for Gentoo-side changes when installed users need rebuild/reinstall or change is non-trivial.

Examples:
- dependency fix
- runtime fix
- installed files changed
- patch added
- QA/runtime behavior changed

Rules:
- Use upstream version bump for upstream release changes.
- Use `-r1`, `-r2`, etc. for Gentoo-side changes.
- Base new revision on previous revision so fixes are not dropped.
- Decide whether to keep old revision based on breakage risk and repo policy.

## Manifest Rules

- `Manifest` records distfile size and hashes.
- Regenerate with:
  - `pkgdev manifest <category/package>`
- If upstream changes distfile content without filename/version change:
  - stop
  - investigate
  - compare old/new distfiles
  - explain in commit message
  - prefer rev-bump if built package changes
- For fetch-restricted packages, use relevant `pkgdev manifest` options only with reason.

## metadata.xml Rules

- Existing/new packages should have `metadata.xml`.
- Include:
  - maintainer
  - useful longdescription when helpful
  - local USE flags under `<use>`
  - upstream remote-id when known
- Validate XML if edited heavily:
  - `xmllint --noout --valid metadata.xml`

## Ebuild Format Rules

- `KEYWORDS` one line, literal content.
- Add keywords only for arches tested or intentionally accepted by overlay policy.
- Do not use `${HOMEPAGE}` inside `SRC_URI`; repeat URL literally.
- Keep `SRC_URI`, `S`, `RESTRICT`, `QA_*` justified.
- In EAPI 8, remember `RESTRICT` accumulates with eclasses.
- Use EAPI 8 selective `fetch+` / `mirror+` only when needed and justified.
- Use `QA_PREBUILT` only for intentional prebuilt binaries installed by package.

## Verification

Minimum:

```sh
pkgdev manifest <category/package>
pkgcheck scan <category/package>
git diff --stat
git diff
```

Optional when relevant:

```sh
pkgcheck scan --net <category/package>
pkgcheck scan --staged
pkgcheck scan --commits
xmllint --noout --valid <category/package>/metadata.xml
```

Ask before:

```sh
emerge -av <category/package>
ebuild <ebuild> compile
ebuild <ebuild> install
```

## Commit Rules

After smallest relevant verification passes or known warnings are documented:

```sh
git add -A <category/package>
git commit -m "<category>/<package>: bump to <version>"
git push origin main
```

Commit message patterns:

- `<category>/<package>: add <version>`
- `<category>/<package>: bump to <version>`
- `<category>/<package>: revbump to <version>-r1`
- `<category>/<package>: update dependencies`
- `<category>/<package>: fix install`

## Report Format

Report concise:

- Package:
- Version:
- Changed files:
- Upstream changelog:
- Verification:
- pkgcheck warnings:
- Commit:
- Push:
- Residual risk:

## Guardrails

- Do not hide warnings.
- Do not weaken deps/keywords/restrict/QA settings without evidence.
- Do not update Manifest blindly if same distfile name hash changed.
- Do not run full build/install without explicit user approval.
- If upstream changelog unavailable, say so and use commit diff/release assets as evidence.

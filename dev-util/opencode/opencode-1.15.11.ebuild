# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# opencode pins its bun toolchain via packageManager in root package.json.
# Verify after each version bump that this matches root package.json's
# packageManager field; bumping opencode without bumping BUN_PV will fail
# the script/index.ts version-range check.
BUN_PV="1.3.14"

DESCRIPTION="AI coding agent built for the terminal"
HOMEPAGE="https://opencode.ai https://github.com/sst/opencode"
BUN_BASE="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_PV}"
SRC_URI="
	https://github.com/sst/opencode/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	amd64? (
		${BUN_BASE}/bun-linux-x64.zip
			-> bun-${BUN_PV}-linux-x64.zip
	)
	arm64? (
		${BUN_BASE}/bun-linux-aarch64.zip
			-> bun-${BUN_PV}-linux-aarch64.zip
	)
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# bun install pulls from npm/jsr at compile time; bun --compile output
# embeds a bunfs section that portage strip would corrupt.
RESTRICT="network-sandbox mirror test strip"

BDEPEND="
	app-arch/unzip
	app-arch/zip
	app-arch/tar
"

QA_PREBUILT="usr/bin/opencode"

# Backport of anomalyco/opencode PR #25886 — retry OpenAI overload stream
# errors (server_is_overloaded / service_unavailable_error) instead of
# terminating the turn with a final "OpenAI Responses stream error".
PATCHES=(
	"${FILESDIR}/${PN}-1.15.11-retry-overload-25886.patch"
)

src_unpack() {
	# Unpack only the opencode tarball; the bun zip is staged manually
	# under ${T}/bun so it doesn't pollute ${S}.
	unpack "${P}.tar.gz"

	local bun_zip
	case ${ARCH} in
		amd64) bun_zip="bun-${BUN_PV}-linux-x64.zip" ;;
		arm64) bun_zip="bun-${BUN_PV}-linux-aarch64.zip" ;;
		*) die "unsupported ARCH=${ARCH}" ;;
	esac

	mkdir -p "${T}/bun" || die
	pushd "${T}/bun" > /dev/null || die
	unzip -q "${DISTDIR}/${bun_zip}" || die "bun zip extract failed"
	# zip layout: bun-linux-{x64,aarch64}/bun
	local extracted
	extracted=$(find . -maxdepth 2 -name bun -type f -executable | head -n1)
	[[ -n ${extracted} ]] || die "bun binary not found inside zip"
	mv "${extracted}" bun || die
	chmod +x bun || die
	popd > /dev/null
}

src_compile() {
	# Sandbox all caches under ${T}.
	export BUN_INSTALL_CACHE_DIR="${T}/bun-cache"
	export HOME="${T}/home"
	export XDG_CACHE_HOME="${T}/cache"
	export npm_config_cache="${T}/npm-cache"
	mkdir -p "${HOME}" "${XDG_CACHE_HOME}" "${BUN_INSTALL_CACHE_DIR}" \
		"${npm_config_cache}" || die

	# Vendored bun goes first so opencode's packageManager check passes.
	export PATH="${T}/bun:${PATH}"

	# packages/script/src/index.ts derives CHANNEL via `git branch
	# --show-current` when OPENCODE_CHANNEL is unset. The release
	# tarball has no .git tree, so pin both channel and version.
	export OPENCODE_CHANNEL="latest"
	export OPENCODE_VERSION="${PV}"

	einfo "Using bun $(bun --version) from ${T}/bun"

	einfo "Installing workspace dependencies (bun)"
	bun install --frozen-lockfile \
		|| bun install \
		|| die "bun install failed"

	einfo "Building opencode binary for current host (bun --compile, --single)"
	# --single restricts build to host os/arch; baseline/musl variants skipped.
	# --skip-install: deps already installed at workspace root above.
	bun run --cwd packages/opencode build --single --skip-install \
		|| die "opencode build failed"
}

src_install() {
	local arch
	case ${ARCH} in
		amd64) arch=x64 ;;
		arm64) arch=arm64 ;;
		*) die "unsupported ARCH=${ARCH}" ;;
	esac

	local distdir="packages/opencode/dist/opencode-linux-${arch}"
	local bin="${distdir}/bin/opencode"

	[[ -x ${bin} ]] || die "expected binary not produced: ${bin}"

	exeinto /usr/bin
	doexe "${bin}"

	local d
	for d in README.md LICENSE CHANGELOG.md; do
		[[ -f ${d} ]] && dodoc "${d}"
	done
}

pkg_postinst() {
	elog "opencode ${PV} installed as /usr/bin/opencode."
	elog
	elog "Experimental flags (all gated by enabledByExperimental — either"
	elog "the global OPENCODE_EXPERIMENTAL=true flips them all on, or the"
	elog "specific OPENCODE_EXPERIMENTAL_<NAME>=true flips just one):"
	elog
	elog "  OPENCODE_EXPERIMENTAL_WORKSPACES         multi-workspace mode"
	elog "  OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS  background subagent tasks"
	elog "  OPENCODE_EXPERIMENTAL_NATIVE_LLM         native OpenAI/Anthropic runtime path"
	elog "  OPENCODE_EXPERIMENTAL_PLAN_MODE          plan mode"
	elog "  OPENCODE_EXPERIMENTAL_EVENT_SYSTEM       new event system"
	elog "  OPENCODE_EXPERIMENTAL_SCOUT              scout agent"
	elog "  OPENCODE_EXPERIMENTAL_LSP_TOOL           LSP tool"
	elog "  OPENCODE_EXPERIMENTAL_OXFMT              oxfmt formatter"
	elog "  OPENCODE_EXPERIMENTAL_ICON_DISCOVERY     icon discovery"
	elog
	elog "Workspace mode is referenced from src/sync, src/session,"
	elog "src/control-plane/workspace, and the TUI prompt/session-list dialogs."
	elog "Full flag list: packages/opencode/src/effect/runtime-flags.ts"
	elog
	elog "New interactive run flags:"
	elog "  opencode run --replay [--replay-limit N]   replay recent history on resume"
	elog "  opencode run --shell                       shell mode in run prompt (1.15.6+)"
	elog
	elog "Since 1.15.5:"
	elog "  1.15.6  TUI diff viewer (file tree), Anthropic native runtime, V2 API error schema"
	elog "  1.15.7  Grok OAuth + device-code login, PDF attachments for Grok"
	elog "  1.15.9  Diff viewer redesign (default-on), MCP OAuth scopes/callbackPort,"
	elog "          Vertex Anthropic multi-region endpoint fix"
	elog "  1.15.10 Restored legacy desktop project/session flows"
	elog "  1.15.11 OpenAI headerTimeout opt-in, plugin dispose hook, restored remote project identity"
	elog
	elog "NOTE: OpenAI overload stream-retry fix (PR #25886) still NOT upstream"
	elog "as of 1.15.11 — applied here via local backport patch."
}

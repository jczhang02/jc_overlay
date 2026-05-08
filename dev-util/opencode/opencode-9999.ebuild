# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="AI coding agent built for the terminal (live build from sst/opencode)"
HOMEPAGE="https://opencode.ai https://github.com/sst/opencode"

EGIT_REPO_URI="https://github.com/sst/opencode.git"
EGIT_BRANCH="dev"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""

# bun install + bun build pull from npm/jsr at compile time.
RESTRICT="network-sandbox mirror test strip"

# Bun-compiled single-file binary embeds its own runtime; only libc is
# required at runtime, satisfied by virtual/libc on any Gentoo system.

BDEPEND="
	net-libs/bun-bin
	app-arch/zip
	app-arch/tar
"

# bun-compile produces a stripped, embedded binary; portage strip would
# damage the bunfs section, hence RESTRICT=strip + QA_PREBUILT mask.
QA_PREBUILT="usr/bin/opencode"

src_unpack() {
	git-r3_src_unpack

	# Pull required submodules (tree-sitter grammars, etc.) if upstream
	# uses them. Safe no-op when none are declared.
	cd "${S}" || die
	if [[ -f .gitmodules ]]; then
		git submodule update --init --recursive --depth 1 \
			|| die "submodule update failed"
	fi
}

src_compile() {
	# Sandbox all caches under ${T}.
	export BUN_INSTALL_CACHE_DIR="${T}/bun-cache"
	export HOME="${T}/home"
	export XDG_CACHE_HOME="${T}/cache"
	export npm_config_cache="${T}/npm-cache"
	mkdir -p "${HOME}" "${XDG_CACHE_HOME}" "${BUN_INSTALL_CACHE_DIR}" \
		"${npm_config_cache}" || die

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

	# Ship docs if present at repo root.
	local d
	for d in README.md LICENSE CHANGELOG.md; do
		[[ -f ${d} ]] && dodoc "${d}"
	done
}

pkg_postinst() {
	elog "opencode installed as /usr/bin/opencode (live build)."
	elog
	elog "Experimental multi-workspace mode is gated by an env flag:"
	elog "  export OPENCODE_EXPERIMENTAL_WORKSPACES=true"
	elog "Set it before launching opencode to enable Flag.OPENCODE_EXPERIMENTAL_WORKSPACES"
	elog "(referenced from src/sync, src/session, src/control-plane/workspace,"
	elog "and the TUI prompt/session-list dialogs)."
}

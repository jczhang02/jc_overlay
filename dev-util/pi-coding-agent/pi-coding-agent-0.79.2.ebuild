# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# pi-mono does not pin a packageManager field, so bun version is selected
# locally. Keep aligned with dev-util/opencode where practical so the bun
# distfile is shared across the overlay.
BUN_PV="1.3.14"

DESCRIPTION="A terminal-based coding agent with multi-model support (built from source)"
HOMEPAGE="https://github.com/earendil-works/pi https://buildwithpi.ai"

BUN_BASE="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_PV}"
SRC_URI="
	https://github.com/earendil-works/pi/archive/refs/tags/v${PV}.tar.gz
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
S="${WORKDIR}/pi-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="+system-fd"

# npm install pulls dependencies from the network and bun --compile embeds a
# bunfs section that portage strip would corrupt.
RESTRICT="network-sandbox mirror test strip"

BDEPEND="
	>=net-libs/nodejs-20.6.0[npm]
	app-arch/unzip
	app-arch/tar
"

RDEPEND="
	system-fd? ( sys-apps/fd )
	!dev-util/pi-coding-agent-bin
"

QA_PREBUILT="opt/${PN}/pi"

src_unpack() {
	# Unpack only the pi source tarball; the bun zip is staged manually
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
	export HOME="${T}/home"
	export XDG_CACHE_HOME="${T}/cache"
	export npm_config_cache="${T}/npm-cache"
	export BUN_INSTALL_CACHE_DIR="${T}/bun-cache"
	mkdir -p "${HOME}" "${XDG_CACHE_HOME}" "${npm_config_cache}" \
		"${BUN_INSTALL_CACHE_DIR}" || die

	# Vendored bun first so packages/coding-agent build:binary can call it.
	export PATH="${T}/bun:${PATH}"

	einfo "Using bun $(bun --version) from ${T}/bun"
	einfo "Using node $(node --version) and npm $(npm --version)"

	# Install full monorepo workspace deps (tsgo, biome, all packages/*).
	# The build:binary script of packages/coding-agent expects sibling
	# workspaces (tui, ai, agent) to be built and node_modules populated.
	einfo "Installing workspace dependencies (npm install)"
	npm install --no-audit --no-fund --foreground-scripts \
		|| die "npm install failed at monorepo root"

	# Build the single-file binary via upstream's build:binary script.
	# Steps performed by that script:
	#   1. tsgo build packages/{tui,ai,agent}
	#   2. tsgo build packages/coding-agent (emits dist/cli.js, dist/bun/cli.js)
	#   3. bun build --compile dist/bun/cli.js plus image worker -> dist/pi
	#   4. copy-binary-assets: theme, assets, docs, examples, photon WASM
	einfo "Building pi single-file binary (bun --compile via build:binary)"
	npm --prefix packages/coding-agent run build:binary \
		|| die "pi build:binary failed"
}

src_install() {
	local distdir="packages/coding-agent/dist"
	local bin="${distdir}/pi"

	[[ -x ${bin} ]] || die "expected binary not produced: ${bin}"

	# Mirror the layout of dev-util/pi-coding-agent-bin from gentoo-zh so
	# both ebuilds collide cleanly and either can satisfy /opt/bin/pi.
	insinto /opt/${PN}
	doins -r "${distdir}"/.
	fperms +x /opt/${PN}/pi

	dosym ../${PN}/pi /opt/bin/pi

	local d
	for d in README.md LICENSE CHANGELOG.md; do
		[[ -f ${d} ]] && dodoc "${d}"
	done
}

pkg_postinst() {
	elog "pi ${PV} installed as /opt/bin/pi (built from source via bun --compile)."
	elog
	elog "Configuration lives under ~/.pi/agent/ (settings.json, models.json,"
	elog "extensions/, sessions/). See:"
	elog "  /opt/${PN}/docs/settings.md"
	elog "  /opt/${PN}/docs/extensions.md"
	elog "  /opt/${PN}/docs/models.md"
	elog
	elog "Optional runtime: USE=system-fd pulls in sys-apps/fd for the find tool."
}

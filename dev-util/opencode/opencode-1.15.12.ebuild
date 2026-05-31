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
	elog "Stock upstream build, no carried patches."
}

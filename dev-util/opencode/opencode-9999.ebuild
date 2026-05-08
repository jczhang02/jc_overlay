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

# bun install + bun build + dynamic bun toolchain fetch all need network.
RESTRICT="network-sandbox mirror test strip"

BDEPEND="
	app-arch/unzip
	app-arch/zip
	app-arch/tar
	net-misc/curl
"

QA_PREBUILT="usr/bin/opencode"

src_unpack() {
	git-r3_src_unpack
	cd "${S}" || die
	if [[ -f .gitmodules ]]; then
		git submodule update --init --recursive --depth 1 \
			|| die "submodule update failed"
	fi
}

src_compile() {
	export BUN_INSTALL_CACHE_DIR="${T}/bun-cache"
	export HOME="${T}/home"
	export XDG_CACHE_HOME="${T}/cache"
	export npm_config_cache="${T}/npm-cache"
	mkdir -p "${HOME}" "${XDG_CACHE_HOME}" "${BUN_INSTALL_CACHE_DIR}" \
		"${npm_config_cache}" "${T}/bun" || die

	# opencode pins bun via packageManager in root package.json. Read it
	# back so the live build always matches whatever upstream ships.
	local bun_pv
	bun_pv=$(sed -n 's/.*"packageManager"[[:space:]]*:[[:space:]]*"bun@\([0-9.]*\)".*/\1/p' \
		"${S}/package.json")
	[[ -n ${bun_pv} ]] || die "could not read packageManager bun version from package.json"
	einfo "Upstream pins bun@${bun_pv}"

	local bun_zip_name bun_inner_dir
	case ${ARCH} in
		amd64) bun_zip_name="bun-linux-x64.zip"; bun_inner_dir="bun-linux-x64" ;;
		arm64) bun_zip_name="bun-linux-aarch64.zip"; bun_inner_dir="bun-linux-aarch64" ;;
		*) die "unsupported ARCH=${ARCH}" ;;
	esac

	einfo "Fetching bun ${bun_pv} (${bun_zip_name})"
	curl -fSL --retry 3 \
		-o "${T}/${bun_zip_name}" \
		"https://github.com/oven-sh/bun/releases/download/bun-v${bun_pv}/${bun_zip_name}" \
		|| die "bun download failed"

	pushd "${T}/bun" > /dev/null || die
	unzip -q "${T}/${bun_zip_name}" || die "bun zip extract failed"
	mv "${bun_inner_dir}/bun" bun || die "bun binary missing in zip"
	chmod +x bun || die
	rm -rf "${bun_inner_dir}"
	popd > /dev/null

	export PATH="${T}/bun:${PATH}"

	einfo "Using bun $(bun --version) from ${T}/bun"

	einfo "Installing workspace dependencies (bun)"
	bun install --frozen-lockfile \
		|| bun install \
		|| die "bun install failed"

	einfo "Building opencode binary for current host (bun --compile, --single)"
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
	elog "opencode installed as /usr/bin/opencode (live build)."
	elog
	elog "Experimental multi-workspace mode is gated by an env flag:"
	elog "  export OPENCODE_EXPERIMENTAL_WORKSPACES=true"
	elog "Set it before launching opencode to enable Flag.OPENCODE_EXPERIMENTAL_WORKSPACES"
	elog "(referenced from src/sync, src/session, src/control-plane/workspace,"
	elog "and the TUI prompt/session-list dialogs)."
}

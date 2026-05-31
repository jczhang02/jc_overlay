# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="${PN%-bin}"

DESCRIPTION="Fast all-in-one JavaScript runtime, bundler, transpiler and package manager"
HOMEPAGE="https://bun.sh https://github.com/oven-sh/bun"

# Upstream ships prebuilt zips. The plain x64/aarch64 variants require a
# modern CPU (x64 needs AVX2); the *-baseline variant covers older CPUs.
BUN_BASE="https://github.com/oven-sh/${MY_PN}/releases/download/${MY_PN}-v${PV}"
SRC_URI="
	amd64? (
		cpu_flags_x86_avx2? (
			${BUN_BASE}/bun-linux-x64.zip
				-> ${MY_PN}-${PV}-linux-x64.zip
		)
		!cpu_flags_x86_avx2? (
			${BUN_BASE}/bun-linux-x64-baseline.zip
				-> ${MY_PN}-${PV}-linux-x64-baseline.zip
		)
	)
	arm64? (
		${BUN_BASE}/bun-linux-aarch64.zip
			-> ${MY_PN}-${PV}-linux-aarch64.zip
	)
"

S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="cpu_flags_x86_avx2"

# Upstream ships only glibc-linked Linux binaries here (musl variants exist
# under different asset names but are not wired up).
REQUIRED_USE="elibc_glibc"

# Prebuilt binary; portage strip risks corrupting the embedded runtime.
RESTRICT="mirror strip"

BDEPEND="app-arch/unzip"

QA_PREBUILT="usr/bin/${MY_PN}"

src_unpack() {
	local zip
	case ${ARCH} in
		amd64)
			if use cpu_flags_x86_avx2; then
				zip="${MY_PN}-${PV}-linux-x64.zip"
			else
				zip="${MY_PN}-${PV}-linux-x64-baseline.zip"
			fi
			;;
		arm64) zip="${MY_PN}-${PV}-linux-aarch64.zip" ;;
		*) die "unsupported ARCH=${ARCH}" ;;
	esac

	unzip -q "${DISTDIR}/${zip}" -d "${S}" || die "bun zip extract failed"

	# zip layout: bun-linux-{x64,x64-baseline,aarch64}/bun
	local extracted
	extracted=$(find "${S}" -maxdepth 2 -name bun -type f | head -n1)
	[[ -n ${extracted} ]] || die "bun binary not found inside zip"
	mv "${extracted}" "${S}/bun" || die
	chmod +x "${S}/bun" || die
}

src_install() {
	dobin "${S}/bun"
	# bunx is the canonical alias upstream installs alongside bun.
	dosym bun /usr/bin/bunx
}

pkg_postinst() {
	elog "bun ${PV} installed as /usr/bin/bun (with bunx symlink)."
	elog
	elog "On older CPUs lacking AVX2, build with USE=-cpu_flags_x86_avx2"
	elog "to fetch the baseline variant."
}

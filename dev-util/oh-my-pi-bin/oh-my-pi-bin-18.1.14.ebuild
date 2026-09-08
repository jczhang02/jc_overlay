# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="${PN%-bin}"

DESCRIPTION="Terminal AI coding agent with native tools, subagents, and MCP support"
HOMEPAGE="https://github.com/can1357/oh-my-pi"
SRC_URI="
	amd64? (
		https://github.com/can1357/oh-my-pi/releases/download/v${PV}/omp-linux-x64
			-> ${MY_PN}-${PV}-linux-x64
	)
	https://github.com/can1357/oh-my-pi/releases/download/v${PV}/LICENSE
		-> ${MY_PN}-${PV}-LICENSE
	https://github.com/can1357/oh-my-pi/releases/download/v${PV}/THIRD-PARTY-NOTICES.txt
		-> ${MY_PN}-${PV}-THIRD-PARTY-NOTICES.txt
"
S="${WORKDIR}"

# Includes bundled JS/Rust dependencies and the Bun/JavaScriptCore runtime.
LICENSE="MIT 0BSD Apache-2.0 BSD BSD-2 BlueOak-1.0.0 Boost-1.0
	CC-BY-4.0 CC0-1.0 CDDL ISC LGPL-2 LGPL-2.1 openssl Unicode-3.0 WTFPL-2 ZLIB"
SLOT="0"
KEYWORDS="-* ~amd64"
REQUIRED_USE="elibc_glibc"

# Stripping Bun's compiled executable can corrupt its embedded payload.
RESTRICT="mirror strip"
QA_PREBUILT="usr/bin/omp"

RDEPEND="
	>=sys-libs/glibc-2.17
	sys-devel/gcc[cxx]
"

src_unpack() {
	# Release assets are plain files, not archives.
	cp "${DISTDIR}/${MY_PN}-${PV}-linux-x64" omp || die
	cp "${DISTDIR}/${MY_PN}-${PV}-LICENSE" LICENSE || die
	cp "${DISTDIR}/${MY_PN}-${PV}-THIRD-PARTY-NOTICES.txt" THIRD-PARTY-NOTICES.txt || die
	chmod +x omp || die
}

src_install() {
	dobin omp
	dodoc LICENSE THIRD-PARTY-NOTICES.txt
}

pkg_postinst() {
	elog "Run 'omp' to start Oh My Pi, then /login to configure a provider."
	elog "Optional features may download additional runtimes or models into your user cache."
	elog "Use Portage, rather than 'omp update', to update this installation."
}

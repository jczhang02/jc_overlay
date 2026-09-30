# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="${PN%-bin}"

DESCRIPTION="The front-end to your dev env"
HOMEPAGE="https://mise.jdx.dev https://github.com/jdx/mise"
SRC_URI="
	amd64? (
		https://github.com/jdx/${MY_PN}/releases/download/v${PV}/${MY_PN}-v${PV}-linux-x64.tar.xz
			-> ${P}-linux-x64.tar.xz
	)
	arm64? (
		https://github.com/jdx/${MY_PN}/releases/download/v${PV}/${MY_PN}-v${PV}-linux-arm64.tar.xz
			-> ${P}-linux-arm64.tar.xz
	)
"

S="${WORKDIR}/${MY_PN}"

# Bundled crate licenses, as listed by the source ebuild.
LICENSE="
	Apache-2.0 BSD-2 BSD CC0-1.0 CDLA-Permissive-2.0 ISC MIT MPL-2.0
	openssl Unicode-3.0 ZLIB BZIP2
"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

# Upstream also ships musl builds, but only the glibc ones are wired up here.
REQUIRED_USE="elibc_glibc"

RDEPEND="!dev-util/mise"

RESTRICT="mirror"

QA_PREBUILT="usr/bin/${MY_PN}"

src_install() {
	dobin bin/${MY_PN}
	doman man/man1/${MY_PN}.1
	einstalldocs
}

pkg_postinst() {
	elog "Activate mise in your shell, e.g. for zsh add to ~/.zshrc:"
	elog "  eval \"\$(mise activate zsh)\""
}

# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="${PN%-bin}"

DESCRIPTION="AI agent for plan/PR review with browser-driven annotations"
HOMEPAGE="https://github.com/backnotprop/plannotator"
SRC_URI="
	amd64? (
		https://github.com/backnotprop/${MY_PN}/releases/download/v${PV}/${MY_PN}-linux-x64
			-> ${MY_PN}-${PV}-linux-x64
	)
"

S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64"

# Upstream ships a bun --compile single-file binary (embedded bunfs +
# bun runtime). Portage strip would corrupt the bunfs section.
RESTRICT="mirror strip"

# Upstream ships only a glibc-linked Linux binary (no musl variant).
REQUIRED_USE="elibc_glibc"

QA_PREBUILT="usr/bin/${MY_PN}"

src_unpack() {
	# Plain ELF, no archive container — copy from DISTDIR into ${S}
	# so dobin can pick it up without portage trying to unpack it.
	cp "${DISTDIR}/${MY_PN}-${PV}-linux-x64" "${S}/${MY_PN}" \
		|| die "could not stage ${MY_PN} from DISTDIR"
	chmod +x "${S}/${MY_PN}" || die
}

src_install() {
	dobin "${MY_PN}"
}

pkg_postinst() {
	elog "plannotator ${PV} installed as /usr/bin/${MY_PN}."
	elog
	elog "Quick start:"
	elog "  plannotator --help"
	elog "  plannotator review <pr_url>"
	elog "  plannotator annotate <file_or_url>"
}

# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Proxy exposing CLI AI models as OpenAI/Gemini/Claude compatible API"
HOMEPAGE="https://github.com/router-for-me/CLIProxyAPI"

MY_PN="CLIProxyAPI"
SRC_URI="https://github.com/router-for-me/${MY_PN}/releases/download/v${PV}/${MY_PN}_${PV}_linux_amd64.tar.gz"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="mirror strip"

QA_PREBUILT="usr/bin/cli-proxy-api"

RDEPEND="
	!net-misc/cli-proxy-api
"

src_install() {
	dobin cli-proxy-api

	insinto /etc/cli-proxy-api
	newins config.example.yaml config.yaml.example

	systemd_douserunit "${FILESDIR}"/cli-proxy-api.service

	dodoc README.md
}

pkg_postinst() {
	elog "Copy the example config and edit it:"
	elog "  mkdir -p ~/.cli-proxy-api"
	elog "  cp /etc/cli-proxy-api/config.yaml.example ~/.cli-proxy-api/config.yaml"
	elog ""
	elog "Enable the systemd user service:"
	elog "  systemctl --user enable --now cli-proxy-api"
}

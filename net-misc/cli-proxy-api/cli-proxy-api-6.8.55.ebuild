# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd

DESCRIPTION="Proxy exposing CLI AI models as OpenAI/Gemini/Claude compatible API"
HOMEPAGE="https://github.com/router-for-me/CLIProxyAPI"
SRC_URI="https://github.com/router-for-me/CLIProxyAPI/archive/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/CLIProxyAPI-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="network-sandbox mirror"

BDEPEND=">=dev-lang/go-1.26"

src_compile() {
	ego build -o cli-proxy-api \
		-ldflags "-s -w \
			-X main.Version=${PV} \
			-X main.Commit=gentoo \
			-X main.BuildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		./cmd/server
}

src_install() {
	dobin cli-proxy-api

	insinto /etc/cli-proxy-api
	newins config.example.yaml config.yaml.example

	systemd_douserunit "${FILESDIR}"/cli-proxy-api.service

	dodoc README.md
}

pkg_postinst() {
	elog "To configure cli-proxy-api, copy the example config:"
	elog "  mkdir -p ~/.cli-proxy-api"
	elog "  cp /etc/cli-proxy-api/config.yaml.example ~/.cli-proxy-api/config.yaml"
	elog ""
	elog "A systemd user service is provided. Enable it with:"
	elog "  systemctl --user enable --now cli-proxy-api"
	elog ""
	elog "Default API port: 8317"
}

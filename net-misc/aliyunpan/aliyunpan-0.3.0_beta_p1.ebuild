# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

HOMEPAGE="https://github.com/tickstep/aliyunpan"
DESCRIPTION="aliyunpan cli client, support Webdav service, JavaScript plugin"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* ~amd64"
SRC_URI="https://github.com/tickstep/aliyunpan/files/14493944/aliyunpan-v0.3.0-Beta1-linux-amd64.zip"
S="${WORKDIR}/aliyunpan-v0.3.0-Beta1-linux-amd64"

src_install() {
	dobin ${PN}
}

pkg_postinst() {
	elog "if you see \"FATAL ERROR: config file error: config file permission denied\""
	elog "try \"mkdir ~/.aliyunpan\""
	elog "from version 0.3.0, you need login via web api"
}

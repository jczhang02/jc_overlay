# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

EGIT_REPO_URI="https://github.com/palinek/${PN}.git"

inherit git-r3 cmake

DESCRIPTION="A simple Qt-based NetworkManager front-end"
HOMEPAGE="https://github.com/palinek/nm-tray"

SRC_URL=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE=""

BDEPEND="
	dev-qt/linguist-tools:5
	>=dev-util/cmake-3.10
"
RDEPEND="
	dev-qt/qtcore:5
	dev-qt/qtdbus:5
	dev-qt/qtgui:5
	dev-qt/qtnetwork:5
	dev-qt/qtwidgets:5
	kde-frameworks/networkmanager-qt
"
DEPEND="${RDEPEND}"

src_unpack() {
	git-r3_src_unpack
}

src_configure() {
	local mycmakeargs=(
		-DNM_TRAY_XDG_AUTOSTART_DIR=/etc/xdg/autostart
	)

	cmake_src_configure
}

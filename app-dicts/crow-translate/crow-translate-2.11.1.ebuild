# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="A simple and lightweight translator."
HOMEPAGE="https://github.com/crow-translate/crow-translate"
SRC_URI="
	https://github.com/crow-translate/crow-translate/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/crow-translate/crow-translate/releases/download/${PV}/crow-translate-${PV}-source.tar.gz -> ${P}-source.tar.gz
"

LICENSE="GPL-3"
SLOT="0"
# KEYWORDS="~amd64"
KEYWORDS=""

IUSE="+portable wayland"

DEPEND="
	app-text/tesseract
	kde-frameworks/extra-cmake-modules
	dev-qt/qtwidgets
	dev-qt/qtnetwork
	dev-qt/qtmultimedia
	dev-qt/qtconcurrent
	dev-qt/qtx11extras
	dev-qt/qtdbus
	dev-build/cmake
	wayland? (
		kde-plasma/kwayland
	)
"
RDEPEND="${DEPEND}"
BDEPEND=""

src_prepare() {
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=OFF
		-WITH_PORTABLE_MODE=$(usex portable)
		-WITH_KWAYLAND=$(usex wayland)
	)
	cmake_src_configure
}

# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake readme.gentoo-r1

DESCRIPTION="Simple fan control program for thinkpads"
HOMEPAGE="https://github.com/vmatare/thinkfan"

COMMIT="b1ad819e4ec79776cb5ccc61e2206a0c5d506ef5"
SRC_URI="https://github.com/vmatare/thinkfan/archive/${COMMIT}.tar.gz -> ${P}-${COMMIT}.tar.gz"

echo $SRC_URI

S="${WORKDIR}/${PN}-${COMMIT}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="atasmart nvidia +yaml +lm-sensors"

DEPEND="atasmart? ( dev-libs/libatasmart )
	yaml? ( dev-cpp/yaml-cpp )
	lm-sensors? ( sys-apps/lm-sensors )"

RDEPEND="${DEPEND}
	nvidia? ( x11-drivers/nvidia-drivers )"

DOC_CONTENTS="
	Please read the documentation and copy an appropriate
	file to /etc/thinkfan.conf.
"

src_configure() {
	local mycmakeargs=(
		-DCMAKE_INSTALL_DOCDIR=/usr/share/doc/${PF}
		-DUSE_NVML="$(usex nvidia)"
		-DUSE_LM_SENSORS=$(usex lm-sensors)
		-DUSE_ATASMART="$(usex atasmart)"
		-DUSE_YAML="$(usex yaml)"
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	readme.gentoo_create_doc
}

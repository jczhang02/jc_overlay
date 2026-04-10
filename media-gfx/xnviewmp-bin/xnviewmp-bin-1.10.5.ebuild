# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="Versatile and powerful photo viewer, image management, and image resizer"
HOMEPAGE="https://www.xnview.com/en/xnviewmp/"
SRC_URI="https://download.xnview.com/old_versions/XnView_MP/XnView_MP-${PV}-linux-x64.tgz"

LICENSE="freedist XnView"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="bindist mirror strip"

RDEPEND="
	dev-libs/glib:2
	media-libs/freetype
	sys-libs/glibc
	x11-libs/libX11
	x11-libs/libXi
	x11-libs/libXt
"

S="${WORKDIR}/XnView"

QA_PREBUILT="opt/XnView/*"

PATCHES=(
	"${FILESDIR}/xnviewmp-bin-fix-ld-path.patch"
)

src_install() {
	local dest=/opt/XnView

	insinto "${dest}"
	doins -r .

	fperms 0755 "${dest}"/XnView
	fperms 0755 "${dest}"/xnview.sh

	local f
	for f in "${ED}/${dest}"/lib/*.so* ; do
		[[ -f "${f}" ]] && fperms 0755 "${dest}/lib/${f##*/}"
	done
	for f in "${ED}/${dest}"/Plugins/*.so* ; do
		[[ -f "${f}" ]] && fperms 0755 "${dest}/Plugins/${f##*/}"
	done

	dosym "${dest}"/xnview.sh /usr/bin/xnviewmp

	newicon xnview.png xnviewmp.png
	make_desktop_entry xnviewmp "XnView MP" xnviewmp "Graphics;Viewer;Photography;"
}

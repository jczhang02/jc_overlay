# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker xdg

MY_PV="${PV}"
DESCRIPTION="Orchestrate coding agents remotely from your phone, desktop and CLI"
HOMEPAGE="https://paseo.sh https://github.com/getpaseo/paseo"
SRC_URI="https://github.com/getpaseo/paseo/releases/download/v${PV}/Paseo-${MY_PV}-amd64.deb"

S="${WORKDIR}"
LICENSE="AGPL-3+"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="bindist mirror strip"

RDEPEND="
	app-accessibility/at-spi2-core
	app-crypt/libsecret
	dev-libs/glib:2
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	sys-apps/dbus
	sys-apps/util-linux
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
	x11-themes/hicolor-icon-theme
"

QA_PREBUILT="opt/Paseo/*"

src_install() {
	insinto /opt/Paseo
	doins -r opt/Paseo/.

	fperms +x /opt/Paseo/Paseo
	fperms +x /opt/Paseo/chrome-sandbox
	fperms +x /opt/Paseo/chrome_crashpad_handler

	dobin "${FILESDIR}/paseo"

	domenu usr/share/applications/Paseo.desktop

	local size
	for size in 32 64 128; do
		newicon -s "${size}" \
			"usr/share/icons/hicolor/${size}x${size}/apps/Paseo.png" \
			Paseo.png
	done
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "Paseo is an Electron application installed under /opt/Paseo."
	elog "Launch via the desktop entry or the 'paseo' command."
	elog
	elog "If sandboxing fails, ensure user namespaces are enabled, or:"
	elog "  chmod u+s /opt/Paseo/chrome-sandbox"
}

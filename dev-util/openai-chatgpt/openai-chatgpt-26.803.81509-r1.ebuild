# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker xdg

DESCRIPTION="OpenAI's ChatGPT desktop app with ChatGPT Work and Codex"
HOMEPAGE="https://learn.chatgpt.com/docs/app"
SRC_BASE="https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt"
SRC_URI="
	amd64? ( ${SRC_BASE}/chatgpt_${PV}_amd64.deb )
	arm64? ( ${SRC_BASE}/chatgpt_${PV}_arm64.deb )
"

S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="apparmor"
REQUIRED_USE="elibc_glibc"

# OpenAI does not grant redistribution rights for the proprietary application.
# The payload contains prebuilt Electron, Codex, Node.js, and native modules.
RESTRICT="bindist mirror strip"

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-arch/tar
	app-arch/xz-utils
	app-crypt/libsecret
	app-shells/bash
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	dev-libs/wayland
	dev-vcs/git
	media-libs/alsa-lib
	media-libs/libglvnd
	media-libs/mesa
	net-print/cups
	sys-apps/coreutils
	sys-apps/dbus
	>=sys-libs/glibc-2.35
	virtual/libusb:1
	virtual/udev
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/pango
	x11-misc/xdg-utils
	amd64? (
		dev-libs/openssl:0/3
		media-gfx/graphite2
	)
	apparmor? ( >=sys-apps/apparmor-4.0 )
"

QA_PREBUILT="usr/lib/chatgpt/*"
# These optional integration shims are loaded only when the corresponding Qt
# version is present; requiring both Qt major versions would be inappropriate.
QA_SONAME="
	usr/lib/chatgpt/libqt5_shim.so
	usr/lib/chatgpt/libqt6_shim.so
"

src_unpack() {
	unpack_deb ${A}
}

src_install() {
	dodir /usr/lib/chatgpt
	cp -a usr/lib/chatgpt/. "${ED}/usr/lib/chatgpt/" \
		|| die "failed to install ChatGPT application payload"
	fowners -R root:root /usr/lib/chatgpt

	dosym ../lib/chatgpt/codex-launcher /usr/bin/chatgpt
	domenu usr/share/applications/chatgpt.desktop
	# hicolor does not universally register a 1024x1024 icon directory.
	doicon usr/share/pixmaps/chatgpt.png
	dodoc usr/share/doc/chatgpt/copyright

	if use apparmor; then
		insinto /etc/apparmor.d
		doins etc/apparmor.d/chatgpt
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	if use apparmor && [[ ${ROOT} == / ]] &&
		command -v aa-enabled > /dev/null &&
		command -v apparmor_parser > /dev/null && aa-enabled --quiet; then
		apparmor_parser -r -W -T "${EROOT}/etc/apparmor.d/chatgpt" \
			|| ewarn "failed to load the ChatGPT AppArmor profile"
	fi

	elog "ChatGPT ${PV} installed. Launch it with: chatgpt"
	elog "The desktop app includes ChatGPT Work and Codex."
	elog "OpenAI's Debian repository is intentionally not installed; Portage owns updates."
}

pkg_prerm() {
	if use apparmor && [[ ${ROOT} == / ]] &&
		command -v aa-enabled > /dev/null &&
		command -v apparmor_parser > /dev/null && aa-enabled --quiet; then
		apparmor_parser -R "${EROOT}/etc/apparmor.d/chatgpt" \
			|| ewarn "failed to unload the ChatGPT AppArmor profile"
	fi
}

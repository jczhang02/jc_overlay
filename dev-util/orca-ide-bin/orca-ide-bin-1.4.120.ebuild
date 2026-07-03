# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )

inherit python-single-r1 xdg-utils

DESCRIPTION="AI worktree IDE for parallel agentic development"
HOMEPAGE="https://www.onorca.dev https://github.com/stablyai/orca"
SRC_URI="
	amd64? (
		https://github.com/stablyai/orca/releases/download/v${PV}/orca-ide_${PV}_amd64.deb
			-> ${P}-amd64.deb
	)
	arm64? (
		https://github.com/stablyai/orca/releases/download/v${PV}/orca-ide_${PV}_arm64.deb
			-> ${P}-arm64.deb
	)
"
S="${WORKDIR}/${P}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	elibc_glibc
"

RESTRICT="mirror strip test"

BDEPEND="
	app-arch/dpkg
	dev-util/patchelf
"

# Runtime deps from upstream deb plus Electron/Chromium shared libraries.
RDEPEND="
	${PYTHON_DEPS}
	app-accessibility/at-spi2-core
	dev-libs/expat
	dev-libs/glib
	dev-libs/nspr
	dev-libs/nss
	$(python_gen_cond_dep '
		dev-python/pygobject[${PYTHON_USEDEP}]
	')
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	sys-libs/glibc
	virtual/udev
	x11-base/xorg-server[xvfb]
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/pango
	x11-misc/xclip
	x11-misc/xdotool
"
DEPEND="${RDEPEND}"
IDEPEND="
	dev-util/desktop-file-utils
	dev-util/gtk-update-icon-cache
"

QA_PREBUILT="*"
QA_SONAME="*"
QA_DT_NEEDED="*"

src_unpack() {
	local deb
	case ${ARCH} in
		amd64) deb="${P}-amd64.deb" ;;
		arm64) deb="${P}-arm64.deb" ;;
		*) die "unsupported ARCH=${ARCH}" ;;
	esac

	mkdir -p "${S}" || die
	dpkg-deb -x "${DISTDIR}/${deb}" "${S}" || die "deb extract failed"
}

src_install() {
	cp -a "${S}"/. "${ED}"/ || die "install deb payload failed"

	if [[ -d ${ED}/usr/share/doc/orca-ide ]]; then
		mv "${ED}/usr/share/doc/orca-ide" "${ED}/usr/share/doc/${PF}" \
			|| die "rename doc dir failed"
	fi

	local sherpa_arch
	case ${ARCH} in
		amd64)
			sherpa_arch="x64"
			rm -rf "${ED}/opt/Orca/resources/node_modules/@parcel/watcher-linux-arm64-glibc" \
				|| die "remove non-native parcel watcher failed"
			;;
		arm64)
			sherpa_arch="arm64"
			rm -rf "${ED}/opt/Orca/resources/node_modules/@parcel/watcher-linux-x64-glibc" \
				|| die "remove non-native parcel watcher failed"
			;;
	esac

	patchelf --set-rpath '$ORIGIN' \
		"${ED}/opt/Orca/resources/node_modules/sherpa-onnx-linux-${sherpa_arch}/sherpa-onnx.node" \
		|| die "fix sherpa-onnx RUNPATH failed"

	# Match upstream deb postinst: make Chromium's sandbox helper usable on
	# systems without unprivileged user namespaces.
	fperms 4755 /opt/Orca/chrome-sandbox

	# Upstream Linux avoids /usr/bin/orca because GNOME Orca owns that name.
	# The bundled CLI help still says "orca"; the Linux command is orca-ide.
	dosym -r /opt/Orca/resources/bin/orca-ide /usr/bin/orca-ide
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update

	elog "Orca IDE ${PV} installed from upstream Debian package."
	elog "Desktop: menu entry 'Orca' or /opt/Orca/orca-ide"
	elog "CLI:     orca-ide status --json"
	elog
	elog "No /usr/bin/orca symlink is installed; that name conflicts with GNOME Orca."
	elog "If you do not install app-accessibility/orca and want upstream docs verbatim,"
	elog "create a user-local alias or symlink from orca to orca-ide."
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

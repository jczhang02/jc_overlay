# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )

inherit desktop python-single-r1 xdg

PNPM_PV="10.24.0"

DESCRIPTION="Agentic development environment for desktop, mobile, and headless servers"
HOMEPAGE="https://github.com/stablyai/orca"
SRC_URI="
	https://github.com/stablyai/orca/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
"
S="${WORKDIR}/${PN}-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64"
REQUIRED_USE="elibc_glibc ${PYTHON_REQUIRED_USE}"

# pnpm and electron-builder fetch the pinned JavaScript dependency graph,
# Electron runtime, and platform-specific native packages during the build.
RESTRICT="network-sandbox mirror strip test"

BDEPEND="
	${PYTHON_DEPS}
	>=net-libs/nodejs-24[npm]
	<net-libs/nodejs-25[npm]
	dev-build/cmake
	dev-build/make
	sys-devel/binutils
	sys-devel/gcc
	virtual/pkgconfig
"

RDEPEND="
	${PYTHON_DEPS}
	app-accessibility/at-spi2-core:2[introspection]
	dev-libs/expat
	dev-libs/glib
	dev-libs/nspr
	dev-libs/nss
	$(python_gen_cond_dep '
		dev-python/pygobject:3[${PYTHON_USEDEP}]
	')
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
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
	x11-libs/libXi
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/pango
	x11-misc/xclip
	x11-misc/xdg-utils
	x11-misc/xdotool
"

# Electron, Chromium, sherpa-onnx, and agent-browser remain bundled; the Orca
# TypeScript/React application and node-pty addon are built locally.
QA_PREBUILT="opt/${PN}/*"

PATCHES=(
	"${FILESDIR}/${PV}-native-linux-window-frame.patch"
	"${FILESDIR}/${PV}-remove-orphan-reaction-test.patch"
	"${FILESDIR}/${PV}-skip-release-glibc-floor-check.patch"
)

src_prepare() {
	default

	# build:cli is also used for release packaging; its final step tries to
	# install an orca-dev symlink into /usr/local, outside Portage's image.
	sed -i 's/ && node config\/scripts\/install-dev-cli\.mjs//' package.json || die
	! grep -q '"build:cli".*install-dev-cli' package.json \
		|| die "failed to disable the development CLI install"
}

src_compile() {
	# Keep all package-manager and Electron downloads inside the build sandbox.
	export HOME="${T}/home"
	export XDG_CACHE_HOME="${T}/cache"
	export XDG_CONFIG_HOME="${T}/config"
	export XDG_DATA_HOME="${T}/share"
	export npm_config_cache="${T}/npm-cache"
	export ELECTRON_BUILDER_CACHE="${T}/electron-builder-cache"
	export ELECTRON_CACHE="${T}/electron-cache"
	export PNPM_HOME="${T}/pnpm-home"
	export CSC_IDENTITY_AUTO_DISCOVERY=false
	export HUSKY=0
	export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
	export USE_HARD_LINKS=false
	mkdir -p "${HOME}" "${XDG_CACHE_HOME}" "${XDG_CONFIG_HOME}" \
		"${XDG_DATA_HOME}" "${npm_config_cache}" \
		"${ELECTRON_BUILDER_CACHE}" "${ELECTRON_CACHE}" \
		"${PNPM_HOME}" "${T}/pnpm-store" || die
	export PATH="${PNPM_HOME}/bin:${PATH}"

	einfo "Bootstrapping pnpm ${PNPM_PV}"
	npm install --prefix "${PNPM_HOME}" --global "pnpm@${PNPM_PV}" \
		|| die "pnpm bootstrap failed"

	einfo "Installing the pinned dependency graph"
	pnpm install --frozen-lockfile --store-dir "${T}/pnpm-store" \
		|| die "pnpm install failed"

	einfo "Building Orca and the unpacked Electron application"
	pnpm run build:unpack || die "Orca build failed"
}

src_install() {
	local appdir="${S}/dist/linux-unpacked"
	[[ -d ${appdir} ]] || die "electron-builder produced no linux-unpacked directory"
	[[ -x ${appdir}/orca-ide ]] || die "packaged Orca executable is missing"
	[[ -x ${appdir}/resources/bin/orca-ide ]] || die "packaged Orca CLI is missing"

	dodir "/opt/${PN}"
	cp -a "${appdir}/." "${ED}/opt/${PN}/" || die "failed to install Orca"
	chmod -R a+rX "${ED}/opt/${PN}" || die "failed to normalize installed permissions"
	fperms 4755 "/opt/${PN}/chrome-sandbox"

	dosym -r "/opt/${PN}/resources/bin/orca-ide" /usr/bin/orca-ide
	newicon -s 512 resources/build/icon.png orca-ide.png
	make_desktop_entry --eapi9 "/opt/${PN}/orca-ide" \
		-d orca-ide \
		-n Orca \
		-i orca-ide \
		-c "Development;Utility" \
		-e "StartupWMClass=orca"
}

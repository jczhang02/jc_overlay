# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop

DESCRIPTION="Local-first design product, open-source alternative to Claude Design"
HOMEPAGE="https://github.com/nexu-io/open-design"
SRC_URI="
	https://github.com/nexu-io/open-design/archive/refs/tags/${PN}-v${PV}.tar.gz
		-> ${P}.tar.gz
"
S="${WORKDIR}/${PN}-${PN}-v${PV}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* ~amd64"
REQUIRED_USE="elibc_glibc"

# pnpm fetch + electron-builder need network; AppImage payload contains
# bundled Electron 41 + native modules; portage strip would corrupt the
# squashfs-image inside the AppImage.
RESTRICT="network-sandbox mirror strip test"

# Need npm to bootstrap pnpm. corepack USE flag also works but defaults
# off in Gentoo, so npm is the lowest-friction path.
BDEPEND="
	>=net-libs/nodejs-24[npm]
	app-arch/tar
	app-arch/gzip
	dev-build/make
	sys-devel/gcc
	dev-build/cmake
	virtual/pkgconfig
"

# Runtime deps for AppImage extract-and-run launch (Electron Chromium runtime).
RDEPEND="
	dev-libs/glib
	dev-libs/nss
	dev-libs/nspr
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/pango
	x11-libs/libnotify
	sys-apps/dbus
	sys-libs/glibc
"

QA_PREBUILT="opt/open-design/Open-Design.AppImage"

src_compile() {
	# Sandbox all writes under ${T}.
	export HOME="${T}/home"
	export XDG_CACHE_HOME="${T}/cache"
	export XDG_CONFIG_HOME="${T}/config"
	export XDG_DATA_HOME="${T}/share"
	export npm_config_cache="${T}/npm-cache"
	export ELECTRON_BUILDER_CACHE="${T}/electron-builder-cache"
	export ELECTRON_CACHE="${T}/electron-cache"
	export PNPM_HOME="${T}/pnpm-home"
	mkdir -p "${HOME}" "${XDG_CACHE_HOME}" "${XDG_CONFIG_HOME}" \
		"${XDG_DATA_HOME}" "${npm_config_cache}" \
		"${ELECTRON_BUILDER_CACHE}" "${ELECTRON_CACHE}" \
		"${PNPM_HOME}" || die

	export PATH="${PNPM_HOME}/bin:${PATH}"

	# Pull the pinned pnpm version straight from packageManager so a bump
	# upstream doesn't require touching the ebuild.
	local pnpm_pin
	pnpm_pin=$(sed -n 's/.*"packageManager"[[:space:]]*:[[:space:]]*"\(pnpm@[^"]*\)".*/\1/p' \
		package.json)
	[[ -n ${pnpm_pin} ]] || die "could not read packageManager pin from package.json"

	einfo "Bootstrapping ${pnpm_pin} via npm"
	npm install --prefix "${PNPM_HOME}" --global "${pnpm_pin}" \
		|| die "npm install ${pnpm_pin} failed"

	einfo "Resolved tool versions:"
	einfo "  node    $(node --version)"
	einfo "  pnpm    $(pnpm --version)"

	einfo "Installing workspace dependencies (pnpm, ~1GB download)"
	pnpm install --frozen-lockfile \
		|| pnpm install \
		|| die "pnpm install failed"

	einfo "Building Linux desktop AppImage (electron-builder)"
	# --to appimage produces a single .AppImage with bundled Electron 41.
	# --portable keeps namespace-base-root out of the artifact so the install
	# can resolve its own runtime dirs under the user's Electron userData.
	#
	# 0.8.0 added @open-design/download as a workspace:* dep on
	# @open-design/desktop. tools-pack's assembled-app prod install defaults
	# to `npm install --omit=dev`, which can't resolve workspace: refs and
	# 404s against the public registry. Pointing OD_TOOLS_PACK_PNPM_BIN at
	# the bootstrapped pnpm binary routes that install through
	# `pnpm install --prod --no-lockfile --config.node-linker=hoisted`,
	# matching the Docker `electronuserland/builder` flow upstream uses.
	# See tools/pack/src/linux.ts:resolveProductionInstallCommand.
	export OD_TOOLS_PACK_PNPM_BIN="${PNPM_HOME}/bin/pnpm"
	pnpm tools-pack linux build --to appimage --portable \
		|| die "tools-pack linux build failed"
}

src_install() {
	# electron-builder writes under
	#   .tmp/tools-pack/out/linux/namespaces/<ns>/...AppImage
	local appimage
	appimage=$(find .tmp/tools-pack/out/linux -maxdepth 6 -name '*.AppImage' \
		-type f 2>/dev/null | head -n1)
	[[ -n ${appimage} && -f ${appimage} ]] \
		|| die "no AppImage produced under .tmp/tools-pack/out/linux"

	einfo "Installing ${appimage##*/} -> /opt/open-design/Open-Design.AppImage"
	exeinto /opt/open-design
	newexe "${appimage}" Open-Design.AppImage

	# Wrapper: extract-and-run avoids FUSE module-load slowness flagged
	# upstream; daemon sidecar boot stays under the 35s startup deadline.
	dodir /usr/bin
	cat > "${T}/open-design" <<-'EOF' || die
		#!/usr/bin/env bash
		exec /opt/open-design/Open-Design.AppImage --appimage-extract-and-run "$@"
	EOF
	exeinto /usr/bin
	newexe "${T}/open-design" open-design

	domenu "${FILESDIR}/open-design.desktop"

	# Icon ships inside the built AppImage at
	#   usr/share/icons/hicolor/<size>x<size>/apps/Open Design.png
	# Filename contains a space + custom 533px size, so extract it from the
	# produced AppImage rather than guessing names in the build tree.
	local icon_src icon_dir="${T}/appimage-extract"
	local appimage_abs="${PWD}/${appimage}"
	mkdir -p "${icon_dir}" || die
	chmod +x "${appimage_abs}" 2>/dev/null
	(
		cd "${icon_dir}" \
			&& "${appimage_abs}" --appimage-extract \
				'usr/share/icons/hicolor/*/apps/*.png'
	) || ewarn "AppImage icon extraction failed"
	icon_src=$(find "${icon_dir}/squashfs-root/usr/share/icons" \
		-path '*/apps/*.png' -type f 2>/dev/null | sort -r | head -n1)
	if [[ -n ${icon_src} && -f ${icon_src} ]]; then
		# Native size lives at hicolor/<N>x<N>/apps; mirror to pixmaps so
		# desktops that don't index theme paths still resolve the icon.
		local icon_size
		icon_size=$(echo "${icon_src}" \
			| sed -n 's:.*/hicolor/\([0-9]\+\)x[0-9]\+/.*:\1:p')
		[[ -n ${icon_size} ]] || icon_size=512
		newicon -s "${icon_size}" "${icon_src}" open-design.png
		insinto /usr/share/pixmaps
		newins "${icon_src}" open-design.png
	else
		ewarn "no AppImage icon found; .desktop will fall back to theme lookup"
	fi

	local d
	for d in README.md LICENSE; do
		[[ -f ${d} ]] && dodoc "${d}"
	done
}

pkg_postinst() {
	elog "Open Design ${PV} (desktop) installed."
	elog
	elog "Launch:    open-design"
	elog "AppImage:  /opt/open-design/Open-Design.AppImage"
	elog
	elog "Daemon writes runtime data under \${OD_DATA_DIR:-~/.od}."
	elog "Set OD_DATA_DIR to relocate the SQLite db, artifacts, and credentials."
	elog
	elog "Electron 41 needs kernel.unprivileged_userns_clone=1 (default on"
	elog "modern kernels). If the renderer fails to start, pass --no-sandbox."
}

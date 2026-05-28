# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

MY_PN="${PN%-bin}"
MY_PV="${PV}"

DESCRIPTION="Superset Desktop — AI-native developer workspace (Electron AppImage)"
HOMEPAGE="https://superset.sh https://github.com/superset-sh/superset"
SRC_URI="
	amd64? (
		https://github.com/superset-sh/superset/releases/download/desktop-v${MY_PV}/${MY_PN}-${MY_PV}-x86_64.AppImage
	)
"

S="${WORKDIR}/squashfs-root"

LICENSE="Elastic-2.0"
SLOT="0"
KEYWORDS="-* ~amd64"

RESTRICT="bindist mirror strip test"

# Upstream ships glibc-linked Electron only; no musl variant.
REQUIRED_USE="elibc_glibc"

# AppImage payload is prebuilt Electron + Chromium + native modules.
QA_PREBUILT="opt/${MY_PN}/*"

RDEPEND="
	app-accessibility/at-spi2-core
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	sys-libs/glibc
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/pango
"

src_unpack() {
	# AppImage runtime can self-extract via --appimage-extract; copy out
	# of DISTDIR first so the resulting squashfs-root lands in WORKDIR
	# (and so DISTDIR stays read-only, as Portage requires).
	local img="${WORKDIR}/${MY_PN}-${MY_PV}-x86_64.AppImage"
	cp "${DISTDIR}/${MY_PN}-${MY_PV}-x86_64.AppImage" "${img}" \
		|| die "could not stage AppImage from DISTDIR"
	chmod +x "${img}" || die

	cd "${WORKDIR}" || die
	"${img}" --appimage-extract > /dev/null \
		|| die "AppImage self-extraction failed"

	rm -f "${img}" || die
}

src_install() {
	local dest="/opt/${MY_PN}"

	# electron-builder names the runtime binary after the package name
	# in package.json — for superset that's @supersetdesktop. Detect it
	# rather than hard-coding so future renames don't break the ebuild.
	local appname
	appname=$(find "${S}" -maxdepth 1 -type f -executable -exec file {} + \
		| awk -F: '/ELF .* executable/ && !/chrome[_-]/ {print $1; exit}')
	[[ -n ${appname} ]] || die "could not locate Electron entry binary in extracted AppImage"
	appname=$(basename "${appname}")

	# Strip AppImage scaffolding we don't want shipped.
	rm -f "${S}"/.DirIcon "${S}"/AppRun.wrapped 2>/dev/null

	insinto "${dest}"
	doins -r "${S}"/*

	# `doins` strips exec bits; restore them on every ELF executable
	# under /opt/${MY_PN}. Shared libraries stay 0644.
	local f rel
	while IFS= read -r -d '' f; do
		rel=${f#${S}/}
		case ${rel} in
			*.so|*.so.*) ;;
			*) fperms 0755 "${dest}/${rel}" ;;
		esac
	done < <(find "${S}" -type f -exec sh -c \
		'head -c4 "$1" | grep -q "^.ELF"' _ {} \; -print0)

	# chrome-sandbox needs setuid root for Chromium's unprivileged-
	# namespace path; otherwise Electron requires --no-sandbox.
	if [[ -f ${S}/chrome-sandbox ]]; then
		fowners root:root "${dest}/chrome-sandbox"
		fperms 4755 "${dest}/chrome-sandbox"
	fi

	# Tiny wrapper instead of symlinking AppRun: upstream's AppRun is a
	# generic AppImage helper that misbehaves when invoked without the
	# AppImage runtime around it.
	dodir /usr/bin
	cat > "${ED}/usr/bin/${MY_PN}" <<-EOF || die
		#!/bin/sh
		exec ${dest}/${appname} "\$@"
	EOF
	fperms 0755 "/usr/bin/${MY_PN}"

	# Desktop entry: rewrite Exec/Icon to absolute, predictable values.
	local desk
	for desk in "${S}"/*.desktop; do
		[[ -f ${desk} ]] || continue
		sed -i \
			-e "s|^Exec=.*|Exec=/usr/bin/${MY_PN} %U|" \
			-e "s|^Icon=.*|Icon=${MY_PN}|" \
			"${desk}" || die
		newmenu "${desk}" "${MY_PN}.desktop"
	done

	# Icons: pull every hicolor size electron-builder shipped, falling
	# back to the top-level PNG (which is itself a symlink to the
	# largest hicolor variant).
	local icon size src_icon
	for size in 16 24 32 48 64 96 128 256 512 1024; do
		# Upstream icon basename matches the executable, not ${MY_PN}.
		for src_icon in \
			"${S}/usr/share/icons/hicolor/${size}x${size}/apps/${appname}.png" \
			"${S}/usr/share/icons/hicolor/${size}x${size}/apps/${MY_PN}.png"
		do
			if [[ -f ${src_icon} ]]; then
				newicon -s "${size}" "${src_icon}" "${MY_PN}.png"
				break
			fi
		done
	done
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "Superset Desktop ${PV} installed to /opt/${MY_PN}."
	elog "Launch with: ${MY_PN}    (or via your application menu)"
	elog
	elog "If the app refuses to start with a sandbox error, either:"
	elog "  - keep chrome-sandbox setuid (default), or"
	elog "  - run: ${MY_PN} --no-sandbox"
}

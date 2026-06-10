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

# Runtime deps for the bundled Electron Chromium runtime. The packaged app
# starts its own daemon/web sidecars using the Node binary bundled inside the
# AppImage (a copy of the build host's net-libs/nodejs, dynamically linked
# against versioned system libs such as ICU/sqlite/nghttp2). Depending on
# net-libs/nodejs:= both pulls those shared libraries in and, via the :=
# subslot, forces a rebuild whenever the Node ABI/soname set changes so the
# bundled copy never goes stale.
RDEPEND="
	net-libs/nodejs:=
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

QA_PREBUILT="opt/open-design/*"

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
	# tools-pack assembles the Electron app from file: tarballs of the
	# workspace packages, then materializes its node_modules with a plain
	# `npm install --omit=dev` (its default when OD_TOOLS_PACK_PNPM_BIN is
	# unset). npm satisfies every nested @open-design/* dep from the bundled
	# top-level file: tarballs, so no registry fetch happens -- as long as all
	# of them are in INTERNAL_PACKAGES. Do NOT route this through pnpm: pnpm
	# refuses to dedupe registry-versioned nested deps against file: tarballs
	# and 404s instead.
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
	local appimage_abs="${S}/${appimage}"

	# Extract the AppImage ONCE into /opt/open-design/app and run the GUI plus
	# helper CLI/MCP wrappers from that persistent tree. We do not install an
	# always-on daemon service; the Electron app owns its packaged daemon/web
	# sidecars and their namespace-scoped data store.
	#
	# Why not just ship the .AppImage and a thin launcher (as <0.8.0 did)?
	# Agent/MCP helpers need the bundled daemon CLI and resource catalog, and the
	# daemon validates OD_RESOURCE_ROOT against the Node binary inside the app
	# tree. Extracting once gives those helpers stable paths and avoids repeated
	# --appimage-extract-and-run startup cost.
	local sq="${WORKDIR}/od-extract/squashfs-root"
	mkdir -p "${WORKDIR}/od-extract" || die
	chmod +x "${appimage_abs}" 2>/dev/null
	(
		cd "${WORKDIR}/od-extract" \
			&& "${appimage_abs}" --appimage-extract >/dev/null
	) || die "AppImage --appimage-extract failed"
	[[ -d ${sq} ]] || die "extraction produced no squashfs-root"

	# Paths (relative to the installed app root) the CLI wrappers depend on.
	local od_rel_node="resources/open-design/bin/node"
	local od_rel_cli="resources/app/node_modules/@open-design/daemon/dist/cli.js"
	[[ -x ${sq}/${od_rel_node} ]] || die "bundled node missing (${od_rel_node})"
	[[ -f ${sq}/${od_rel_cli} ]]  || die "daemon CLI missing (${od_rel_cli})"
	[[ -x ${sq}/AppRun ]]         || die "AppRun missing"

	# Install the extracted tree (preserve symlinks + executable bits).
	einfo "Installing app tree -> /opt/open-design/app"
	dodir /opt/open-design
	cp -a "${sq}" "${ED}/opt/open-design/app" || die "install app tree failed"

	# `--appimage-extract` yields an OWNER-ONLY tree (directories mode 0700).
	# cp -a preserves that, and once portage remaps ownership to root, an
	# unprivileged user can no longer traverse /opt/open-design/app -- every
	# launcher then dies with "AppRun: Permission denied". Normalize the tree:
	# directories + already-executable files become world-traversable, data
	# files world-readable (a+rX adds execute only where it already exists).
	chmod -R a+rX "${ED}/opt/open-design/app" || die "normalize app tree perms failed"

	# Belt-and-suspenders: guarantee the binaries the launchers exec are +x,
	# even if a future extraction strips the bit before a+rX can preserve it.
	local b
	for b in AppRun "Open Design" chrome-sandbox chrome_crashpad_handler \
		resources/open-design/bin/node; do
		[[ -e ${ED}/opt/open-design/app/${b} ]] \
			&& fperms 0755 "/opt/open-design/app/${b}"
	done

	# --- launchers ------------------------------------------------------
	local odroot="/opt/open-design/app"
	dodir /usr/bin

	# GUI: AppRun sets up LD_LIBRARY_PATH/XDG and execs the Electron binary --
	# identical to the old extract-and-run launcher, just persistent. Pin
	# APPDIR so AppRun skips its fragile arg-based AppDir auto-detection.
	#
	# Packaged Open Design treats OD_DATA_DIR as a base path unless it already
	# ends with namespaces/<name>/data. Default it under XDG_DATA_HOME so the
	# desktop daemon/web sidecars and generated MCP snippets share one XDG data
	# store instead of the upstream XDG config namespace store.
	cat > "${T}/open-design" <<-EOF || die
		#!/usr/bin/env bash
		export APPDIR="${odroot}"
		export OD_DATA_DIR="\${OD_DATA_DIR:-\${XDG_DATA_HOME:-\${HOME}/.local/share}/open-design}"
		exec "${odroot}/AppRun" "\$@"
	EOF

	# open-design-cli: the OD CLI. Upstream names this binary `od`, but
	# sys-apps/coreutils owns /usr/bin/od (octal dump), so installing our own
	# would be a fatal file collision -- and shadowing coreutils' od on PATH
	# would break every script that uses it. We install under the open-design-*
	# namespace instead; users who want the short name can `alias od=...`.
	# Runs the bundled Node from inside the tree with OD_RESOURCE_ROOT pointed
	# at the bundled catalog (required, else the catalog is empty). Packaged
	# desktop sidecars inject OD_DATA_DIR/OD_DAEMON_URL/OD_SIDECAR_* when they
	# spawn agents or generate MCP install snippets; this wrapper deliberately
	# does not invent ~/.od, avoiding a second store beside the Electron store.
	cat > "${T}/open-design-cli" <<-EOF || die
		#!/usr/bin/env bash
		export OD_NODE_BIN="${odroot}/${od_rel_node}"
		export OD_BIN="${odroot}/${od_rel_cli}"
		export OD_RESOURCE_ROOT="${odroot}/resources/open-design"
		exec "\${OD_NODE_BIN}" "\${OD_BIN}" "\$@"
	EOF

	# open-design-mcp: stdio MCP server for IDEs / code agents. Prefer the MCP
	# config generated by the running Electron app; it supplies the sidecar IPC
	# env needed to talk to the desktop-owned daemon/store. Refuse the implicit
	# default 127.0.0.1:7456 path unless the user explicitly provides a daemon URL.
	cat > "${T}/open-design-mcp" <<-EOF || die
		#!/usr/bin/env bash
		case " \$* " in
			*" --daemon-url "*|*" --daemon-url="*) ;;
			*)
				if [[ -z \${OD_DAEMON_URL:-} && -z \${OD_SIDECAR_IPC_PATH:-} ]]; then
					printf '%s\n' \
						"open-design-mcp needs Open Design desktop MCP env" \
						"or explicit --daemon-url/OD_DAEMON_URL." >&2
					exit 1
				fi
				;;
		esac
		exec /usr/bin/open-design-cli mcp "\$@"
	EOF

	local w
	exeinto /usr/bin
	for w in open-design open-design-cli open-design-mcp; do
		newexe "${T}/${w}" "${w}"
	done

	domenu "${FILESDIR}/open-design.desktop"

	# Icon ships inside the tree at usr/share/icons/hicolor/<N>x<N>/apps/.
	local icon_src
	icon_src=$(find "${sq}/usr/share/icons" -path '*/apps/*.png' -type f \
		2>/dev/null | sort -r | head -n1)
	if [[ -n ${icon_src} && -f ${icon_src} ]]; then
		local icon_size
		icon_size=$(echo "${icon_src}" \
			| sed -n 's:.*/hicolor/\([0-9]\+\)x[0-9]\+/.*:\1:p')
		[[ -n ${icon_size} ]] || icon_size=512
		newicon -s "${icon_size}" "${icon_src}" open-design.png
		insinto /usr/share/pixmaps
		newins "${icon_src}" open-design.png
	else
		ewarn "no icon found; .desktop will fall back to theme lookup"
	fi

	local d
	for d in README.md LICENSE; do
		[[ -f ${d} ]] && dodoc "${d}"
	done
}

pkg_postinst() {
	elog "Open Design ${PV} installed (app tree under /opt/open-design/app)."
	elog
	elog "Commands:"
	elog "  open-design          desktop GUI (primary entry point)"
	elog "  open-design-cli      bundled Open Design CLI helper. Upstream names"
	elog "                       it 'od', but coreutils owns /usr/bin/od; alias"
	elog "                       od=open-design-cli yourself if you want it."
	elog "  open-design-mcp      guarded stdio MCP helper for desktop-generated"
	elog "                       MCP configs; it refuses implicit 7456 fallback."
	elog
	elog "This Gentoo package is Electron-only: it installs no systemd service"
	elog "and does not start a standalone ~/.od daemon. Open Design runs while"
	elog "the desktop app is open; desktop-owned daemon/web sidecars use the"
	elog "XDG data store: \${XDG_DATA_HOME:-~/.local/share}/open-design/"
	elog "namespaces/default/data (override by launching with OD_DATA_DIR=...)."
	elog
	elog "To connect Claude/Codex/Cursor/etc., open Open Design desktop and use"
	elog "its MCP install instructions. Do not hand-write an MCP config that"
	elog "connects to http://127.0.0.1:7456 unless you intentionally run a"
	elog "separate daemon."
	elog
	elog "If upgrading from an older ebuild that installed open-design-daemon,"
	elog "stop the old user service to avoid split-brain stores:"
	elog "  systemctl --user disable --now open-design-daemon.service 2>/dev/null || true"
	elog "  systemctl --user daemon-reload"
	elog
	elog "Electron needs kernel.unprivileged_userns_clone=1 (default on modern"
	elog "kernels). If the GUI renderer fails, run: open-design --no-sandbox"
}

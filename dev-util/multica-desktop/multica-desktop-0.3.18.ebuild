# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop

DESCRIPTION="Multica desktop client — open-source managed agents platform"
HOMEPAGE="https://multica.ai https://github.com/multica-ai/multica"
SRC_URI="
	https://github.com/multica-ai/multica/archive/refs/tags/v${PV}.tar.gz
		-> multica-${PV}.tar.gz
"
S="${WORKDIR}/multica-${PV}"

# Upstream LICENSE is a modified Apache-2.0 (commercial-redistribution
# clause); Homebrew formula declares Apache-2.0, follow that.
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
REQUIRED_USE="elibc_glibc"

# pnpm install fetches ~1GB of node modules + Electron 39 tarball; bundle-cli
# uses go modules from proxy.golang.org; portage strip would corrupt the
# AppImage's embedded squashfs payload.
RESTRICT="network-sandbox mirror strip test"

# npm bootstraps the pinned pnpm; go builds the bundled multica CLI sidecar.
BDEPEND="
	>=net-libs/nodejs-22[npm]
	>=dev-lang/go-1.24
	app-arch/tar
	app-arch/gzip
"

# Runtime deps for AppImage extract-and-run (Electron 39 Chromium runtime).
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

QA_PREBUILT="opt/multica-desktop/Multica.AppImage"

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
	export GOTOOLCHAIN=auto
	export GOFLAGS="-mod=mod -trimpath"
	export GOCACHE="${T}/go-cache"
	export GOMODCACHE="${T}/go-mod"
	# Suppress macOS signing probes; linux build never signs.
	export CSC_IDENTITY_AUTO_DISCOVERY=false
	mkdir -p "${HOME}" "${XDG_CACHE_HOME}" "${XDG_CONFIG_HOME}" \
		"${XDG_DATA_HOME}" "${npm_config_cache}" \
		"${ELECTRON_BUILDER_CACHE}" "${ELECTRON_CACHE}" \
		"${PNPM_HOME}" "${GOCACHE}" "${GOMODCACHE}" || die

	export PATH="${PNPM_HOME}/bin:${PATH}"

	# Pull the pinned pnpm version straight from packageManager so an
	# upstream bump doesn't require touching the ebuild.
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
	einfo "  go      $(go version)"

	einfo "Installing workspace dependencies (pnpm, ~1GB download)"
	pnpm install --frozen-lockfile \
		|| pnpm install \
		|| die "pnpm install failed"

	# Build server/cmd/multica → apps/desktop/resources/bin/multica
	einfo "Building bundled Go CLI sidecar"
	pnpm --filter @multica/desktop run bundle-cli \
		|| die "bundle-cli failed"

	einfo "Building Electron renderer (electron-vite)"
	pnpm --filter @multica/desktop exec electron-vite build \
		|| die "electron-vite build failed"

	# Map portage ARCH → electron-builder flag.
	local eb_arch
	case ${ARCH} in
		amd64) eb_arch="--x64" ;;
		arm64) eb_arch="--arm64" ;;
		*) die "unsupported ARCH=${ARCH}" ;;
	esac

	einfo "Packaging Linux AppImage (electron-builder ${eb_arch})"
	# `--linux AppImage` restricts targets to AppImage only; the upstream
	# electron-builder.yml also lists deb/rpm which we don't need and which
	# pull in extra fakeroot/dpkg/rpmbuild tooling.
	cd apps/desktop || die
	pnpm exec electron-builder --linux AppImage ${eb_arch} \
		-c.extraMetadata.version="${PV}" \
		--publish never \
		|| die "electron-builder failed"
}

src_install() {
	local appimage
	appimage=$(find apps/desktop/dist -maxdepth 2 -name '*.AppImage' \
		-type f 2>/dev/null | head -n1)
	[[ -n ${appimage} && -f ${appimage} ]] \
		|| die "no AppImage produced under apps/desktop/dist"

	einfo "Installing ${appimage##*/} -> /opt/multica-desktop/Multica.AppImage"
	exeinto /opt/multica-desktop
	newexe "${appimage}" Multica.AppImage

	# Wrapper: extract-and-run avoids FUSE module-load slowness on hosts
	# without fuse2; matches the Multica desktop launcher contract on the
	# .deb/.rpm channels.
	#
	# The bundled CLI daemon (server/cmd/multica) is the LOCAL agent executor:
	# it clones repos, builds git worktrees, and runs codex tasks under its
	# "workspaces root". With no override the daemon plants that tree in
	# ${HOME} as ~/multica_workspaces_desktop-<api-host> (config.go derives
	# the dir from the per-host profile name). Pin MULTICA_WORKSPACES_ROOT to
	# an XDG data path so the workspaces live under ~/.local/share instead of
	# cluttering ${HOME}, and drop the ugly per-host suffix. `:=` keeps it a
	# default — a user who exports their own MULTICA_WORKSPACES_ROOT wins.
	dodir /usr/bin
	cat > "${T}/multica-desktop" <<-'EOF' || die
		#!/usr/bin/env bash
		: "${MULTICA_WORKSPACES_ROOT:=${XDG_DATA_HOME:-${HOME}/.local/share}/multica/workspaces}"
		export MULTICA_WORKSPACES_ROOT
		exec /opt/multica-desktop/Multica.AppImage --appimage-extract-and-run "$@"
	EOF
	exeinto /usr/bin
	newexe "${T}/multica-desktop" multica-desktop

	domenu "${FILESDIR}/multica-desktop.desktop"

	# Icon ships pre-rendered in apps/desktop/build/icon.png (1024x1024).
	if [[ -f apps/desktop/build/icon.png ]]; then
		newicon -s 512 apps/desktop/build/icon.png multica-desktop.png
		insinto /usr/share/pixmaps
		newins apps/desktop/build/icon.png multica-desktop.png
	else
		ewarn "build/icon.png missing; .desktop falls back to theme lookup"
	fi

	local d
	for d in README.md LICENSE; do
		[[ -f ${d} ]] && dodoc "${d}"
	done
}

pkg_postinst() {
	elog "Multica desktop ${PV} installed."
	elog
	elog "Launch:    multica-desktop"
	elog "AppImage:  /opt/multica-desktop/Multica.AppImage"
	elog
	elog "First run will prompt for login. The bundled multica CLI/daemon"
	elog "is launched automatically by the desktop client and runs agent"
	elog "tasks locally (repo clones, git worktrees, codex runs)."
	elog
	elog "Agent workspaces default to:"
	elog "    \${XDG_DATA_HOME:-~/.local/share}/multica/workspaces"
	elog "instead of the upstream ~/multica_workspaces_desktop-<host>. Export"
	elog "MULTICA_WORKSPACES_ROOT before launching to point elsewhere."
	elog
	elog "Electron 39 needs kernel.unprivileged_userns_clone=1 (default on"
	elog "modern kernels). If the renderer fails to start, pass --no-sandbox."
}

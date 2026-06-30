# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop git-r3 xdg

DESCRIPTION="Unofficial Linux wrapper for OpenAI Codex Desktop"
HOMEPAGE="https://github.com/ilysenko/codex-desktop-linux"
EGIT_REPO_URI="https://github.com/ilysenko/codex-desktop-linux.git"
EGIT_BRANCH="main"

LICENSE="MIT all-rights-reserved"
SLOT="0"
KEYWORDS=""
REQUIRED_USE="elibc_glibc"

# Upstream downloads mutable Codex.dmg, managed Node.js, Electron, npm modules,
# and Cargo crates during install.sh. Generated Electron/Node/native payloads
# must not be stripped.
RESTRICT="network-sandbox mirror strip test"

BDEPEND="
	app-arch/7zip
	app-arch/tar
	app-arch/unzip
	dev-build/make
	net-misc/curl
	sys-devel/gcc
	|| (
		dev-lang/rust
		dev-lang/rust-bin
	)
"

# Runtime deps for Electron/Chromium and launcher helpers. The app bundles its
# own managed Node.js runtime under /opt/codex-desktop-linux/resources.
RDEPEND="
	app-accessibility/at-spi2-core
	dev-libs/glib
	dev-libs/nss
	dev-libs/nspr
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/dbus
	x11-apps/xprop
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
	x11-misc/xdg-utils
"
DEPEND="${RDEPEND}"

QA_PREBUILT="opt/${PN}/*"
QA_SONAME="*"

src_compile() {
	# Sandbox all user/cache writes under ${T}. The source checkout itself stays
	# writable for upstream Cargo target/ and generated build state.
	export HOME="${T}/home"
	export XDG_CACHE_HOME="${T}/cache"
	export XDG_CONFIG_HOME="${T}/config"
	export XDG_DATA_HOME="${T}/share"
	export CARGO_HOME="${T}/cargo-home"
	export npm_config_cache="${T}/npm-cache"
	export CODEX_MANAGED_NODE_CACHE_DIR="${T}/node-runtime-cache"
	export CODEX_INSTALL_DIR="${WORKDIR}/codex-app"
	export PACKAGE_WITH_UPDATER=0
	mkdir -p "${HOME}" "${XDG_CACHE_HOME}" "${XDG_CONFIG_HOME}" \
		"${XDG_DATA_HOME}" "${CARGO_HOME}" "${npm_config_cache}" \
		"${CODEX_MANAGED_NODE_CACHE_DIR}" || die

	einfo "Building Codex Desktop Linux payload from upstream Codex.dmg"
	./install.sh --fresh || die "install.sh failed"
}

src_install() {
	local appdir="${WORKDIR}/codex-app"
	[[ -x ${appdir}/start.sh ]] || die "generated launcher missing: ${appdir}/start.sh"

	einfo "Installing generated app tree -> /opt/${PN}"
	dodir "/opt/${PN}"
	cp -a "${appdir}"/. "${ED}/opt/${PN}/" || die "install app tree failed"
	chmod -R a+rX "${ED}/opt/${PN}" || die "normalize app tree permissions failed"
	fperms 0755 "/opt/${PN}/start.sh"

	dodir /usr/bin
	cat > "${T}/codex-desktop" <<-EOF || die
		#!/usr/bin/env bash
		exec /opt/${PN}/start.sh "\$@"
	EOF
	dobin "${T}/codex-desktop"

	if [[ -f ${appdir}/.codex-linux/codex-desktop.png ]]; then
		newicon -s 256 "${appdir}/.codex-linux/codex-desktop.png" codex-desktop.png
	fi
	make_desktop_entry codex-desktop "Codex Desktop" codex-desktop "Development;Utility;"

	local d
	for d in README.md CHANGELOG.md CONTRIBUTING.md docs/build-and-packaging.md \
		docs/native-setup.md docs/troubleshooting.md; do
		[[ -f ${d} ]] && dodoc "${d}"
	done
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "Codex Desktop Linux installed as /usr/bin/codex-desktop."
	elog "This live ebuild tracks upstream main and rebuilds from OpenAI's current"
	elog "Codex.dmg during emerge. Re-emerge when upstream Codex Desktop changes."
	elog
	elog "Runtime still needs Codex CLI. First launch can install @openai/codex"
	elog "with the bundled Node/npm, or you can manage the CLI yourself."
	elog
	elog "Updater manager is intentionally not installed; Portage owns updates."
}

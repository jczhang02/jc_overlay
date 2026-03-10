# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="Cross-platform desktop All-in-One assistant tool for Claude Code, Codex & Gemini CLI"
HOMEPAGE="https://github.com/farion1231/cc-switch"

MY_PV="v${PV}"
SRC_URI="
	amd64? ( https://github.com/farion1231/cc-switch/releases/download/${MY_PV}/CC-Switch-${MY_PV}-Linux-x86_64.deb -> ${P}-amd64.deb )
	arm64? ( https://github.com/farion1231/cc-switch/releases/download/${MY_PV}/CC-Switch-${MY_PV}-Linux-arm64.deb -> ${P}-arm64.deb )
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RESTRICT="mirror strip test bindist"

RDEPEND="
	x11-libs/gtk+:3
	net-libs/webkit-gtk:4.1
	dev-libs/libayatana-appindicator
"
BDEPEND=""

QA_PREBUILT="opt/${PN}/*"

S="${WORKDIR}"

src_unpack() {
	local deb_file
	if use amd64; then
		deb_file="${DISTDIR}/${P}-amd64.deb"
	elif use arm64; then
		deb_file="${DISTDIR}/${P}-arm64.deb"
	fi

	ar x "${deb_file}" || die "Failed to extract .deb"

	if [[ -f data.tar.gz ]]; then
		tar xzf data.tar.gz || die "Failed to extract data.tar.gz"
	elif [[ -f data.tar.xz ]]; then
		tar xJf data.tar.xz || die "Failed to extract data.tar.xz"
	elif [[ -f data.tar.zst ]]; then
		tar --zstd -xf data.tar.zst || die "Failed to extract data.tar.zst"
	else
		die "No recognized data archive found in .deb"
	fi
}

src_install() {
	# Install main binary
	exeinto /opt/${PN}
	doexe usr/bin/${PN}

	# Install desktop file
	domenu "usr/share/applications/CC Switch.desktop"

	# Install icons
	local icon_dir
	for icon_dir in usr/share/icons/hicolor/*/apps; do
		local size="${icon_dir#usr/share/icons/hicolor/}"
		size="${size%/apps}"
		insinto /usr/share/icons/hicolor/${size}/apps
		doins "${icon_dir}"/${PN}.png
	done

	# Symlink binary to PATH
	dosym /opt/${PN}/${PN} /usr/bin/${PN}
}

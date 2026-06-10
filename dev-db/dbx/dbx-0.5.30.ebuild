# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="Open-source database management tool — 25+ databases in 15 MB"
HOMEPAGE="https://github.com/t8y2/dbx"
SRC_URI="https://github.com/t8y2/dbx/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"
# Cargo + pnpm fetch dependencies online during src_compile.
RESTRICT="network-sandbox test"

RDEPEND="
	dev-libs/glib:2
	dev-libs/openssl:=
	gnome-base/librsvg:2
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:4.1=
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/pango
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=net-libs/nodejs-20[corepack]
	|| (
		>=dev-lang/rust-1.77.2
		>=dev-lang/rust-bin-1.77.2
	)
	virtual/pkgconfig
"

src_prepare() {
	default

	export HOME="${T}/home"
	export PNPM_HOME="${T}/pnpm"
	export CARGO_HOME="${T}/cargo"
	mkdir -p "${HOME}" "${PNPM_HOME}" "${CARGO_HOME}" || die
	export PATH="${PNPM_HOME}:${PATH}"
}

src_compile() {
	einfo "Activating pnpm via corepack"
	corepack enable --install-directory "${PNPM_HOME}" || die
	corepack prepare pnpm@latest --activate || die

	einfo "Installing JS dependencies"
	pnpm install --frozen-lockfile || die

	einfo "Building frontend (vite)"
	pnpm build || die

	einfo "Building Tauri backend (cargo)"
	cd src-tauri || die
	cargo build --release --locked --bin dbx || die
}

src_install() {
	newbin src-tauri/target/release/dbx dbx

	local size
	for size in 32 128; do
		if [[ -f src-tauri/icons/${size}x${size}.png ]]; then
			newicon -s "${size}" "src-tauri/icons/${size}x${size}.png" dbx.png
		fi
	done

	make_desktop_entry dbx DBX dbx "Development;Database;"
}

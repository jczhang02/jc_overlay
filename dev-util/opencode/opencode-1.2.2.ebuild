# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OpenCode Desktop - The open source AI coding agent"
HOMEPAGE="https://opencode.ai/"

SRC_URI="
	amd64? ( https://github.com/anomalyco/opencode/releases/download/v${PV}/opencode-desktop-linux-amd64.deb )
	arm64? ( https://github.com/anomalyco/opencode/releases/download/v${PV}/opencode-desktop-linux-arm64.deb )
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
RESTRICT="mirror"

# Dependencies based on AUR analysis and actual .deb contents
RDEPEND="
	dev-libs/glib
	x11-libs/gtk+:3
	dev-libs/libpcre
"
DEPEND="${RDEPEND}"
BDEPEND="app-arch/dpkg"

QA_PREBUILT="*"
S="${WORKDIR}"

src_unpack() {
	default
	if use amd64; then
		unpack "${DISTDIR}/${P}-amd64.deb"
	elif use arm64; then
		unpack "${DISTDIR}/${P}-arm64.deb"
	else
		die "Unsupported architecture: ${ARCH}"
	fi
}

src_prepare() {
	default
}

src_configure() {
	:
}

src_compile() {
	:
}

src_install() {
	# Install files from /usr directory
	if [[ -d "${S}/usr" ]]; then
		cp -r "${S}/usr" "${D}/" || die "Failed to install /usr"
	fi

	# Fix permissions for main executable
	fperms +x /usr/bin/OpenCode
	fperms +x /usr/bin/opencode-cli
}

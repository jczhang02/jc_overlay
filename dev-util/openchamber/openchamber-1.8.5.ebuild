# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Web interface for OpenCode AI coding agent"
HOMEPAGE="https://github.com/openchamber/openchamber"
SRC_URI="https://github.com/openchamber/openchamber/releases/download/v${PV}/${PN}-web-${PV}.tgz"

S="${WORKDIR}/package"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# npm install needs network access to fetch dependencies
RESTRICT="network-sandbox mirror"

RDEPEND="
	>=net-libs/nodejs-20[npm]
	dev-util/opencode-desktop
"

BDEPEND="
	>=net-libs/nodejs-20[npm]
	dev-lang/python
"

# Native .node addons (node-pty) are prebuilt during src_compile
QA_PREBUILT="opt/openchamber/*"

src_compile() {
	# Install production dependencies only
	npm install \
		--production \
		--no-audit \
		--no-fund \
		--no-update-notifier \
		--ignore-scripts || die "npm install failed"

	# Rebuild native addons (node-pty requires compilation)
	npm rebuild || die "npm rebuild failed"
}

src_install() {
	local dest="/opt/openchamber"

	# Install application files preserving permissions
	dodir "${dest}"
	cp -a dist server bin public package.json node_modules \
		"${ED}${dest}/" || die "install failed"

	# Ensure CLI entry point is executable
	fperms +x "${dest}/bin/cli.js"

	# Install wrapper script to PATH
	dobin "${FILESDIR}/openchamber"

	# Install systemd user service
	insinto /usr/lib/systemd/user
	doins "${FILESDIR}/openchamber.service"

	# Documentation
	dodoc README.md
}

pkg_postinst() {
	elog "OpenChamber has been installed."
	elog ""
	elog "To start the server:"
	elog "  openchamber serve"
	elog ""
	elog "Or enable the systemd user service:"
	elog "  systemctl --user enable --now openchamber.service"
	elog ""
	elog "The web interface will be available at http://localhost:3000"
	elog ""
	elog "Requires 'opencode' to be installed and available in PATH."
}

# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Anthropic's AI assistant for your terminal — understands codebases, edits files, runs commands"
HOMEPAGE="https://github.com/anthropics/claude-code"

# npm registry tarball URL
SRC_URI="https://registry.npmjs.org/@anthropic-ai/claude-code/-/${PN}-${PV}.tgz"

S="${WORKDIR}/package"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

RESTRICT="mirror"

RDEPEND=">=net-libs/nodejs-18"
BDEPEND=">=net-libs/nodejs-18[npm]"

# Bundled node_modules contain prebuilt native addons
QA_PREBUILT="opt/claude-code/*"

src_compile() {
		# Dependencies are already bundled in the npm tarball; nothing to build
		:
	}

src_install() {
		local dest="/opt/claude-code"

		dodir "${dest}"
			cp -a "${S}"/* "${ED}${dest}/" || die "install failed"

		# CLI wrapper
		dobin "${FILESDIR}/claude"

		# Documentation
		dodoc README.md
	}

pkg_postinst() {
		elog "Claude Code has been installed."
		elog ""
		elog "Run 'claude' to start. You will need an Anthropic API key"
		elog "or an active Claude subscription to authenticate."
	}

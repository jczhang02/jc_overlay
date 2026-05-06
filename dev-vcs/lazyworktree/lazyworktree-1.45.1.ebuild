# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="TUI tool to manage git worktrees"
HOMEPAGE="https://github.com/chmouel/lazyworktree"
SRC_URI="https://github.com/chmouel/lazyworktree/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="+delta"

# Source build fetches Go modules at compile time
RESTRICT="network-sandbox mirror"

RDEPEND="
	dev-vcs/git
	dev-vcs/lazygit
	app-misc/tmux
	sys-apps/less
	delta? ( dev-util/git-delta )
"

BDEPEND=">=dev-lang/go-1.25"

src_compile() {
	ego build -o lazyworktree \
		-ldflags "-s -w \
			-X main.version=${PV} \
			-X main.commit=gentoo \
			-X main.date=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
			-X main.builtBy=gentoo" \
		./cmd/lazyworktree
}

src_install() {
	dobin lazyworktree

	doman lazyworktree.1

	insinto /usr/share/lazyworktree
	doins shell/functions.bash shell/functions.zsh shell/functions.fish

	dodoc config.example.yaml
	einstalldocs
}

pkg_postinst() {
	elog "Shell helper functions are installed at:"
	elog "  /usr/share/lazyworktree/functions.{bash,zsh,fish}"
	elog ""
	elog "Source the one matching your shell to enable the 'lwt' helper, e.g.:"
	elog "  source /usr/share/lazyworktree/functions.bash"
	elog ""
	elog "Example config:"
	elog "  /usr/share/doc/${PF}/config.example.yaml"
	elog ""
	elog "Shell completions are generated at runtime via the"
	elog "--generate-shell-completion flag; see upstream README for setup."

	if ! use delta; then
		elog ""
		elog "Built without USE=delta. The default config references"
		elog "git-delta for diff display; edit ~/.config/lazyworktree/config.yaml"
		elog "to use a different pager or install dev-util/git-delta later."
	fi
}

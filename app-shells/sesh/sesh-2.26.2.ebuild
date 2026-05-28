# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion

DESCRIPTION="Smart tmux session manager backed by zoxide, fzf, and tmuxinator"
HOMEPAGE="https://github.com/joshmedeski/sesh"
SRC_URI="https://github.com/joshmedeski/sesh/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"

# No vendor tarball upstream; allow go module fetch during build.
RESTRICT="network-sandbox mirror test strip"

BDEPEND=">=dev-lang/go-1.23"

RDEPEND="app-misc/tmux"

PDEPEND="
	app-shells/fzf
	app-shells/zoxide
"

src_compile() {
	export GOTOOLCHAIN=auto
	export GOFLAGS="-mod=mod -trimpath"
	export GOCACHE="${T}/go-cache"
	export GOMODCACHE="${T}/go-mod"

	go build \
		-ldflags="-s -w -X main.version=v${PV}" \
		-o sesh \
		./ || die "go build failed"
}

src_install() {
	dobin sesh
	doman man/sesh.1

	einstalldocs

	# Cobra-generated completions; binary is self-contained and safe to run.
	local shell
	for shell in bash zsh fish; do
		./sesh completion "${shell}" > "${T}/sesh.${shell}" \
			|| die "completion generation failed for ${shell}"
	done
	newbashcomp "${T}/sesh.bash" sesh
	newzshcomp  "${T}/sesh.zsh"  _sesh
	newfishcomp "${T}/sesh.fish" sesh
}

pkg_postinst() {
	elog "sesh installed. Quick start:"
	elog "  sesh connect                # interactive fzf picker"
	elog "  sesh list                   # list candidate sessions"
	elog
	elog "Optional integrations (auto-detected at runtime):"
	elog "  app-shells/zoxide           # recent-directory source"
	elog "  app-shells/fzf              # built-in picker UI"
	elog "  app-admin/tmuxinator        # project layout templates"
	elog
	elog "Recommended tmux binding (~/.config/tmux/tmux.conf.local):"
	elog "  bind T display-popup -E -w 80% -h 80% \"sesh connect \\\$(sesh list -tz | fzf)\""
	elog
	elog "Config file: ~/.config/sesh/sesh.toml"
}
